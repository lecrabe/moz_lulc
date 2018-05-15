####################################################################################################
####################################################################################################
## GET REFERENCE DATA FROM REMAINING POLYGONS TO VALIDATE MAP
## Contact remi.dannunzio@fao.org 
## 2017/12/08
####################################################################################################
####################################################################################################


#### READ MAP & TRAINING POLYGONS & USED TRAING POLYGONS
the_result <- paste0(res_dir,"moz_lulc2016_20180405.tif")
all_poly   <- paste0(train_dir,"train_poly_29300_lambazim_20171208.shp")
train_dbf  <- read.dbf(paste0(train_dir,"train_poly_848_20171124.dbf"))

shp <- readOGR(all_poly)
length(unique(shp$poly_id))

#### CREATE ZONAL STATS OF THE FULL DATABASE OVER THE MAP
system(sprintf("python %s/s7_misc/oft-zonal_large_list.py -i %s -um %s -o %s -a %s",
               scriptdir,
               the_result,
               all_poly,
               paste0(res_dir,"zonal_training_result_20180405.txt"),
               "poly_id"
))


#### SELECT ONLY COLUMNS OF INTEREST< COMPUTE THE MODE AND THE PURITY OF EACH POLYGON
df <- read.table(paste0(res_dir,"zonal_training_result_20180405.txt"))

names(df) <- c("poly_id","total","nodata",paste0("class",1:(ncol(df)-3)))
df <- df[,colSums(df)!=0]
val_classes <- names(df)[4:ncol(df)]

df$map_code <- substr(c(val_classes)[max.col(df[,val_classes])],6,8)

df$purity <- 0
for(i in 1:nrow(df)){
  df[i,"purity"] <- max(df[i,val_classes] / df$total)
}

df$purity <- floor(df$purity*10)/10

#### MERGE POLYGON COMPOSITION WITH TRAINING DATABASE
poly_map <- merge(
  df[,c("poly_id","total","map_code","purity")],
  shp@data,
  all.x=T)

head(poly_map)

#### IS USED FOR TRAINING OR NOT ?
poly_map$train <- "no"
poly_map[poly_map$poly_id %in% train_dbf$poly_id,]$train <- "yes"
table(poly_map$train)

#### MERGE CODES TO OBTAIN L1 and L2 for the MAP INFORMATION
codes <- read.csv(paste0(datadir,"code_list_lc.csv"))
codes_l2 <- unique(codes[,c("nivel1_code","nivel1_label_en","code_l2","nivel2_code")])
names(codes_l2) <- c("map_code_l1","map_class_l1","map_code_l2","map_class_l2")

df1 <- merge(poly_map,
             codes_l2,
             by.x="map_code",
             by.y="map_code_l2",
             all.x=T
)

names(df1)
df2 <- df1[,c("poly_id","total","purity","author","granule","map_code_l1","map_code","map_class_l1","map_class_l2","lev1_code","code_l2","lev2_code","train")]

names(df2) <- c("poly_id","total","purity","author","granule","map_code_l1","map_code_l2","map_class_l1","map_class_l2","ref_code_l1","ref_code_l2","ref_class_l2","train")
head(df2)
df3 <- df2[df2$train == "no",]

write.csv(df3,paste0(res_dir,"map_vs_ref_val_poly_20180405.csv"),row.names = F)


#### COMPUTE MAP AREAS
system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               the_result,
               paste0(res_dir,"map_area.txt"),
               the_result
))

#### CONVERT AREAS INTO HA AND MERGE NECESSARY CODES
areas <- read.table(paste0(res_dir,"map_area.txt"))[,1:2]
names(areas) <- c("map_code_l2","map_area")
areas_merge <- merge(areas,codes_l2)
pix <- res(raster(the_result))[1]
areas_merge$map_area <- areas_merge$map_area * pix * pix / 10000
sum(areas_merge$map_area)

write.csv(areas_merge,paste0(res_dir,"areas_l2_20180405.csv"),row.names = F)

#### SELECT NLCS_1 AND EXPORT FOR AA
areas_l1 <- data.frame(tapply(areas_merge$map_area,areas_merge$map_code_l1,sum))
names(areas_l1) <- "map_area"
areas_l1$map_code_l1 <- rownames(areas_l1)
sum(areas_l1$map_area)

write.csv(areas_l1,paste0(res_dir,"areas_l1_20180405.csv"),row.names = F)
