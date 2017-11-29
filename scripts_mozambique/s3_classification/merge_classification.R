####################################################################################################
####################################################################################################
## Merge classification results (GEE exported tiles) for integration in decision tree
## Contact remi.dannunzio@fao.org 
## 2017/11/02
####################################################################################################
####################################################################################################
time_start  <- Sys.time()

# for(file in list.files(downclassdir,pattern=".tif")){
# system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
#                paste0(downclassdir,file),
#                paste0(downclassdir,"byte_",file)
# ))
# }

#############################################################
### MERGE AS VRT
system(sprintf("gdalbuildvrt %s %s",
               paste0(class_dir,"tmp_merge.vrt"),
               paste0(downclassdir,"*.tif")
               ))


#############################################################
### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(class_dir,"tmp_merge.vrt"),
               paste0(class_dir,classif_name)
               ))

# #############################################################
# ### STATS
# system(sprintf("oft-stat -i %s -o  %s -um %s",
#                paste0(class_dir,classif_name),
#                paste0(class_dir,"stats.txt"),
#                paste0(class_dir,classif_name)
# ))

#############################################################
### CLEAN
system(sprintf("rm %s",
               paste0(class_dir,"tmp_merge.vrt")
               ))

time_merge_classif <- Sys.time() - time_start
