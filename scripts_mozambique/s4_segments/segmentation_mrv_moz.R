####################################################################################################
####################################################################################################
## Generate segments over the satellite mosaic (unsupervised classif + clump)
## Contact remi.dannunzio@fao.org 
## 2017/11/02
####################################################################################################
####################################################################################################
time_start <- Sys.time() 

province <- "Gaza"
mosaic_name  <- paste0(downmosaidir,mosaic_base,"_",province,".tif")

####################################################################################
####### Segment satellite mosaic
####################################################################################

#################### VERIFY SATELLITE IMAGE CHARACTERISTICS

mosaic   <- brick(mosaic_name)
res(mosaic)
proj4string(mosaic)
extent(mosaic)
nbands(mosaic)

#################### PERFORM SEGMENTATION USING THE OTB-SEG ALGORITHM
# system(sprintf("gdal_translate -srcwin 0 3000 5000 5000 -co COMPRESS=LZW %s %s",
#                mosaic_name,
#                paste0(seg_dir,"tile_5000.tif")
# ))

#################### PERFORM SEGMENTATION USING THE OTB-SEG ALGORITHM
system(sprintf("otbcli_MeanShiftSmoothing -in %s -fout %s -foutpos %s -spatialr 16 -ranger 16 -thres 0.1 -maxiter 10",
               mosaic_name,
               #paste0(seg_dir,"tile_5000.tif"),
               paste0(seg_dir,"smooth.tif"),
               paste0(seg_dir,"position.tif")
               ))

system(sprintf("otbcli_LSMSSegmentation -in %s -inpos %s -out %s -spatialr 5 -ranger 15 -minsize 0 -tilesizex 256 -tilesizey 256",
               paste0(seg_dir,"smooth.tif"),
               paste0(seg_dir,"position.tif"),
               paste0(seg_dir,"tmp_seg_lsms.tif")
               ))


system(sprintf("otbcli_LSMSSmallRegionsMerging -in %s -inseg %s -out %s -minsize 20 -tilesizex 256 -tilesizey 256",
               paste0(seg_dir,"smooth.tif"),
               paste0(seg_dir,"tmp_seg_lsms.tif"),
               paste0(seg_dir,"merged_seg_lsms_",province,".tif")
               ))


#################### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(seg_dir,"tmp_mmu_segs_km.tif"),
               paste0(seg_dir,"segs_km.tif")
))

# #################### POLYGONISE
# system(sprintf("gdal_polygonize.py -f \"ESRI Shapefile\" %s %s",
#                paste0(seg_dir,"segs_km.tif"),
#                paste0(seg_dir,"segs_km.shp")
#                ))

#################### CLUMP THE RESULTS TO OBTAIN UNIQUE ID PER POLYGON
system(sprintf("oft-clump -i %s -o %s -um %s",
               paste0(seg_dir,"segs_km.tif"),
               paste0(seg_dir,"tmp_clump_segs_mmu.tif"),
               paste0(seg_dir,"segs_km.tif")
               ))

#################### COMPRESS
system(sprintf("gdal_translate -ot UInt32 -co COMPRESS=LZW %s %s",
               paste0(seg_dir,"tmp_clump_segs_mmu.tif"),
               paste0(seg_dir,"segs_mmu_id.tif")
               ))

#################### CLEAN
system(sprintf("rm %s",
               paste0(seg_dir,"tmp_*")
))

time_segments <- Sys.time() - time_start