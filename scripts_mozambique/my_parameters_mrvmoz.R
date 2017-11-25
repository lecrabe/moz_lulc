####################################################################################################
####################################################################################################
## LOCAL PARAMETERS FOR THE PROCESS
####################################################################################################
####################################################################################################

### LOCATION AND NAME OF SUPERVISED CLASSIFICATION
classif_base <- "classif_wet_dry_ratio_430_poly_20171124"
downclassdir <- paste0(rootdir,"downloads/",classif_base,"/")
dir.create(downclassdir,showWarnings = F)
classif_name <- paste0(classif_base,".tif")


### LOCATION AND NAME OF SATELLITE MOSAIC FOR SEGMENTATION
mosaic_base  <- 'export_mosaic_lsat_dry'
downmosaidir <- paste0(rootdir,"downloads/",mosaic_base,"/")
dir.create(downmosaidir,showWarnings = F)



### TREE COVER THRESHOLD FOR GRC PRODUCT
gfc_threshold <- 30

### AD grid results
ad_grid <- paste0(adg_dir,"ad_grid.csv")

### CLASSIFICATION RESULTS
res_segmode <- paste0(res_dir,"obia_classification_segmode_20171103.tif")
res_dectree <- paste0(res_dir,"decision_tree.tif")
the_result  <- res_segmode

### CREATE A PSEUDO COLOR TABLE
my_classes <- c(11,12,13,21,22,23,24,25,26,31,32,33,41,42,43,44,45,51,61,62,63)
my_colors  <- col2rgb(c("brown","yellow","yellow", # agriculture 
                        "lightgreen","lightgreen","purple","darkgreen","purple2","green", # forest
                        "orange","green1","green2", # grassland
                        "paleturquoise2","paleturquoise3","darkblue","darkblue","grey", # wetland
                        "darkred", # urban
                        "grey1","grey2","grey3" # other
))
#colors()