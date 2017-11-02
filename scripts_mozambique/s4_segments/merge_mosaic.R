####################################################################################################
####################################################################################################
## Merge mosaic to feed into segmentation / unsupervised classification
## Contact remi.dannunzio@fao.org 
## 2017/11/02
####################################################################################################
####################################################################################################
options(stringsAsFactors = FALSE)

#############################################################
### Load necessary packages
library(gfcanalysis)
library(rgeos)
library(ggplot2)
library(rgdal)
library(dplyr)

#############################################################
### WORK ENVIRONMENT
setwd("~/")
rootdir  <- paste0(getwd(),"/")
moz_dir  <- paste0(rootdir,"moz_lulc/")


#############################################################
### VARIABLES TO MODIFY
downdir      <- paste0(rootdir,"downloads/zambezia_lsat_dry_20171102")
mosaic_name <- "landsat_mosaic_dry_zambezia.tif"

#############################################################
### MERGE
system(sprintf("gdal_merge.py -v -ot Byte -co COMPRESS=LZW -co BIGTIFF=YES -o %s %s",
               paste0(mosaicdir,"tmp_merge.tif"),
               paste0(downdir,"*.tif")
               ))

#############################################################
### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(mosaicdir,"tmp_merge.tif"),
               paste0(mosaicdir,mosaic_name)
               ))

#############################################################
### CLEAN
system(sprintf("rm %s",
               paste0(mosaicdir,"tmp_merge.tif")
               ))

