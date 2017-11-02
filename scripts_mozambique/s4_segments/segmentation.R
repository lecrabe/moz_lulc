####################################################################################################
####################################################################################################
## Generate segments and merge GFC + ESA map
## Contact remi.dannunzio@fao.org 
## 2017/10/30
####################################################################################################
####################################################################################################
options(stringsAsFactors = FALSE)

### Load necessary packages
library(gfcanalysis)
library(rgeos)
library(ggplot2)
library(rgdal)
library(maptools)
library(dplyr)


####################################################################################
####### Segment Landsat data
####################################################################################
setwd("/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/mozambique/gis_data_moz/")
lsat_dir <- "landsat_2016/"
seg_dir  <- "segments/"
esa_dir  <- "esa_cci/"
gfc_dir  <- "gfc_mozambique/"

#################### VERIFY SATELLITE IMAGE CHARACTERISTICS
lsat_name <- paste0(lsat_dir,"lsat_2016_zambezia.tif")
lsat      <- brick(lsat_name)
res(lsat)
proj4string(lsat)
extent(lsat)
nbands(lsat)

#################### SEGMENTATION USING OFT-SEG
system(sprintf("(echo 0; echo 0 ; echo 0)|oft-seg -region -ttest -automax %s %s",
               lsat_name,
               paste0(seg_dir,"tmp_segs.tif")
))

#################### NAME OF SEGMENTS
segs <- paste0(seg_dir,"segments.tif")

#################### COMPRESS
system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
               paste0(seg_dir,"tmp_segs.tif"),
               segs
               ))

#################### CLEAN
system(sprintf("rm %s",
               paste0(seg_dir,"tmp_segs.tif")
))

################################################################################
## Perform unsupervised classification
################################################################################
spacing_km  <- 0.05
nb_clusters <- 50

## Generate a systematic grid point
system(sprintf("oft-gengrid.bash %s %s %s %s",
               lsat_name,
               spacing_km,
               spacing_km,
               paste0(seg_dir,"tmp_grid.tif")
               ))

## Extract spectral signature
system(sprintf("(echo 2 ; echo 3) | oft-extr -o %s %s %s",
               paste0(seg_dir,"tmp_grid.txt"),
               paste0(seg_dir,"tmp_grid.tif"),
               lsat_name
               ))

#################### Run k-means unsupervised classification
system(sprintf("(echo %s; echo %s) | oft-kmeans -o %s -i %s",
               paste0(seg_dir,"tmp_grid.txt"),
               nb_clusters,
               paste0(seg_dir,"tmp_segs_km.tif"),
               lsat_name
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

#################### COMPRESS
system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
               paste0(seg_dir,"tmp_sieve_segs_km.tif"),
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
               paste0(seg_dir,"tmp_clump_segs_km.tif"),
               paste0(seg_dir,"segs_km.tif")
               ))

#################### COMPRESS
system(sprintf("gdal_translate -ot UInt32 -co COMPRESS=LZW %s %s",
               paste0(seg_dir,"tmp_clump_segs_km.tif"),
               paste0(seg_dir,"segs_id.tif")
               ))

#################### CLEAN
system(sprintf("rm %s",
               paste0(seg_dir,"tmp_*.tif")
))

#################### CALL ESA MAP AND GFC DATA PRODUCTS
esa <- paste0(esa_dir,"ESACCI_mozambique_crop.tif")
gtc <- paste0(gfc_dir,"gfc_moz_treecover2000.tif")
gly <- paste0(gfc_dir,"gfc_moz_lossyear.tif")
ggn <- paste0(gfc_dir,"gfc_moz_gain.tif")

#################### ALIGN ESA MAP WITH SEGMENTS
system(sprintf("oft-clip.pl %s %s %s",
               paste0(seg_dir,"segs_id.tif"),
               esa,
               paste0(seg_dir,"tmp_esa_clip.tif")
               ))

#################### TAKE MAJORITY CLASS PER POLYGON
system(sprintf("bash oft-segmode.bash %s %s %s",
               paste0(seg_dir,"segs_id.tif"),
               paste0(seg_dir,"tmp_esa_clip.tif"),
               paste0(seg_dir,"tmp_esa_segmode.tif")
               ))

#################### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(seg_dir,"tmp_esa_segmode.tif"),
               paste0(seg_dir,"esa_segmode.tif")
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
