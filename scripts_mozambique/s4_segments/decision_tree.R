####################################################################################################
####################################################################################################
## Use a decision tree to integrate raster values inside segments
## Contact remi.dannunzio@fao.org 
## 2017/11/02
####################################################################################################
####################################################################################################
time_start <- Sys.time() 

#################### CALL SUPERVISED CLASSIFICATION, ESA MAP AND GFC DATA PRODUCTS
spc <- paste0(class_dir,classif_name)

#################### ALIGN SUPERVISED CLASSIFICATION MAP WITH SEGMENTS
mask   <- paste0(seg_dir,"segs_mmu_id.tif")
input  <- spc
ouput  <- paste0(seg_dir,"tmp_spc_clip.tif")

proj   <- proj4string(raster(mask))
extent <- extent(raster(mask))
res    <- res(raster(mask))[1]

system(sprintf("gdalwarp -co COMPRESS=LZW -t_srs \"%s\" -te %s %s %s %s -tr %s %s %s %s",
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


#################### TAKE MAJORITY CLASS PER POLYGON
system(sprintf("bash oft-segmode.bash %s %s %s",
               paste0(seg_dir,"segs_mmu_id.tif"),
               paste0(seg_dir,"tmp_spc_clip.tif"),
               paste0(seg_dir,"tmp_spc_segmode.tif")
))

####################  CREATE A PSEUDO COLOR TABLE
my_classes <- c(11,12,13,21,22,23,24,25,26,31,32,33,41,42,43,44,45,51,61,62,63)
my_colors  <- col2rgb(c("brown","yellow","yellow", # agriculture 
                        "lightgreen","lightgreen","purple","darkgreen","purple2","green", # forest
                        "orange","green1","green2", # grassland
                        "blue1","blue2","darkblue","darkblue","grey", # wetland
                        "darkred", # urban
                        "grey1","grey2","grey3" # other
                        ))
colors()


pct <- data.frame(cbind(my_classes,
                        my_colors[1,],
                        my_colors[2,],
                        my_colors[3,]
)
)

write.table(pct,paste0(seg_dir,"/color_table.txt"),row.names = F,col.names = F,quote = F)


################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(seg_dir,"/color_table.txt"),
               paste0(seg_dir,"tmp_spc_segmode.tif"),
               paste0(seg_dir,"tmp_pct_spc_segmode.tif")
))

#################### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(seg_dir,"tmp_pct_spc_segmode.tif"),
               paste0(res_dir,"spc_segmode.tif")
))

#################### ZONAL FOR ESA MAP
system(sprintf("oft-his -i %s -o %s -um %s -maxval 10",
               paste0(seg_dir,"tmp_esa_clip.tif"),
               paste0(seg_dir,"tmp_zonal_esa.txt"),
               paste0(seg_dir,"segs_id.tif")
))
threshold <- 30


system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
               gtc,
               gly,
               ggn,
               paste0(gfc_dir,"gfc_tc2016_th",threshold,".tif"),
               paste0("(A>",threshold,")*((B==0)+(C==1))*A")
))

#################### ALIGN GFC TC MAP WITH SEGMENTS
system(sprintf("oft-clip.pl %s %s %s",
               paste0(seg_dir,"segs_id.tif"),
               paste0(gfc_dir,"gfc_tc2016_th",threshold,".tif"),
               paste0(seg_dir,"tmp_gfc_tc_clip.tif")
))

#################### ZONAL FOR GFC TREE COVER MAP
system(sprintf("oft-his -i %s -o %s -um %s -maxval 100",
               paste0(seg_dir,"tmp_gfc_tc_clip.tif"),
               paste0(seg_dir,"tmp_zonal_gfc_tc.txt"),
               paste0(seg_dir,"segs_id.tif")
))
