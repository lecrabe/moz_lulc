####################################################################################################
####################################################################################################
## Generate segments and merge GFC + ESA map
## Contact remi.dannunzio@fao.org 
## 2017/10/30
####################################################################################################
####################################################################################################
time_start <- Sys.time() 

####################################################################################
####### Segment satellite mosaic
####################################################################################
tmp          <- substr(list.files(mosaicdir),24,50)
provinces    <- substr(tmp,1,nchar(tmp)-4)
for(province in provinces){
  
  mosaic_name  <- paste0(mosaicdir,mosaic_base,"_",province,".tif")
  
  #################### VERIFY SATELLITE IMAGE CHARACTERISTICS
  mosaic   <- brick(mosaic_name)
  mos_name <- mosaic_name
  res(mosaic)
  proj4string(mosaic)
  extent(mosaic)
  nbands(mosaic)
  
  
  #################### SEGMENTATION USING OFT-SEG
  system(sprintf("(echo 0; echo 0 ; echo 0)|oft-seg -region -ttest -automax %s %s",
                 mosaic_name,
                 paste0(seg_dir,"tmp_segs_oft.tif")
  ))
  
  #################### SIEVE RESULTS x2
  system(sprintf("gdal_sieve.py -st %s %s %s",
                 2,
                 paste0(seg_dir,"tmp_segs_oft.tif"),
                 paste0(seg_dir,"tmp_sieve_segs_oft.tif")
  ))
  
  #################### SIEVE RESULTS x4
  system(sprintf("gdal_sieve.py -st %s %s %s",
                 4,
                 paste0(seg_dir,"tmp_sieve_segs_oft.tif"),
                 paste0(seg_dir,"tmp_sieve_sieve_segs_oft.tif")
  ))
  
  #################### SIEVE RESULTS x8
  system(sprintf("gdal_sieve.py -st %s %s %s",
                 8,
                 paste0(seg_dir,"tmp_sieve_sieve_segs_oft.tif"),
                 paste0(seg_dir,"tmp_sieve_segs_oft.tif")
  ))
  
  #################### SIEVE RESULTS x12 --> ~10000m2
  system(sprintf("gdal_sieve.py -st %s %s %s",
                 12,
                 paste0(seg_dir,"tmp_sieve_segs_oft.tif"),
                 paste0(seg_dir,"tmp_mmu_segs_oft.tif")
  ))
  
  #################### COMPRESS
  system(sprintf("gdal_translate -ot UInt32 -co COMPRESS=LZW %s %s",
                 paste0(seg_dir,"tmp_mmu_segs_oft.tif"),
                 paste0(seg_dir,"tmp_segs_oft.tif")
  ))
  
  # #################### POLYGONISE
  # system(sprintf("gdal_polygonize.py -f \"ESRI Shapefile\" %s %s",
  #                paste0(seg_dir,"segs_km.tif"),
  #                paste0(seg_dir,"segs_km.shp")
  #                ))
  
  #################### CLUMP THE RESULTS TO OBTAIN UNIQUE ID PER POLYGON
  system(sprintf("oft-clump -i %s -o %s -um %s",
                 paste0(seg_dir,"tmp_segs_oft.tif"),
                 paste0(seg_dir,"tmp_clump_segs_mmu_oft.tif"),
                 paste0(seg_dir,"tmp_segs_oft.tif")
  ))
  
  #################### COMPRESS
  system(sprintf("gdal_translate -ot UInt32 -co COMPRESS=LZW %s %s",
                 paste0(seg_dir,"tmp_clump_segs_mmu_oft.tif"),
                 paste0(seg_dir,"segs_oft_mmu_",province,".tif")
  ))
  
  #################### CLEAN
  system(sprintf("rm %s",
                 paste0(seg_dir,"tmp_*")
  ))
  
}
time_segments <- Sys.time() - time_start