####################################################################################################
####################################################################################################
## Clip available products for Mozambique
## Contact remi.dannunzio@fao.org 
## 2017/10/29
####################################################################################################
####################################################################################################
options(stringsAsFactors = FALSE)

### Load necessary packages
library(gfcanalysis)
library(rgeos)
library(ggplot2)
library(rgdal)
library(dplyr)

setwd("~/")
rootdir <- paste0(getwd(),"/")
downdir <- paste0(rootdir,"downloads/")
moz_dir <- paste0(rootdir,"moz_lulc/")
lim_dir <- paste0(moz_dir,"boundaries/")
scriptdir <- paste0(moz_dir,"scripts_mozambique/")

dir.create(lim_dir)

gfc_folder    <-  "~/downloads/gfc_2016/"
esa_folder    <-  "~/downloads/ESA_2016/"

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
               paste0(esa_folder,"tmp_ESACCI_mozambique.tif")
))

####################################################################################
####### CROP GFC TO COUNTRY BOUNDARIES
####################################################################################
moz <- getData('GADM',path=lim_dir, country= "MOZ", level=2)
writeOGR(moz,paste0(lim_dir,"moz_limits.shp"),"moz_limits","ESRI Shapefile",overwrite_layer = T)

# setwd(scriptdir)
# system(sprintf("gdalwarp -cutline %s -crop_to_cutline -co COMPRESS=LZW -ot Byte %s %s",
#                paste0(lim_dir,"moz_limits.shp"),
#                paste0(esa_folder,"tmp_ESACCI_mozambique.tif"),
#                paste0(esa_folder,"ESACCI_mozambique.tif")
#                ))

####################################################################################
####### CLIP GFC DATA TO MOZAMBIQUE BOUNDARIES
####################################################################################
setwd(gfc_folder)
dest_dir <- paste0(moz_dir,"gfc_data/")
dir.create(dest_dir)

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
                 paste0(dest_dir,"gfc_moz_",type,".tif")
  ))
  

  
}
