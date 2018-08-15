####################################################################################################
####################################################################################################
## Polygonize results
## Contact remi.dannunzio@fao.org 
## 2018/04/06
####################################################################################################
####################################################################################################
time_start <- Sys.time() 


#################### GET LIST OF SUBSETS (TILES) TO PROCESS
tiles          <- substr(
  list.files(seg_tile_dir,glob2rx("segment_tile*.tif")),
  1,
  nchar(list.files(seg_tile_dir,glob2rx("segment_tile*.tif")))-4
)
tile <- tiles[1]
#################### LOPP THROUGH EACH SUBSET 
for(tile in tiles[58]){
  
  
  the_segments <- paste0(seg_tile_dir,tile,".tif")
  the_codes    <- paste0(seg_dir,tile,"_reclass.txt")
  
  system(sprintf("gdal_polygonize.py %s -f \"ESRI Shapefile\" %s %s",
                 the_segments,
                 paste0(pol_dir,tile,".shp"),
                 paste0(pol_dir,tile)
  ))
  
  file.rename(paste0(pol_dir,tile,".dbf"),paste0(pol_dir,"bckup_",tile,".dbf"))
  dbf <- read.dbf(file = paste0(pol_dir,"bckup_",tile,".dbf"))
  
  df  <- read.table(the_codes)
  names(df) <-  c("DN","size","auto_code","mode_spk","mode_spw","mode_esa","av_gfc")
  dbf$sort_code <- row(dbf)[,1]
  
  dbf1 <- merge(dbf,df,by.x="DN",by.y="DN")
  dbf2  <- arrange(dbf1,sort_code)
  
  dbf2$edit_code <- dbf2$auto_code
  
  tryCatch({
    dbf2[dbf2$mode_esa == 8,]$edit_code <- 51
  },error=function(e){cat("Not relevant\n")})
  
  dbf2$av_gfc <- as.integer(floor(dbf2$av_gfc))
  dbf2$edit_code <- as.character(dbf2$edit_code)
  
  dbf3 <- dbf2[,-2]

  write.dbf(dbf3,paste0(pol_dir,tile,".dbf"))
}

time_polygons <- Sys.time() - time_start
