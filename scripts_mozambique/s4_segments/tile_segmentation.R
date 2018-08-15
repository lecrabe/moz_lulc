####################################################################################################
####################################################################################################
## Generate a wall-to-wall tiling system for the segmentation, in correct projection
## Contact remi.dannunzio@fao.org 
## 2018/05/22
####################################################################################################
####################################################################################################

provinces          <- substr(
  list.files(seg_dir,glob2rx("seg_lsms*.tif")),
  10,
  nchar(list.files(seg_dir,glob2rx("seg_lsms*.tif")))-19
)
# province <- provinces[5]
# dbf <- read.dbf(paste0(res_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".dbf"))
# df  <- read.csv(paste0(res_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".csv"))
# head(dbf)
# head(df)
# write.dbf(df,paste0(res_dir,"reclass_seg_lsms_",province,"_",paste0(params,collapse = "_"),".dbf"))

#################### Loop through existing segmentation files and reproject
for(province in provinces[1:14]){
  segs_geo <- paste0(seg_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".tif")
  segs_lae <- paste0(seg_dir,"laea_seg_lsms_",province,"_",paste0(params,collapse = "_"),".tif")
  system(sprintf("gdalwarp -t_srs %s -dstnodata 0 -co COMPRESS=LZW %s %s",
                 paste0(res_dir,"lamb_azim.txt"),
                 segs_geo,
                 segs_lae
                 ))
}



#################### Build VRT with new segments
system(sprintf("gdalbuildvrt %s %s",
               paste0(seg_dir,"segment_tile.vrt"),
               paste0(seg_dir,"laea_seg_lsms*.tif")
))


#################### TILE VRT INTO 8x12 tiles
system(sprintf("perl %s/s7_misc/subset_tif_in_n_subtifs.pl %s %s %s ",
               scriptdir,
               paste0(seg_dir,"segment_tile.vrt"),
               8,
               12
))

#################### GET FILE SIZE
list <- list.files(seg_tile_dir,pattern=".tif")
info <- file.info(paste0(seg_tile_dir,list))

barplot(info$size)
summary(info$size)

#################### FILTER OUT SEGMENTATION TILES WITH LESS THAN 2.8MB, they are empty
to_rm <- info[info$size <= 2800000,]
file.remove(row.names(to_rm))

#################### GENERATE A INDEX SHAPEFILE
system(sprintf("gdaltindex %s %s",
               paste0(seg_dir,"index_segments.shp"),
               paste0(seg_tile_dir,"*.tif")
               ))

dbf <- read.dbf(paste0(seg_dir,"index_segments.dbf"))
dbf$location <- basename(as.character(dbf$location))

operators <- c("alismo","credencio","delfio","hercilo","muri")
dbf$operator <- sample(rep(operators,12),60)

write.dbf(dbf,paste0(seg_dir,"index_segments.dbf"))


#################### GET LIST OF SUBSETS (TILES) TO PROCESS
tiles          <- substr(
  list.files(seg_tile_dir,glob2rx("segment_tile*.tif")),
  1,
  nchar(list.files(seg_tile_dir,glob2rx("segment_tile*.tif")))-4
)

#################### RECLUMP THE SEGMENTS VALUES
for(tile in tiles){
  
  the_segments <- paste0(seg_tile_dir,tile,".tif")
  
  system(sprintf("oft-clump %s %s",
                 the_segments,
                 paste0(seg_tile_dir,"tmp_clump",tile,".tif")
  ))

  system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
                 paste0(seg_tile_dir,"tmp_clump",tile,".tif"),
                 paste0(seg_tile_dir,"clump_",tile,".tif")
  ))

  system(sprintf("rm %s",
                 paste0(seg_tile_dir,"tmp_clump",tile,".tif")
  ))
  
  system(sprintf("mv %s %s",
                 paste0(seg_tile_dir,"clump_",tile,".tif"),
                 the_segments
                 ))
  
}
  
  
