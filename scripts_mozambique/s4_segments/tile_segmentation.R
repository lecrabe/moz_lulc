provinces          <- substr(
  list.files(seg_dir,glob2rx("seg_lsms*.tif")),
  10,
  nchar(list.files(seg_dir,glob2rx("seg_lsms*.tif")))-19
)
province <- provinces[5]
dbf <- read.dbf(paste0(res_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".dbf"))
df  <- read.csv(paste0(res_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".csv"))
head(dbf)
head(df)
write.dbf(df,paste0(res_dir,"reclass_seg_lsms_",province,"_",paste0(params,collapse = "_"),".dbf"))

for(province in provinces){
  segs_geo <- paste0(seg_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".tif")
  segs_lae <- paste0(seg_dir,"laea_seg_lsms_",province,"_",paste0(params,collapse = "_"),".tif")
  system(sprintf("gdalwarp -t_srs %s -co COMPRESS=LZW %s %s",
                 paste0(res_dir,"lamb_azim.txt"),
                 segs_geo,
                 segs_lae
                 ))
}

system(sprintf("rm %s",
               paste0(seg_dir,"segment_tile.vrt")
))


system(sprintf("gdalbuildvrt %s %s",
               paste0(seg_dir,"segment_tile.vrt"),
               paste0(seg_dir,"laea_seg_lsms*.tif")
))


system(sprintf("perl %s/s7_misc/subset_tif_in_n_subtifs.pl %s %s %s ",
               scriptdir,
               paste0(seg_dir,"segment_tile.vrt"),
               8,
               12
))

seg_tile_dir <- paste0(seg_dir,"segment_tile","_subset_tiles/")
list <- list.files(seg_tile_dir,pattern=".tif")
info <- file.info(paste0(seg_tile_dir,list))

barplot(info$size)
summary(info$size)

to_rm <- info[info$size <= 2800000,]
file.remove(row.names(to_rm))

system(sprintf("gdaltindex %s %s",
               paste0(seg_dir,"index_segments.shp"),
               paste0(seg_tile_dir,"*.tif")
               ))

dbf <- read.dbf(paste0(seg_dir,"index_segments.dbf"))
dbf$location <- basename(as.character(dbf$location))
write.dbf(dbf,paste0(seg_dir,"index_segments.dbf"))
4927 * 30
