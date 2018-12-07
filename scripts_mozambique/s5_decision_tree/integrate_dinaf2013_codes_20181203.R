####################################################################################################
####################################################################################################
## INTEGRATE INTO MANUAL CLASSIFIED MAP CODES FROM DINAF 2013
## Contact remi.dannunzio@fao.org 
## 2018/12/03
####################################################################################################
####################################################################################################
setwd(man_dir)

####################################################################################################
####################################################################################################
################                 PART I: COMBINE DINAF 2013 and LULC 2016
####################################################################################################
####################################################################################################


#################### SET NODATA AS "NONE" BECAUSE IT MESSES WITH GDAL_CALC OTHERWISE
system(sprintf("gdal_translate -co COMPRESS=LZW -a_nodata none %s %s ",
               paste0(man_dir,"moz_lulc2016_03122018.tif"),
               paste0(man_dir,"moz_lulc2016_03122018_nodata.tif")
))

system(sprintf("gdal_translate -co COMPRESS=LZW -a_nodata none %s %s ",
               paste0(man_dir,"LULC_2013_comp.tif"),
               paste0(man_dir,"LULC_2013_comp_nodata.tif")
))


#################### ALIGN DINAF_2013 map with LULC_2016 edited map
mask   <- paste0(man_dir,"moz_lulc2016_03122018_nodata.tif")
input  <- paste0(man_dir,"LULC_2013_comp_nodata.tif")
ouput  <- paste0(man_dir,"tmp_LULC_2013_comp.tif")

proj   <- proj4string(raster(mask))
extent <- extent(raster(mask))
res    <- res(raster(mask))[1]

system(sprintf("gdalwarp -co COMPRESS=LZW -t_srs \"%s\" -te %s %s %s %s -tr %s %s %s %s -overwrite",
               proj4string(raster(mask)),
               extent(raster(mask))@xmin,
               extent(raster(mask))@ymin,
               extent(raster(mask))@xmax,
               extent(raster(mask))@ymax,
               res(raster(mask))[1],
               res(raster(mask))[2],
               input,
               ouput
))


################################################################################
#################### IMPLEMENT CONDITIONS BETWEEN DINAF2013 AND LULC2016
system(sprintf("gdal_calc.py -A %s -B %s --co=\"COMPRESS=LZW\" --outfile=%s --calc=\"%s\" ",
               paste0(man_dir,"tmp_LULC_2013_comp.tif"),
               paste0(man_dir,"moz_lulc2016_03122018_nodata.tif"),
               paste0(man_dir,"tmp_conditions.tif"),
               paste0("(B>=22)*(B<=26)*((A==5)*86+(A==6)*82+(A==7)*24+(A==8)*25+(A==11)*28+(A==12)*23)+",
                      "(B>=23)*(B<=24)*((A==9)*26+(A==10)*29)+",
                      "(B>=25)*(B<=26)*((A==9)*84+(A==10)*85)+",
                      "(A==7)*(B==32)*41+",
                      "(A==1)*(B>=11)*(B<=63)*51")
               ))

################################################################################
#################### IMPLEMENT DEFAULT WHERE NO CONDITIONS
system(sprintf("gdal_calc.py -A %s -B %s  --co=\"BIGTIFF=YES\" --co=\"COMPRESS=LZW\" --outfile=%s --calc=\"%s\" ",
               paste0(man_dir,"moz_lulc2016_03122018_nodata.tif"),
               paste0(man_dir,"tmp_conditions.tif"),
               paste0(man_dir,"tmp_combined.tif"),
               "(B==0)*A+(B>0)*B"
               ))           

################################################################################
#################### COMPRESS
system(sprintf("gdal_translate -ot Byte -a_nodata none -co COMPRESS=LZW %s %s",
               paste0(man_dir,"tmp_combined.tif"),
               paste0(man_dir,"tmp_nodata.tif")
))


#############################################################
### CROP TO COUNTRY BOUNDARIES
system(sprintf("python %s/s7_misc/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(limit_dir,"districtos_laea.shp"),
               paste0(man_dir,"tmp_nodata.tif"),
               paste0(man_dir,"tmp_crop.tif"),
               "id"
))

#################### CREATE COLOR TABLE
pct <- data.frame(cbind(my_classes_l3,
                        my_colors_l3[1,],
                        my_colors_l3[2,],
                        my_colors_l3[3,]))

write.table(pct,paste0(seg_dir,"/color_table_l3.txt"),row.names = F,col.names = F,quote = F)

################################################################################
#################### Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(seg_dir,"/color_table_l3.txt"),
               paste0(man_dir,"tmp_crop.tif"),
               paste0(man_dir,"tmp_pct.tif")
))

################################################################################
#################### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(man_dir,"tmp_pct.tif"),
               paste0(man_dir,"lulc2016_dinaf2013_20181206.tif")
))


####################################################################################################
####################################################################################################
################                 PART II: POLYGONIZE THE RESULTS TO HAVE AN EDITABLE SHP DATABASE
####################################################################################################
####################################################################################################

the_map <- paste0(man_dir,"lulc2016_dinaf2013_20181206.tif")

#################### GET LIST OF SUBSETS (TILES) TO PROCESS
tiles          <- substr(
  list.files(seg_tile_dir,glob2rx("segment_tile*.tif")),
  1,
  nchar(list.files(seg_tile_dir,glob2rx("segment_tile*.tif")))-4
)

#################### LOOP THROUGH EACH SUBSET 
tile <- tiles[1]

for(tile in tiles){
  
  the_segments <- paste0(seg_tile_dir,tile,".tif")
  
  #################### ALIGN CLASSIFICATION MAP WITH SEGMENTS
  mask   <- the_segments
  input  <- the_map
  ouput  <- paste0(man_dir,"tmp_map_clip.tif")
  
  proj   <- proj4string(raster(mask))
  extent <- extent(raster(mask))
  res    <- res(raster(mask))[1]
  
  system(sprintf("gdalwarp -co COMPRESS=LZW -t_srs \"%s\" -te %s %s %s %s -tr %s %s %s %s -overwrite",
                 proj4string(raster(mask)),
                 extent(raster(mask))@xmin,
                 extent(raster(mask))@ymin,
                 extent(raster(mask))@xmax,
                 extent(raster(mask))@ymax,
                 res(raster(mask))[1],
                 res(raster(mask))[2],
                 input,
                 ouput
  ))
  

  
  #################### COMPUTE STATS PER SEGMENTS
  system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
                 paste0(man_dir,"tmp_map_clip.tif"),
                 paste0(man_dir,"tmp_zonal.txt"),
                 the_segments,
                 max(my_classes_l3)
  ))

  #################### ADD THE L3 information into the corresponding DBF 
  dbf <- read.dbf(paste0(pol_dir,tile,".dbf"))
  dbf$sort_code <- row(dbf)[,1]

  df  <- read.table(paste0(man_dir,"tmp_zonal.txt"))
  names(df)  <- c("DN","total",paste0("l3_",0:max(my_classes_l3)))
  
  df$mode_l3 <- c(0:max(my_classes_l3))[max.col(df[,paste0("l3_",0:max(my_classes_l3))])]
  
  dbf1 <- merge(dbf,df[,c("DN","total","mode_l3")],by.x="DN",by.y="DN")
  dbf2  <- arrange(dbf1,sort_code)
  
  summary(dbf2$size-dbf2$total)
  write.dbf(dbf2[,c("DN","size","mode_l3")],paste0(man_pol_dir,tile,".dbf"))
  
  system(sprintf("rm %s",
                 paste0(man_dir,"tmp_*")
  ))
  }


