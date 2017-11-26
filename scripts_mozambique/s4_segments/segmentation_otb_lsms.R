####################################################################################################
####################################################################################################
## Generate segments over the satellite mosaic (unsupervised classif + clump)
## Contact remi.dannunzio@fao.org 
## 2017/11/02
####################################################################################################
####################################################################################################
time_start <- Sys.time() 

####################################################################################
####### Segment satellite mosaic
####################################################################################
province     <- "Maputo"
mosaic_name  <- paste0(mosaicdir,mosaic_base,"_",province,".tif")

#################### VERIFY SATELLITE IMAGE CHARACTERISTICS

mosaic   <- brick(mosaic_name)
res(mosaic)
proj4string(mosaic)
extent(mosaic)
nbands(mosaic)

# #################### TEST A SUBTILE
# system(sprintf("gdal_translate -srcwin 500 500 1000 1000 -co COMPRESS=LZW %s %s",
#                mosaic_name,
#                paste0(seg_dir,"tile_1000.tif")
# ))


#################### PERFORM SEGMENTATION USING THE OTB-SEG ALGORITHM
params <- c(3,   # radius of smoothing (pixels)
            16,  # radius of proximity (pixels)
            0.1, # radiance threshold 
            50,  # iterations of algorithm
            10)  # segment minimum size (pixels)

system(sprintf("otbcli_MeanShiftSmoothing -in %s -fout %s -foutpos %s -spatialr %s -ranger %s -thres %s -maxiter %s",
               mosaic_name,
               #paste0(seg_dir,"tile_1000.tif"),
               paste0(seg_dir,"smooth_",paste0(params,collapse = "_"),".tif"),
               paste0(seg_dir,"position_",paste0(params,collapse = "_"),".tif"),
               params[1],
               params[2],
               params[3],
               params[4]
               ))

system(sprintf("otbcli_LSMSSegmentation -in %s -inpos %s -out %s -spatialr %s -ranger %s -minsize 0 -tmpdir %s -tilesizex 4096 -tilesizey 4096",
               paste0(seg_dir,"smooth_",paste0(params,collapse = "_"),".tif"),
               paste0(seg_dir,"position_",paste0(params,collapse = "_"),".tif"),
               paste0(seg_dir,"tmp_seg_lsms_",paste0(params,collapse = "_"),".tif"),
               params[1],
               params[2],
               seg_dir
               ))


system(sprintf("otbcli_LSMSSmallRegionsMerging -in %s -inseg %s -out %s -minsize %s -tilesizex 4096 -tilesizey 4096",
               paste0(seg_dir,"smooth_",paste0(params,collapse = "_"),".tif"),
               paste0(seg_dir,"tmp_seg_lsms_",paste0(params,collapse = "_"),".tif"),
               paste0(seg_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".tif"),
               params[5]
               ))

system(sprintf("rm %s",
               paste0(seg_dir,"tmp*")))

system(sprintf("rm %s",
               paste0(seg_dir,"smooth*")))

system(sprintf("rm %s",
               paste0(seg_dir,"position*")))

time_segments <- Sys.time() - time_start
