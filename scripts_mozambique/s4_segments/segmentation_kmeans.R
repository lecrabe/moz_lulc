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
mos_name <- mosaic_name
res(mosaic)
proj4string(mosaic)
extent(mosaic)
nbands(mosaic)


################################################################################
## Perform unsupervised classification
################################################################################
spacing_km  <- res(mosaic)[1]*200
nb_clusters <- 50

## Generate a systematic grid point
system(sprintf("oft-gengrid.bash %s %s %s %s",
               mosaic_name,
               spacing_km,
               spacing_km,
               paste0(seg_dir,"tmp_grid.tif")
               ))

## Extract spectral signature
system(sprintf("(echo 2 ; echo 3) | oft-extr -o %s %s %s",
               paste0(seg_dir,"tmp_grid.txt"),
               paste0(seg_dir,"tmp_grid.tif"),
               mos_name
               ))

#################### Run k-means unsupervised classification
system(sprintf("(echo %s; echo %s) | oft-kmeans -o %s -i %s",
               paste0(seg_dir,"tmp_grid.txt"),
               nb_clusters,
               paste0(seg_dir,"tmp_segs_km.tif"),
               mos_name
))

#################### SIEVE RESULTS x2
system(sprintf("gdal_sieve.py -st %s %s %s",
               2,
               paste0(seg_dir,"tmp_segs_km.tif"),
               paste0(seg_dir,"tmp_sieve_segs_km.tif")
))

#################### SIEVE RESULTS x4
system(sprintf("gdal_sieve.py -st %s %s %s",
               4,
               paste0(seg_dir,"tmp_sieve_segs_km.tif"),
               paste0(seg_dir,"tmp_sieve_sieve_segs_km.tif")
))

#################### SIEVE RESULTS x8
system(sprintf("gdal_sieve.py -st %s %s %s",
               8,
               paste0(seg_dir,"tmp_sieve_sieve_segs_km.tif"),
               paste0(seg_dir,"tmp_sieve_segs_km.tif")
))

#################### SIEVE RESULTS x12 --> ~10000m2
system(sprintf("gdal_sieve.py -st %s %s %s",
               12,
               paste0(seg_dir,"tmp_sieve_segs_km.tif"),
               paste0(seg_dir,"tmp_mmu_segs_km.tif")
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
               paste0(seg_dir,"segs_kmeans_mmu_",province,".tif")
               ))

#################### CLEAN
system(sprintf("rm %s",
               paste0(seg_dir,"tmp_*")
))

time_segments <- Sys.time() - time_start