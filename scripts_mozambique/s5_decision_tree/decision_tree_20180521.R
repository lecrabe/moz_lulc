####################################################################################################
####################################################################################################
## Use a decision tree to integrate raster values inside segments
## Contact remi.dannunzio@fao.org 
## 2018/04/06
####################################################################################################
####################################################################################################
time_start <- Sys.time() 

#################### CALL SUPERVISED CLASSIFICATIONS
spc_wd <- paste0(class_dir,"classif_wet_dry_ratio848_poly_20171127.tif")
spc_k  <- paste0(class_dir,"classif_catarina_ratio848_poly_20171127.tif")
#spc_k  <- paste0(class_dir,"classif_pbs_ratio_848_poly_20171205.tif")

#################### CREATE COLOR TABLE
pct <- data.frame(cbind(my_classes,
                        my_colors[1,],
                        my_colors[2,],
                        my_colors[3,]))

write.table(pct,paste0(seg_dir,"/color_table.txt"),row.names = F,col.names = F,quote = F)

#################### GET LIST OF SUBSETS (PROVINCES) TO PROCESS
provinces          <- substr(
  list.files(seg_dir,glob2rx("seg_lsms*.tif")),
  10,
  nchar(list.files(seg_dir,glob2rx("seg_lsms*.tif")))-19
)

#################### LOPP THROUGH EACH SUBSET --> START WITH ONE PROVINCE ONLY [1], Cabo Delgado
#################### ONCE YOU HAVE RUN FOR ONE PROVINCE. DOWNLOAD AND VERIFY
#################### IF ALL GOOD, DELETE [1] below and RUN FOR ALL PROVINCES
for(province in provinces[c(10:14)]){

  the_segments <- paste0(seg_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".tif")
  
  #################### ALIGN SUPERVISED CLASSIFICATION MAP WITH SEGMENTS : IITC classification
  mask   <- the_segments
  input  <- spc_k
  ouput  <- paste0(seg_dir,"tmp_spc_k_clip.tif")
  
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
  
  #################### ALIGN SUPERVISED CLASSIFICATION MAP WITH SEGMENTS : WET DRY
  input  <- spc_wd
  ouput  <- paste0(seg_dir,"tmp_spc_wd_clip.tif")
  
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
  
  
  ####################################################################################################
  #################### OPTION 1: MAJORITY RULE OF SCP
  ####################################################################################################
  
  # #################### TAKE MAJORITY CLASS PER POLYGON
  # system(sprintf("bash oft-segmode.bash %s %s %s",
  #                the_segments,
  #                paste0(seg_dir,"tmp_spc_k_clip.tif"),
  #                paste0(seg_dir,"tmp_spc_segmode.tif")
  # ))
  
  

  
  # ################################################################################
  # ## Add pseudo color table to result
  # system(sprintf("(echo %s) | oft-addpct.py %s %s",
  #                paste0(seg_dir,"/color_table.txt"),
  #                paste0(seg_dir,"tmp_spc_segmode.tif"),
  #                paste0(seg_dir,"tmp_pct_spc_segmode.tif")
  # ))
  # 
  # #################### COMPRESS
  # system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
  #                paste0(seg_dir,"tmp_pct_spc_segmode.tif"),
  #                paste0(res_dir,province,"_spc_segmode.tif")
  # ))
  
  
  ####################################################################################################
  #################### OPTION 2: DECISION TREE 
  ####################################################################################################
  
  #################### ZONAL FOR SPC MAPS: K, WD and D
  system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
                 paste0(seg_dir,"tmp_spc_k_clip.tif"),
                 paste0(seg_dir,"tmp_zonal_spc_k.txt"),
                 the_segments,
                 max(my_classes)
  ))
  
  system(sprintf("oft-his -i %s -o %s -um %s -maxval %s",
                 paste0(seg_dir,"tmp_spc_wd_clip.tif"),
                 paste0(seg_dir,"tmp_zonal_spc_wd.txt"),
                 the_segments,
                 max(my_classes)
  ))
  
  
  #################### ALIGN ESA MAP WITH SEGMENTS
  mask   <- the_segments
  input  <- esa
  ouput  <- paste0(seg_dir,"tmp_esa_clip.tif")
  
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
  
  #################### ZONAL FOR ESA MAP
  system(sprintf("oft-his -i %s -o %s -um %s -maxval 10",
                 paste0(seg_dir,"tmp_esa_clip.tif"),
                 paste0(seg_dir,"tmp_zonal_esa.txt"),
                 the_segments
  ))
  
  # #################### CREATE GFC 2016 TREE COVER MAP
  # system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
  #                gtc,
  #                gly,
  #                ggn,
  #                paste0(gfc_dir,"gfc_tc2016_th",gfc_threshold,".tif"),
  #                paste0("(A>",gfc_threshold,")*((B==0)+(C==1))*A")
  # ))
  # 
  # 
  #################### ALIGN GFC MAP WITH SEGMENTS
  mask   <- the_segments
  input  <- paste0(gfc_dir,"gfc_tc2016_th",gfc_threshold,".tif")
  ouput  <- paste0(seg_dir,"tmp_gfc_tc_clip.tif")
  
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
  
  #################### ZONAL FOR GFC TREE COVER MAP
  system(sprintf("oft-stat -i %s -o %s -um %s",
                 paste0(seg_dir,"tmp_gfc_tc_clip.tif"),
                 paste0(seg_dir,"tmp_zonal_gfc_tc.txt"),
                 the_segments
  ))
  
  #################### READ THE ZONAL STATS
  df_spc_k  <- read.table(paste0(seg_dir,"tmp_zonal_spc_k.txt"))
  df_spc_w  <- read.table(paste0(seg_dir,"tmp_zonal_spc_wd.txt"))
  df_esa    <- read.table(paste0(seg_dir,"tmp_zonal_esa.txt"))
  df_gfc    <- read.table(paste0(seg_dir,"tmp_zonal_gfc_tc.txt"))
  
  names(df_spc_k)  <- c("clump_id","total_spk",paste0("spk_",0:max(my_classes)))
  names(df_spc_w)  <- c("clump_id","total_spw",paste0("spw_",0:max(my_classes)))
  names(df_gfc)    <- c("clump_id","total_gfc","av_gfc","sd_gfc")
  names(df_esa)    <- c("clump_id","total_esa",paste0("esa_",0:10))
  hist(df_gfc$sd_gfc)
  
  ####### INITIATE THE OUT DATAFRAME
  df <- df_spc_k[,c("clump_id","total_spk")]
  
  ####### CALCULATE MAJORITY CLASS FOR EACH THEMATIC PRODUCT
  df$mode_esa <- c(0:10)[max.col(df_esa[,paste0("esa_",0:10)])]
  df$mode_spk <- c(0:max(my_classes))[max.col(df_spc_k[,paste0("spk_",0:max(my_classes))])]
  df$mode_spw <- c(0:max(my_classes))[max.col(df_spc_w[,paste0("spw_",0:max(my_classes))])]
  df$sd_gfc   <- df_gfc$sd_gfc
  
  table(df$mode_spk,df$mode_spw)
  table(df$mode_esa,df$mode_spk)
  
  ####### BY DEFAULT ALL POLYGONS ARE SET TO ZERO
  df$out <- 0
  
  tryCatch({
    df[df$mode_spk %in% c(0) ,]$out <- df[df$mode_spk %in% c(0) ,]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  ####################################################################################################
  ####### AGRICULTURE BRANCH
  tryCatch({
    df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(11:13,31:33) & df$mode_esa %in% c(4),]$out      <- 12
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(11:13,31:33) & !(df$mode_esa %in% c(4)),]$out      <- 
      df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(11:13,31:33) & !(df$mode_esa %in% c(4)),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c(0,1,2),]$out      <- 
      df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c(0,1,2),]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c(3:7),]$out      <- 
      df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c(3:7),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c( 8),]$out       <- 51
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c(10),]$out       <- 44
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(41:44) & df$mode_esa %in% c(10),]$out       <- 44
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(41:44) & df$mode_esa %in% c(0:9),]$out      <- 
      df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(41:44) & df$mode_esa %in% c(0:9),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(51:63) & df$mode_esa %in% c(7,8),]$out      <-
      df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(51:63) & df$mode_esa %in% c(7,8),]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(51:63) & df$mode_esa %in% c(0:6,10),]$out   <-
      df[df$mode_spk %in% c(11,12,13) & df$mode_spw %in% c(51:63) & df$mode_esa %in% c(0:6,10),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  
  ####################################################################################################
  ####### FOREST BRANCH
  tryCatch({
    df[df$mode_spk %in% c(21:24) & df$mode_spw %in% c(21:24),]$out      <- 
      df[df$mode_spk %in% c(21:24) & df$mode_spw %in% c(21:24),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(21:24) & df$mode_spw %in% c(25:26),]$out      <- 
      df[df$mode_spk %in% c(21:24) & df$mode_spw %in% c(25:26),]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(25:26) & df$mode_spw %in% c(21:24),]$out      <- 
      df[df$mode_spk %in% c(25:26) & df$mode_spw %in% c(21:24),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(25:26) & df$mode_spw %in% c(25:26) & df$mode_esa %in% c(4),]$out      <- 11
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(25:26) & df$mode_spw %in% c(25:26) & !(df$mode_esa %in% c(4)),]$out      <- 
      df[df$mode_spk %in% c(25:26) & df$mode_spw %in% c(25:26) & !(df$mode_esa %in% c(4)),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(11:13,31:33) & df$mode_esa %in% c(0,1,2),]$out  <-
      df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(11:13,31:33) & df$mode_esa %in% c(0,1,2),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(11:13,31:33) & df$mode_esa %in% c(3:7),]$out  <-
      df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(11:13,31:33) & df$mode_esa %in% c(3:7),]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(11:13,31:33) & df$mode_esa %in% c(8),  ]$out  <- 51
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(11:13,31:33) & df$mode_esa %in% c(10), ]$out  <- 44
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(41:44)       & df$mode_esa %in% c(10), ]$out  <- 
      df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(41:44)       & df$mode_esa %in% c(10), ]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(41:44)       & df$mode_esa %in% c(0:9),]$out  <- 
      df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(41:44)       & df$mode_esa %in% c(0:9),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(51:63)       & df$mode_esa %in% c(7:8),]$out  <- 
      df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(51:63)       & df$mode_esa %in% c(7:8),]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(51:63)       & df$mode_esa %in% c(0:6,10),]$out <- 
      df[df$mode_spk %in% c(21:26) & df$mode_spw %in% c(51:63)       & df$mode_esa %in% c(0:6,10),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  
  ####################################################################################################
  ####### GRASSLAND BRANCH
  tryCatch({
    df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(11:13,31:33),]$out      <- 
      df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(11:13,31:33),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c(1,2),]$out      <- 
      df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c(1,2),]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c(0,3:7),]$out      <- 
      df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c(0,3:7),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c( 8),]$out       <- 51
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(21:26) & df$mode_esa %in% c(10),]$out       <- 44
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(41:44) & df$mode_esa %in% c(10),]$out       <- 44
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(41:44) & df$mode_esa %in% c(0:9),]$out      <- 
      df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(41:44) & df$mode_esa %in% c(0:9),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(51:63) & df$mode_esa %in% c(7,8),]$out      <-
      df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(51:63) & df$mode_esa %in% c(7,8),]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(51:63) & df$mode_esa %in% c(0:6,10),]$out   <-
      df[df$mode_spk %in% c(31:33) & df$mode_spw %in% c(51:63) & df$mode_esa %in% c(0:6,10),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  
  ####################################################################################################
  ####### WETLAND BRANCH
  tryCatch({
    df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(41:42),]$out      <- 
      df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(41:42),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(43:44) & df$mode_esa %in% c(0:7),]$out      <- 
      df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(43:44) & df$mode_esa %in% c(0:7),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(43:44) & df$mode_esa %in% c(10),]$out     <- 44
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(43:44) & df$mode_esa %in% c(8 ),]$out   <-  51
    1},error=function(e){cat("Not relevant\n")})

  tryCatch({
    df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(51) & df$mode_esa %in% c(8),]$out       <-  51
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(51) & !(df$mode_esa %in% c(8)),]$out    <-  41
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(11:33,61:63) & df$mode_esa %in% c(2:5,10),]$out       <- 
      df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(11:33,61:63) & df$mode_esa %in% c(2:5,10),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(11:33,61:63) & df$mode_esa %in% c(0:1,6:8),]$out    <- 
      df[df$mode_spk %in% c(41:42) & df$mode_spw %in% c(11:33,61:63) & df$mode_esa %in% c(0:1,6:8),]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  
  ####################################################################################################
  ####### WATER BRANCH
  tryCatch({
    df[df$mode_spk %in% c(43:44) & df$mode_spw %in% c(41:44),]$out      <- 44
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(43:44) & df$mode_spw %in% c(1:33,51:63) & df$mode_esa %in% c(10),]$out       <- 44
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(43:44) & df$mode_spw %in% c(1:33,51:63) & df$mode_esa %in% c(1:9),]$out      <- 
      df[df$mode_spk %in% c(43:44) & df$mode_spw %in% c(1:33,51:63) & df$mode_esa %in% c(1:9),]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  
  ####################################################################################################
  ####### URBAN BRANCH
  tryCatch({
    df[df$mode_spk %in% c(51) & df$mode_spw %in% c(51) & df$mode_esa %in% c(8),]$out <- 51
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(51) & df$mode_spw %in% c(51) & df$mode_esa != 8     ,]$out <- 61
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(51) & df$mode_spw != 51 & df$mode_esa %in% c(8),]$out      <- 51
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(51) & df$mode_spw != 51 & df$mode_esa != 8,]$out           <- 
      df[df$mode_spk %in% c(51) & df$mode_spw != 51 & df$mode_esa != 8,]$mode_spw
  },error=function(e){cat("Not relevant\n")})
  
  
  ####################################################################################################
  ####### OTHER LAND BRANCH
  tryCatch({
    df[df$mode_spk %in% c(61:63) & df$mode_spw %in% c(61:63),]$out                                <- 
      df[df$mode_spk %in% c(61:63) & df$mode_spw %in% c(61:63),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(61:63) & df$mode_spw %in% c(11:51) & df$mode_esa %in% c(6,7),]$out      <- 
      df[df$mode_spk %in% c(61:63) & df$mode_spw %in% c(11:51) & df$mode_esa %in% c(6,7),]$mode_spk
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(61:63) & df$mode_spw %in% c(11:51) & df$mode_esa %in% c(8),]$out      <- 51
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(61:63) & df$mode_spw %in% c(11:51) & df$mode_esa %in% c(10),]$out      <- 44
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(61:63) & df$mode_spw %in% c(11:51) & df$mode_esa %in% c(10),]$out      <- 44
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(61:63) & df$mode_spw %in% c(11:51) & df$mode_esa %in% c(0:3,5),]$out      <- 63
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(61:63) & df$mode_spw %in% c(11:13) & df$mode_esa %in% c(4),]$out      <- 12
  },error=function(e){cat("Not relevant\n")})
  
  tryCatch({
    df[df$mode_spk %in% c(61:63) & df$mode_spw %in% c(21:51) & df$mode_esa %in% c(4),]$out      <- 63
  },error=function(e){cat("Not relevant\n")})
  
  table(df$out)
  table(df$out,df$mode_spk)
  
  
  
  write.table(df[,c("clump_id","total_spk","out","mode_spk","mode_spw","mode_esa","sd_gfc")],
              paste0(seg_dir,province,"_reclass.txt"),row.names = F,col.names = F)
  
  
  ################################################################################
  #################### Reclassify 
  system(sprintf("(echo %s; echo 1; echo 1; echo 3; echo 0) | oft-reclass  -oi %s  -um %s %s",
                 paste0(seg_dir,province,"_reclass.txt"),
                 paste0(seg_dir,"tmp_reclass.tif"),
                 the_segments,
                 the_segments
  ))
  
  ################################################################################
  #################### CONVERT TO BYTE
  system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
                 paste0(seg_dir,"tmp_reclass.tif"),
                 paste0(seg_dir,"tmp_reclass_byte.tif")
  ))
  
  ################################################################################
  #################### Add pseudo color table to result
  system(sprintf("(echo %s) | oft-addpct.py %s %s",
                 paste0(seg_dir,"/color_table.txt"),
                 paste0(seg_dir,"tmp_reclass_byte.tif"),
                 paste0(seg_dir,"tmp_pct_decision_tree.tif")
  ))
  
  ################################################################################
  #################### COMPRESS
  system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
                 paste0(seg_dir,"tmp_pct_decision_tree.tif"),
                 paste0(res_dir,province,"_decision_tree_20180521.tif")
  ))
  
  system(sprintf("rm %s",
                 paste0(seg_dir,"tmp*.tif")))

  system(sprintf("rm %s",
                 paste0(seg_dir,"tmp*.txt")))
  
  time_decision_tree <- Sys.time() - time_start
  assign(paste0("time_",province),time_decision_tree)
  
}

