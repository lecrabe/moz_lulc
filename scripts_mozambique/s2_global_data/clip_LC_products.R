####################################################################################################
####################################################################################################
## Clip available products for Mozambique
## Contact remi.dannunzio@fao.org 
## 2017/11/02
####################################################################################################
####################################################################################################

gfc_folder    <-  "~/downloads/gfc_2016/"
esa_folder    <-  "~/downloads/ESA_2016/"

time_start  <- Sys.time()

####################################################################################
####### GET COUNTRY BOUNDARIES
####################################################################################
moz <- getData('GADM',path=limit_dir, country= "MOZ", level=2)
writeOGR(moz,paste0(limit_dir,"moz_limits.shp"),"moz_limits","ESRI Shapefile",overwrite_layer = T)
bb <- extent(moz)

####################################################################################
####### CLIP ESA MAP TO COUNTRY BOUNDING BOX
####################################################################################
setwd(esa_folder)
system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
                30,
               -10,
                41,
               -27,
               paste0(esa_folder,"ESACCI-LC-L4-LC10-Map-20m-P1Y-2016-v1.0.tif"),
               esa
))



####################################################################################
####### CLIP GFC DATA TO MOZAMBIQUE BOUNDARIES
####################################################################################
setwd(gfc_folder)

prefix <- "Hansen_GFC-2016-v1.4_"
tiles <- c("10S_040E","10S_030E","20S_030E")
list <- list()

for(tile in tiles){
  list <- append(list,list.files(".",pattern=tile))
}

types <- c("treecover2000","lossyear","gain","datamask")

for(type in types){
  print(type)
  to_merge <- paste(prefix,type,"_",tiles,".tif",sep = "",collapse = " ")
  system(sprintf("gdal_merge.py -o %s -v -co COMPRESS=LZW %s",
                 paste0(gfc_folder,"tmp_merge_",type,".tif"),
                 to_merge
                 ))
  
  system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
                 30,
                 -10,
                 41,
                 -27,
                 paste0(gfc_folder,"tmp_merge_",type,".tif"),
                 paste0(gfc_dir,"gfc_moz_",type,".tif")
  ))
  
system(sprintf("rm %s",
               paste0(gfc_folder,"tmp_merge_",type,".tif")
               ))
  
}

time_products_global <- Sys.time() - time_start
