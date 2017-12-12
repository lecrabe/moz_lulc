####################################################################################################
####################################################################################################
## Retrieve mosaic from GEE to feed into segmentation
## Contact remi.dannunzio@fao.org 
## 2017/11/27
####################################################################################################
####################################################################################################


###################################################################################
####### LOAD AUTHORIZATION KEY FOR "DRIVE" AND DOWNLOAD RESULTS
setwd(downclassdir)

###################################################################################
####### RUN THE FOLLOWING COMMAND ONCE, PICK UP THE LINK, GET THE AUTHORIZATION KEY
system(sprintf("echo %s | drive init",
               "KEY_MISSING"))

####### LOAD AUTHORIZATION KEY FOR "DRIVE" 
system(sprintf("echo %s | drive init",
               "4/ybdodOIR--g_DPY_1lQsDj5IFNyVF_zX7Zy6KxZJ9EQ"))

system(sprintf("drive list -matches %s > %s",
               classif_base,
               "list_tif.txt"))

data_input <- basename(unlist(read.table("list_tif.txt")))

data_input

for(data in data_input){
  system(sprintf("drive pull %s",
                 data))
}

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


#############################################################
### CLEAN
system(sprintf("rm %s",
               paste0(class_dir,"tmp_merge.vrt")
))

system(sprintf("rm %s",
               paste0(downclassdir,"*.tif")
))
