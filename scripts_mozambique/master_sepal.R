####################################################################################################
####################################################################################################
## COMBINE CLASSIFICATION AND OTHER PRODUCTS INTO OBJECTS TO CREATE LULC MAP OF MOZAMBIQUE
## ALWAYS RUN MASTER LINE BY LINE
## Contact remi.dannunzio@fao.org 
## 2017/11/02
####################################################################################################
####################################################################################################

####################################################################################################
####################################################################################################
scriptdir   <- "~/moz_lulc/scripts_mozambique/"

#############################################################
### SETUP PARAMETERS
#############################################################
source(paste0(scriptdir,"s0_setup_parameters_and_folders.R"),echo=TRUE)

#############################################################
### DOWNLOAD AND CLIP GLOBAL PRODUCTS
#############################################################
source(paste0(scriptdir,"s2_global_data/download_ESA_CCI_map.R"),echo=TRUE)
source(paste0(scriptdir,"s2_global_data/download_gfc_2016.R"),echo=TRUE)
source(paste0(scriptdir,"s2_global_data/clip_LC_products.R"),echo=TRUE)



#############################################################
### GET CLASSIFICATION PERFORMED IN SEPAL AND MERGE TILES
#############################################################

### VARIABLES TO MODIFY
downclassdir <- paste0(rootdir,"downloads/classif_zambezia_lsat_train_520_poly_wetperiod/")
classif_name <- "classification_20171101.tif"

source(paste0(scriptdir,"s3_classification/merge_classification.R"),echo=TRUE)


#############################################################
### CREATE SEGMENTS OVER THE AOI AND INTEGRATE VALUES
#############################################################

### VARIABLES TO MODIFY
downmosaidir <- paste0(rootdir,"downloads/zambezia_lsat_dry_20171102/")
mosaic_name  <- "lsat_2016_zambezia.tif"

source(paste0(scriptdir,"s4_segments/merge_mosaic.R"),echo=TRUE)
source(paste0(scriptdir,"s4_segments/segmentation.R"),echo=TRUE)
source(paste0(scriptdir,"s4_segments/decision_tree.R"),echo=TRUE)


#############################################################
### COMBINE PRODUCTS IN A DECISION TREE
#############################################################
source(paste0(scriptdir,"s5_decision_tree/TBD_XXXX.R"),echo=TRUE)
time_decision_tree <- Sys.time() - time_start

#############################################################
### USE AD GRID (Collect Earth exercise) TO ASSESS ACCURACY
#############################################################
source(paste0(scriptdir,"s6_accuracy_assessment/aa_esa_map.R"),echo=TRUE)
time_AA <- Sys.time() - time_start
