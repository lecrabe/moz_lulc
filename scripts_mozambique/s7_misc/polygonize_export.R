####################################################################################################
####################################################################################################
## Use a decision tree to integrate raster values inside segments
## Contact remi.dannunzio@fao.org 
## 2018/04/06
####################################################################################################
####################################################################################################
time_start <- Sys.time() 


#################### GET LIST OF SUBSETS (PROVINCES) TO PROCESS
provinces          <- substr(
  list.files(seg_dir,glob2rx("seg_lsms*.tif")),
  10,
  nchar(list.files(seg_dir,glob2rx("seg_lsms*.tif")))-19
)

#################### LOPP THROUGH EACH SUBSET
for(province in provinces[c(1:4,6:14)]){
  
  the_segments <- paste0(seg_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".tif")
  the_codes    <- paste0(seg_dir,province,"_reclass.txt")
  
  system(sprintf("gdal_polygonize.py %s -f \"ESRI Shapefile\" %s %s",
                 the_segments,
                 paste0(pol_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".shp"),
                 paste0("seg_lsms_",province,"_",paste0(params,collapse = "_"))
                 ))
  
  dbf <- read.dbf(file = paste0(pol_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".dbf"))
  df  <- read.table(the_codes)
  names(df) <- c("DN","size","code_20180521","mode_spk","mode_spw","mode_esa","sd_gfc")
  dbf$sort_code <- row(dbf)[,1]
  dbf1 <- merge(dbf,df,by.x="DN",by.y="DN")
  dbf2  <- arrange(dbf1,sort_code)[,c(1,3:8)]
  head(dbf2)
  
  write.csv(dbf2,paste0(pol_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".csv"),row.names = F)
  #write.dbf(dbf2[,c(1,3)],paste0(pol_dir,"out_seg_lsms_",province,"_",paste0(params,collapse = "_"),".dbf"))
  }

time_polygons <- Sys.time() - time_start
