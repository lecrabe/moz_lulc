####################################################################################################
####################################################################################################
## Merge mosaic to feed into segmentation / unsupervised classification
## Contact remi.dannunzio@fao.org 
## 2017/11/02
####################################################################################################
####################################################################################################

#############################################################
### MERGE
system(sprintf("gdal_merge.py -v -co COMPRESS=LZW -co BIGTIFF=YES -o %s %s",
               paste0(mosaicdir,"tmp_merge.tif"),
               paste0(downmosaidir,"*.tif")
               ))

#############################################################
### COMPRESS
system(sprintf("gdal_translate -co COMPRESS=LZW %s %s",
               paste0(mosaicdir,"tmp_merge.tif"),
               paste0(mosaicdir,mosaic_name)
               ))

#############################################################
### CLEAN
system(sprintf("rm %s",
               paste0(mosaicdir,"tmp_merge.tif")
               ))

