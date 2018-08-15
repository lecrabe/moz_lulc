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
tile <- tiles[2]
#################### LOPP THROUGH EACH SUBSET 
for(tile in tiles[58:60]){

  file.rename(paste0(pol_dir,tile,".dbf"),paste0(pol_dir,"bckup_",tile,".dbf"))
  
  dbf <- read.dbf(file = paste0(pol_dir,"bckup_",tile,".dbf"))
  
  names(dbf) <- c("DN","sort_code","size","auto_code","mode_spk","mode_spw","mode_esa","av_gfc","edit_code")
  dbf2 <- dbf[,-2]

  dbf2[dbf2$mode_esa == 8,]$edit_code <- 51
  write.dbf(dbf2,paste0(pol_dir,tile,".dbf"))
}

time_polygons <- Sys.time() - time_start
