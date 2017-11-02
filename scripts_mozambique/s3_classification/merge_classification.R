####################################################################################################
####################################################################################################
## Merge classification results (GEE exported tiles) for integration in decision tree
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
library(maptools)
library(dplyr)

#############################################################
### WORK ENVIRONMENT
setwd("~/")
rootdir  <- paste0(getwd(),"/")
moz_dir  <- paste0(rootdir,"moz_lulc/")
classdir <- paste0(moz_dir,"classification/")
esa_dir  <- paste0(moz_dir,"esa_data/")
dir.create(esa_dir)

dir.create(classdir)

#############################################################
### VARIABLES TO MODIFY
downdir      <- paste0(rootdir,"downloads/classif_zambezia_lsat_train_520_poly_wetperiod/")
classif_name <- "classification_20171101.tif"

#############################################################
### MERGE
system(sprintf("gdal_merge.py -v -ot Byte -co COMPRESS=LZW -co BIGTIFF=YES -o %s %s",
               paste0(classdir,"tmp_merge.tif"),
               paste0(downdir,"*.tif")
               ))

#############################################################
### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(classdir,"tmp_merge.tif"),
               paste0(classdir,classif_name)
               ))

#############################################################
### CLEAN
system(sprintf("rm %s",
               paste0(classdir,"tmp_merge.tif")
               ))

