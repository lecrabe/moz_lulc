####################################################################################################
####################################################################################################
## DOWNLOAD ESA DATA IN SEPAL
## Contact remi.dannunzio@fao.org 
## 2017/11/02
####################################################################################################
####################################################################################################


###### IMPORTANT --> LICENSE FROM ESA
#   The present product is made available to the public by ESA and the consortium. 
#   You may use S2 prototype LC 20m map of Africa 2016 for educational and/or scientific purposes, without any fee on the condition that you credit the ESA Climate Change Initiative and in particular its Land Cover project as the source of the CCI-LC database:
#   Copyright notice:
#   © Contains modified Copernicus data (2015/2016)
# © ESA Climate Change Initiative - Land Cover project 2017

###### INSTRUCTIONS
###### Get an authorized download link here: http://2016africalandcover20m.esrin.esa.int/download.php
authorized_url <- "http://2016africalandcover20m.esrin.esa.int/download.php?token=29abc6b51a196a1b5ff5c631f2011216&email=remi.dannunzio@fao.org"

## Folder where your ESA data archives get stored
esa_folder    <-  "~/downloads/ESA_2016/"
dir.create(esa_folder)
setwd(esa_folder)

## DOWNLOAD
download.file(authorized_url,
              paste0(esa_folder,"esa_cci.zip"),
              method="auto")

## UNZIP
system(sprintf("unzip esa_cci.zip"))

## DELETE ZIP
system(sprintf("rm esa_cci.zip"))
