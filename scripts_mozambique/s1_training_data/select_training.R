####################################################################################
####### Object:  Select training data, export as KML -> FT -> classification           
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/11/01                                     
####################################################################################

######## SET YOUR WORKING DIRECTORY
rootdir <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/mozambique/training/"
date    <- 20171101

######## LOAD PACKAGES & OPTIONS
library(raster)
library(rgeos)
library(rgdal)

library(foreign)
library(plyr)
library(ggplot2)
library(stringr)

options(stringsAsFactors = F)

########### READ MERGED SHAPEFILES
shp <- readOGR(paste0(rootdir,"all_training_",date,".shp"))
names(shp)

########### SELECT FOR CLASSIFICATION
out <- shp[shp@data$area < 1000 & shp@data$lev2_code != "17" & shp@data$lev2_code != "1CXF" & shp@data$lev2_code != "2T" & !is.na(shp@data$lev2_code),]

nrow(out)
table(out$lev2_code,out$code_l2)

########### REPROJECT BEFORE EXPORTING TO KML
out <- spTransform(out,CRS("+init=epsg:4326"))
writeOGR(out[,"code_l2"],"train_poly_38257_",date,".kml",paste0("train_poly_38257_",date),"KML")

########### EXTRACT THE CENTROIDS ONLYS, WE NEVER KNOW
points <- SpatialPointsDataFrame(
  coords = gCentroid(out,byid = T)@coords,
  data = out@data,
  proj4string = CRS("+init=epsg:4326"),
  match.ID = F
)

writeOGR(points,"train_pts_38257_",date,".kml",paste0("train_pts_38257_",date),"KML",overwrite_layer = T)

########### SUBSAMPLE with 200 per level 3 class
sampled_id <- list()

for(x in levels(as.factor(out$lev3_code))){
  tmp <- out[out$lev3_code == x,]
  sampled_id <- c(sampled_id,sample(tmp$poly_id,min(200,nrow(tmp))))
}

sample <- out[out$poly_id %in% sampled_id,]
table(sample$lev2_code)
writeOGR(sample[,"code_l2"],"train_poly_4826_",date,".kml",paste0("train_poly_4826_",date),"KML",overwrite_layer = T)

########### EXTRACT THE CENTROIDS ONLYS, WE NEVER KNOW
points <- SpatialPointsDataFrame(
  coords = gCentroid(sample,byid = T)@coords,
  data = sample@data,
  proj4string = CRS("+init=epsg:4326"),
  match.ID = F
)

writeOGR(points[,"code_l2"],"train_pts_4826_",date,".kml",paste0("train_pts_4826_",date),"KML",overwrite_layer = T)

########### SUBSAMPLE with 20 per level 3 code
sampled_id <- list()

for(x in levels(as.factor(out$lev3_code))){
  tmp <- out[out$lev3_code == x,]
  sampled_id <- c(sampled_id,sample(tmp$poly_id,min(20,nrow(tmp))))
}

sample <- out[out$poly_id %in% sampled_id,]
table(sample$lev2_code)
writeOGR(sample[,"code_l2"],"train_poly_520_",date,".kml",paste0("train_poly_520_",date),"KML",overwrite_layer = T)

