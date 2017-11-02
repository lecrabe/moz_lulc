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

#############################################################
### HARMONIZE MERGE AND SELECT TRAINING DATA -->>  IN DESKTOP 
#############################################################

scriptdir   <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/mozambique/scripts_mozambique/"

source(paste0(scriptdir,"s1_training_data/harmonize_shp.R"),echo=TRUE)
source(paste0(scriptdir,"s1_training_data/select_training.R"),echo=TRUE)


