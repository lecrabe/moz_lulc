####################################################################################
####### Object:  Select training data, export as KML -> FT -> classification           
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/11/01                                     
####################################################################################

######## SET YOUR WORKING DIRECTORY
rootdir <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/mozambique/training_data/"
date    <- 20171124
setwd(rootdir)
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
shp <- readOGR(paste0(rootdir,"all_training_",date,".shp"),
               paste0("all_training_",date)
               )
names(shp)
length(unique(shp$poly_id))

df <- shp@data
summary(df$area)
hist(log(df$area),xlab="Log of the area in ha",main="Distribution of sample size per class")

hh <- ggplot(data = df,aes(log(area),fill=as.character(lev1_code)))
hh + geom_histogram(binwidth = 0.5) + facet_wrap( ~ author)

table(df$lev1_code)

check_classes <- function(x){
  tr_db <- data.frame(cbind(
  tapply(x[,"area"],x[,"lev2_code"],length),
  tapply(x[,"area"],x[,"lev2_code"],min),
  tapply(x[,"area"],x[,"lev2_code"],mean),
  tapply(x[,"area"],x[,"lev2_code"],max),
  tapply(x[,"area"],x[,"lev2_code"],sum)
  ))
  
  names(tr_db) <- c("count","min_ha","average_ha","max_ha","sum_ha")
  tr_db$class <- row.names(tr_db)
  tr_db <- tr_db[,c(6,1:5)]
  print(tr_db)
  }

df1 <- df[df$area >= 0.5 & df$area < 100,]
tr_db <- check_classes(df1)
table(df1$granule,df1$lev2_code)
#write.csv(tr_db,"training_DB_20171120.csv",row.names = F)

########### SELECT FOR CLASSIFICATION
out <- shp[shp@data$area < 5 & shp@data$area >= 0.1 & shp@data$lev2_code != "17" & shp@data$lev2_code != "2T" & !is.na(shp@data$lev2_code),]

nbtotal <- nrow(out)
table(out$lev2_code,out$code_l2)

########### REPROJECT BEFORE EXPORTING TO KML
out <- spTransform(out,CRS("+init=epsg:4326"))
#writeOGR(out,paste0("train_poly_",nbtotal,"_",date,".shp"),paste0("train_poly_",nbtotal,"_",date),"ESRI Shapefile")
#writeOGR(out[,"code_l2"],paste0("train_poly_",nbtotal,"_",date,".kml"),paste0("train_poly_",nbtotal,"_",date),"KML")
check_classes(out@data)

########### SUBSAMPLE with 5 per level 3 class / per granule
sampled_id <- list()

for(y in levels(as.factor(out$granule))){
  granule <- out[out$granule == y,]
  print("granule")
  print(y)
  for(x in levels(as.factor(granule$lev3_code))){
    print(x)
    tmp <- granule[granule$lev3_code == x ,]
    print(nrow(tmp))
    selected <- sample(tmp$poly_id,min(1,nrow(tmp)))
    print(length(selected))
    sampled_id <- c(sampled_id,selected)
  }
}

sample <- out[out$poly_id %in% sampled_id,]
table(sample@data$author,sample@data$lev2_code)
(nbtotal <- nrow(sample))
plot(sample)

writeOGR(sample[,"code_l2"],paste0("train_poly_",nbtotal,"_",date,".kml"),paste0("train_poly_",nbtotal,"_",date),"KML",overwrite_layer = T)
writeOGR(sample,paste0("train_poly_",nbtotal,"_",date,".shp"),paste0("train_poly_",nbtotal,"_",date),"ESRI Shapefile",overwrite_layer = T)



##### COMPUTE ZONAL STATS FOR ESA map
# esa <- "../data/esa_data/ESACCI_mozambique_crop_clean.tif"
# system(sprintf("oft-zonal_large_list.py -i %s -um %s -o %s -a %s",
#                esa,
#                paste0("train_poly_",nbtotal,"_",date,".shp"),
#                paste0("zonal_esa_train_poly_",nbtotal,"_",date,".txt"),
#                "poly_id"))
# 
# st <- read.table(paste0("zonal_esa_train_poly_",nbtotal,"_",date,".txt"))
# names(st) <- c("id","total","nodata",paste0("esa_",1:(ncol(st)-3)))
# 
# st1 <- st[,colSums(st) !=0]
# 
# head(sample)
# head(st1)
# summary(sample$poly_id == st1$id)
# 
# st1 <- data.frame(cbind(sample@data,st1))
# names(st1)
