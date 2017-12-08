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

system(sprintf("gdalwarp -t_srs %s -co COMPRESS=LZW %s %s",
               paste0(res_dir,"lamb_azim.txt"),
               paste0(res_dir,"tmp_merge.vrt"),
               paste0(res_dir,"tmp_map_prj.tif")
               ))


#############################################################
### CROP TO COUNTRY BOUNDARIES
system(sprintf("python %s/s7_misc/oft-cutline_crop.py -v %s -i %s -o %s",
               scriptdir,
               paste0(limit_dir,"districtos_laea.shp"),
               paste0(res_dir,"tmp_map_prj.tif"),
               paste0(res_dir,"tmp_dt_merge_clip.tif")
               ))

#################### CREATE COLOR TABLE
pct <- data.frame(cbind(my_classes,
                        my_colors[1,],
                        my_colors[2,],
                        my_colors[3,]))

write.table(pct,paste0(seg_dir,"/color_table.txt"),row.names = F,col.names = F,quote = F)

################################################################################
#################### Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(seg_dir,"/custom_color_table.txt"),
               paste0(res_dir,"tmp_dt_merge_clip.tif"),
               paste0(res_dir,"tmp_pct_dt_merge_clip.tif")
))

################################################################################
#################### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(res_dir,"tmp_pct_dt_merge_clip.tif"),
               paste0(res_dir,"moz_lulc2016_20171208.tif")
))
# #############################################################
# ### CLEAN
system(sprintf("rm %s",
               paste0(res_dir,"tmp_*")
))


the_result <- paste0(res_dir,"moz_lulc2016_20171208.tif")

#### READ THE AD GRID AND THE CODE LIST
ad    <- read.csv(paste0(adg_dir,"Mocambique_AD_100%_26_11_17.csv"))
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
                   names(df)[grep("code",names(df))],
                   names(df)[grep(glob2rx("*element_cover"),names(df))]
)
)

df <- df[,c("id","location_x","location_y",select)]
table(df$nivel2_code,df$lulc_nivel2,useNA="always")
names(df) <- c("id","location_x","location_y",
               "ref_class_l3","ref_code_l1","ref_class_l1",
               "ref_class_l2","ref_class_l2_long","ref_class_l3_long",
               "ref_code_chge","ref_class_chge","ref_class_l2_tmp",
               "ref_code_l3","ref_code_l2",
               "element_cover_tree","element_cover_shrub","element_cover_thicket","element_cover_grass","element_cover_bare",
               "element_cover_crops","element_cover_river","element_cover_lake","element_cover_structure"
)
df[df=="na"] <- 0
head(df)

df <- df[,c("id","location_x","location_y",
            "ref_code_l3","ref_code_l2","ref_code_l1",
            "ref_class_l3","ref_class_l2","ref_class_l1",
            "ref_class_l3_long","ref_class_l2_long",
            "ref_code_chge","ref_class_chge",
            "element_cover_tree","element_cover_shrub","element_cover_thicket","element_cover_grass","element_cover_bare",
            "element_cover_crops","element_cover_river","element_cover_lake","element_cover_structure"
            )]

#### CONVERT ELEMENTS TO NUMBERS
for(el_col in names(df)[grep(glob2rx("element_cover*"),names(df))]){
  df[,el_col] <- as.numeric(df[,el_col])
}

df$total_elements <- rowSums(df[,names(df)[grep(glob2rx("element_cover*"),names(df))]])
summary(df$total_elements)
#### SPATIALIZE THE POINTS AND PROJECT IN THE RIGHT PROJECTION SYSTEM
spdf <- SpatialPointsDataFrame(coords = df[,c("location_x","location_y")],
                               data   = df,
                               proj4string = CRS("+init=epsg:4326"))

laea <- proj4string(raster(the_result))
spdf_laea <- spTransform(spdf,laea)

#### INTERSECT WITH RESULT MAP
spdf_laea@data$map_code <- extract(raster(the_result),spdf_laea)


#### MERGE THE AD GRID SPATIAL POINTS WITH CODES LIST TO GET MAP CLASS AT LEVEL 1 AND 2
codes_l2 <- unique(codes[,c("nivel1_code","nivel1_label_en","code_l2","nivel2_code")])
names(codes_l2) <- c("map_code_l1","map_class_l1","map_code_l2","map_class_l2")

df1 <- merge(spdf_laea@data,
             codes_l2,
             by.x="map_code",
             by.y="map_code_l2",
             all.x=T
)

names(df1)[1] <- "map_code_l2"
table(df1$map_code_l2,df1$map_code_l1)

#### SELECT ONLY POINTS THAT HAVE BEEN INTERSECTED WITH MAP
df2 <- df1[df1$map_code_l2 != 0 ,]
df2 <- df2[!is.na(df2$map_code_l2) ,]

#### REFINE SELECTION BY PURE CLASSES
table(df2$element_cover_structure,df2$ref_code_l1)

df2$pure_class <- 0

df2[df2$ref_code_l1 == 1 & df2$element_cover_crops > 9  ,]$pure_class <- 1

df2[df2$ref_code_l1 == 2 & df2$element_cover_tree > 9,]$pure_class <- 1
df2[df2$ref_code_l1 == 2 & df2$element_cover_tree < 7 & (df2$element_cover_thicket  + df2$element_cover_river + df2$element_cover_lake + df2$element_cover_crops) == 0,]$pure_class <- 1

df2[df2$ref_code_l1 == 3 & (df2$element_cover_grass > 9 | df2$element_cover_shrub > 9 | df2$element_cover_thicket > 9),]$pure_class <- 1

df2[df2$ref_code_l1 == 4 & (df2$element_cover_river > 9 | df2$element_cover_lake > 9 | df2$element_cover_shrub > 9 | df2$element_cover_grass > 9),]$pure_class <- 1

df2[df2$ref_code_l1 == 5 & df2$element_cover_structure > 4  ,]$pure_class <- 1

df2[df2$ref_code_l1 == 6 & df2$element_cover_bare > 9  ,]$pure_class <- 1

df3 <- df2[df2$pure_class ==1,]
table(df3$ref_code_l1,df3$element_cover_tree)
write.csv(df3,paste0(res_dir,"map_vs_ref_20171208.csv"),row.names = F)

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

#### CONVERT AREAS INTO HA AND MERGE NECESSARY CODES
areas <- read.table(paste0(res_dir,"map_area.txt"))[,1:2]
names(areas) <- c("map_code_l2","map_area")
areas_merge <- merge(areas,codes_l2)
pix <- res(raster(the_result))[1]
areas_merge$map_area <- areas_merge$map_area * pix * pix / 10000
sum(areas_merge$map_area)

#### SELECT NLCS_1 AND EXPORT FOR AA
areas_l1 <- data.frame(tapply(areas_merge$map_area,areas_merge$map_code_l1,sum))
names(areas_l1) <- "map_area"
areas_l1$map_code_l1 <- rownames(areas_l1)
sum(areas_l1$map_area)

write.csv(areas_l1,paste0(res_dir,"areas_l1_20171208.csv"),row.names = F)
