####################################################################################################
####################################################################################################
## Merge classification results (GEE exported tiles) for integration in decision tree
## Contact remi.dannunzio@fao.org 
## 2017/11/02
####################################################################################################
####################################################################################################
time_start  <- Sys.time()


#############################################################
### MERGE
system(sprintf("gdal_merge.py -v -ot Byte -co COMPRESS=LZW -co BIGTIFF=YES -o %s %s",
               paste0(class_dir,"tmp_merge.tif"),
               paste0(downclassdir,"*.tif")
               ))

#############################################################
### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(class_dir,"tmp_merge.tif"),
               paste0(class_dir,classif_name)
               ))

#############################################################
### CLEAN
system(sprintf("rm %s",
               paste0(class_dir,"tmp_merge.tif")
               ))

time_merge_classif <- Sys.time() - time_start
