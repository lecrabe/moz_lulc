####################################################################################
####### Object:  Use AD Grid to assess accuracy of ESA CCI map @ 20m (2017)     
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/10/23                                    
####################################################################################

####################################################################################
####### PARAMETERS
####################################################################################
setwd("/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/mozambique/")

options(stringsAsFactors = F)
library(raster)
library(rgeos)
library(rgdal)
library(foreign)
library(plyr)
library(ggplot2)

####################################################################################
####### DATA INPUT
####################################################################################
cci <- raster("gis_data_moz/ESACCI_mozambique.tif")
adg <- read.csv("ce_exercise/Mozambique_AD_ALL_1.csv",encoding = "UTF-8",stringsAsFactors = FALSE)
moz <- getData('GADM',path="gis_data_moz/", country= "MOZ", level=2)

####################################################################################
####### SPATIALIZE ADG POINTS
####################################################################################
adg <- adg[!is.na(adg$location_y),]

spdf <- SpatialPointsDataFrame(
  coords = adg[,c("location_x","location_y")],
  data   = adg,
  proj4string = CRS("+init=epsg:4326")
  )

####################################################################################
####### INTERSECT ADG POINTS WITH ADMIN BOUNDARIES 
####################################################################################
proj4string(moz)   <- proj4string(spdf)
spdf@data$region_1 <- over(spdf,moz)$NAME_1
spdf@data$region_2 <- over(spdf,moz)$NAME_2

####################################################################################
####### INTERSECT ADG POINTS WITH ESA MAP VALUES
####################################################################################
proj4string(cci)   <- proj4string(spdf)
spdf@data$esa_code <- extract(cci,spdf)

legend_esa <- data.frame(cbind(c(1:8,10),
                               c("Trees cover areas",
                                 "Shrubs cover areas",
                                 "Grassland",
                                 "Cropland",
                                 "Vegetation aquatic or regularly flooded",
                                 "Lichen Mosses / Sparse vegetation",
                                 "Bare areas",
                                 "Built up areas",
                                 "Open water")
                               )
                         )
names(legend_esa) <- c("esa_code","esa_class")
df <- merge(spdf@data,legend_esa)

####################################################################################
####### CLEAN EMPTY LULC LEVELS
####################################################################################
df$lulc_nivel1_label <- as.character(df$lulc_nivel1_label)
table(df$lulc_nivel1_label)

df$lulc_nivel2_label <- as.character(df$lulc_nivel2_label)
table(df$lulc_nivel2_label)

df$lulc_nivel3_label <- as.character(df$lulc_nivel3_label)
table(df$lulc_nivel3_label)

df[df$lulc_nivel2_label %in% c(""," "),]$lulc_nivel2_label <- df[df$lulc_nivel2_label %in% c(""," "),]$lulc_nivel1_label
df[df$lulc_nivel3_label %in% c(""," "),]$lulc_nivel3_label <- df[df$lulc_nivel3_label %in% c(""," "),]$lulc_nivel2_label
table(df$lulc_nivel3_label)

table(df$lulc_nivel1_label,df$esa_class)

####################################################################################
####### GENERATE IPCC CLASSES FOR ESA MAP
####################################################################################
df$esa_ipcc <- "tbd"

df[df$esa_class %in% c("Shrubs cover areas","Grassland"),                      ]$esa_ipcc <- "Pradarias"
df[df$esa_class %in% c("Trees cover areas"),                                   ]$esa_ipcc <- "Florestas"
df[df$esa_class %in% c("Built up areas"),                                      ]$esa_ipcc <- "Áreas urbanas"
df[df$esa_class %in% c("Cropland"),                                            ]$esa_ipcc <- "Cultivos"
df[df$esa_class %in% c("Open water","Vegetation aquatic or regularly flooded"),]$esa_ipcc <- "Áreas alagadas"
df[df$esa_class %in% c("Bare areas","Lichen Mosses / Sparse vegetation"),      ]$esa_ipcc <- "Outras Terras"

table(df$esa_class,df$esa_ipcc)

table(df$esa_ipcc,df$lulc_nivel1_label)
table(df$esa_ipcc,df$lulc_nivel2_label)
table(df$esa_ipcc,df$region_1)

####################################################################################
####### COMPUTE MAP AREAS
####################################################################################
system(sprintf("oft-stat -i %s -o %s -um %s",
               "gis_data_moz/ESACCI_mozambique_crop.tif",
               "gis_data_moz/stat_ESACCI_moz.txt",
               "gis_data_moz/ESACCI_mozambique_crop.tif"))
stats <- read.table("gis_data_moz/stat_ESACCI_moz.txt")

system(sprintf("gdalinfo -hist gis_data_moz/ESACCI_mozambique_crop.tif"))
