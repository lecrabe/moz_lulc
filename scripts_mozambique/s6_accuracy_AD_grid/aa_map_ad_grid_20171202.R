####################################################################################################
####################################################################################################
## GET REFERENCE DATA FROM AD GRID FOR ACCURACY ASSESSMENT OF RESULTS
## Contact remi.dannunzio@fao.org 
## 2017/12/02
####################################################################################################
####################################################################################################

#############################################################
### MERGE AS VRT
system(sprintf("gdalbuildvrt %s %s",
               paste0(res_dir,"tmp_merge.vrt"),
               paste0(res_dir,"*_decision_tree_20171130.tif")
))


#############################################################
### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(res_dir,"tmp_merge.vrt"),
               paste0(res_dir,"dt_merge_20171204.tif")
))




the_result <- paste0(res_dir,"dt_merge_20171204.tif")

#### READ THE AD GRID AND THE CODE LIST
ad    <- read.csv(paste0(adg_dir,"ad_grid.csv"))
codes <- read.csv(paste0(datadir,"code_list_lc.csv"))

levels(as.factor((ad[,"lulc_nivel2"])))
levels(as.factor((codes[,"nivel2_code"])))

#### RECODE THE URBAN AREAS THAT ARE MISSING AT LEVEL 2 WITH CODE 5BU
ad[(ad$lulc_nivel2 == " " | ad$lulc_nivel2 == "") & ad$lulc_nivel1_label == "Áreas urbanas",]$lulc_nivel2 <- "5BU"
ad <- ad[ad$lulc_nivel2 != "" & !is.na(ad$lulc_nivel2),]

#### MERGE TO GET LEVEL 3 and LEVEL 2 CODE DATA INTO AD GRID
df <- merge(ad,
            codes[,c("nivel3_code","nivel2_code","code_l3","code_l2")],
            by.x="lulc_nivel3",
            by.y="nivel3_code",
            all.x=T
)

#### SELECT ONLY COLUMNS OF INTEREST
select <- unique(c(names(df)[grep("lulc",names(df))],
                   names(df)[grep("code",names(df))]
)
)

df <- df[,c("id","location_x","location_y",select)]
table(df$nivel2_code,df$lulc_nivel2,useNA="always")

names(df) <- c("id","location_x","location_y",
               "ref_class_l3","ref_code_l1","ref_class_l1",
               "ref_class_l2","ref_class_l2_long","ref_class_l3_long",
               "ref_code_chge","ref_class_chge","ref_class_l2_tmp",
               "ref_code_l3","ref_code_l2"
)

df <- df[,c("id","location_x","location_y",
            "ref_code_l3","ref_code_l2","ref_code_l1",
            "ref_class_l3","ref_class_l2","ref_class_l1",
            "ref_class_l3_long","ref_class_l2_long",
            "ref_code_chge","ref_class_chge"
            )]

#### SPATIALIZE THE POINTS
spdf <- SpatialPointsDataFrame(coords = df[,c("location_x","location_y")],
                               data   = df,
                               proj4string = CRS("+init=epsg:4326"))

#### INTERSECT WITH ADMINISTRATIVE BOUNDARIES
moz <- getData('GADM',path=limit_dir, country= "MOZ", level=2)
proj4string(moz) <- proj4string(spdf)

spdf@data$region_1 <- over(spdf,moz)$NAME_1
spdf@data$region_2 <- over(spdf,moz)$NAME_2

#### INTERSECT WITH RESULT MAP
spdf@data$map_code <- extract(raster(the_result),spdf)


#### MERGE THE AD GRID SPATIAL POINTS WITH CODES LIST TO GET MAP CLASS AT LEVEL 1 AND 2
codes_l2 <- unique(codes[,c("nivel1_code","nivel1_label_en","code_l2","nivel2_code")])
names(codes_l2) <- c("map_code_l1","map_class_l1","map_code_l2","map_class_l2")

df1 <- merge(spdf@data,
             codes_l2,
             by.x="map_code",
             by.y="map_code_l2",
             all.x=T
)

names(df1)[1] <- "map_code_l2"
table(df1$map_code_l2,df1$map_code_l1)
df2 <- df1[df1$map_code_l2 != 0 ,]
df2 <- df2[!is.na(df2$map_code_l2) ,]

write.csv(df2,paste0(res_dir,"map_vs_ref_20171204.csv"),row.names = F)

######## Confusion matrix as count of elements
map_code <- "map_code_l1"
ref_code <- "ref_code_l1"
legend <- levels(as.factor(df1[,ref_code]))

table(df1[,map_code,],useNA = "always")
tmp <- as.matrix(table(df1[,map_code,],df1[,ref_code]))

tmp[is.na(tmp)]<- 0

matrix<-matrix(0,nrow=length(legend),ncol=length(legend))

for(i in 1:length(legend)){
  tryCatch({
    cat(paste(legend[i],"\n"))
    matrix[,i]<-tmp[,legend[i]]
  }, error=function(e){cat("Not relevant\n")}
  )
}

matrix

#### COMPUTE MAP AREAS
system(sprintf("oft-stat -i %s -o %s -um %s -nostd",
               the_result,
               paste0(res_dir,"map_area.txt"),
               the_result
))

areas <- read.table(paste0(res_dir,"map_area.txt"))[,1:2]
names(areas) <- c("map_code_l2","map_area")
areas <- merge(areas,codes_l2)

areas_l1 <- data.frame(tapply(areas$map_area,areas$map_code_l1,sum))
names(areas_l1) <- "map_area"
areas_l1$map_code_l1 <- rownames(areas_l1)

write.csv(areas_l1,paste0(res_dir,"areas_l1_20171204.csv"),row.names = F)
