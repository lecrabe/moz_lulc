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
source(paste0(scriptdir,"s0_load_packages_set_folders.R"),echo=TRUE)
source(paste0(scriptdir,"my_parameters.R"),echo=TRUE)


#############################################################
### DOWNLOAD AND CLIP GLOBAL PRODUCTS
#############################################################
source(paste0(scriptdir,"s2_global_data/download_ESA_CCI_map.R"),echo=TRUE)
source(paste0(scriptdir,"s2_global_data/download_gfc_2016.R"),echo=TRUE)
source(paste0(scriptdir,"s2_global_data/clip_LC_products.R"),echo=TRUE)


#############################################################
### GET CLASSIFICATION PERFORMED IN SEPAL AND MERGE TILES
#############################################################
source(paste0(scriptdir,"s3_classification/merge_classification.R"),echo=TRUE)


#############################################################
### CREATE SEGMENTS OVER THE AOI AND INTEGRATE VALUES
#############################################################
source(paste0(scriptdir,"s4_segments/merge_mosaic.R"),echo=TRUE)
source(paste0(scriptdir,"s4_segments/segmentation.R"),echo=TRUE)


#############################################################
### COMBINE PRODUCTS IN A DECISION TREE
#############################################################
source(paste0(scriptdir,"s5_decision_tree/decision_tree.R"),echo=TRUE)


#############################################################
### USE AD GRID (Collect Earth exercise) TO ASSESS ACCURACY
#############################################################
#source(paste0(scriptdir,"s6_accuracy_assessment/aa_map_with_ad_grid.R"),echo=TRUE)

