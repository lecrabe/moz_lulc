####################################################################################
####### Object:  Read results from CE exercise              
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/10/12                                     
####################################################################################
library(raster)
library(rgeos)
library(rgdal)

library(foreign)
library(plyr)
library(ggplot2)

options(stringsAsFactors = F)

####################################################################################
###### Set directories
rootdir <- "~/countries/mozambique/ce_exercise/"
rootdir <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/mozambique/ce_exercise/"
setwd(rootdir)

df <- read.csv("Mozambique_AD_ALL_1.csv",encoding = "UTF-8")
df <- df[!is.na(df$location_y),]

names(df)
summary(df)
summary(df$land_use_former_national_label)
table(df$land_use_former_national_label,df$lulc_nivel1_label)
table(df$lulc_nivel1,df$lulc_nivel1_label)
(gadm_list       <- data.frame(getData('ISO3')))

spdf <- SpatialPointsDataFrame(coords = df[,c("location_x","location_y")],
                               data   = df,
                               proj4string = CRS("+init=epsg:4326"))

moz <- getData('GADM',path=".", country= "MOZ", level=2)
proj4string(moz) <- proj4string(spdf)
test <- over(spdf,moz)

spdf@data$region_1 <- test$NAME_1
spdf@data$region_2 <- test$NAME_2

df <- spdf@data
table(df$lulc_nivel2_label,df$region_1)
table(df$lulc_nivel2_label,df$lulc_nivel1_label)
table(df$land_use_former_national_label,df$lulc_change_label)
table(df$lulc_nivel1_label,df$lulc_change_label)

df$change <- 1
df[df$lulc_change_label %in% c("A>A","C>C","F>F","O>O","P>P","U>U"),]$change <- 0
table(df$change,df$lulc_change_label)

df[df$change == 0,]$land_use_former_national_label <- df[df$change == 0,]$lulc_nivel1_label

table(df$land_use_former_national_label,df$lulc_nivel2_label)
table(df$lulc_nivel2_label,df$lulc_nivel1_label)

table(df$lulc_nivel3_label,df$lulc_nivel2_label)
x <- "Dunas"
sampled_id <- list()

for(x in levels(as.factor(df$lulc_nivel2_label))){
  tmp <- df[df$lulc_nivel2_label == x,]
  sampled_id <- c(sampled_id,sample(tmp$id,min(100,nrow(tmp))))
  }

out <- spdf[spdf$id %in% sampled_id,]
out_simple <- out[,c("id","lulc_nivel1_label","lulc_nivel1","lulc_nivel2","lulc_nivel2_label")] 
names(out_simple) <- c("id","code_l1","class_l1","code_l2","class_l2")
writeOGR(out_simple,"training_points.kml","training_points","KML")
