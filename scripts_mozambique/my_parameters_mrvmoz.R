####################################################################################################
####################################################################################################
## LOCAL PARAMETERS FOR THE PROCESS
####################################################################################################
####################################################################################################

### LOCATION AND NAME OF SUPERVISED CLASSIFICATION
#classif_base <- "classif_dry_ratio_430_poly_20171125"
#classif_base <- "classif_catarina_430_poly_20171125"
#classif_base <- "classif_catarina_ratio430_poly_20171127"
#classif_base <- "classif_catarina_ratio848_poly_20171127"
#classif_base <- "classif_wet_dry_ratio848_poly_20171127"
#classif_base <- "classif_pbs_ratio_848_poly_20171205"
classif_base <- "classif_iitc_ratio_ecozone"

downclassdir <- paste0(rootdir,"downloads/",classif_base,"/")
dir.create(downclassdir,showWarnings = F)
classif_name <- paste0(classif_base,".tif")


### LOCATION AND NAME OF SATELLITE MOSAIC FOR SEGMENTATION
mosaic_base  <- 'export_mosaic_lsat_dry'
downmosaidir <- paste0(rootdir,"downloads/",mosaic_base,"/")
dir.create(downmosaidir,showWarnings = F)

### PROVINCE TO WORK ON
province <- "Maputo"

### TREE COVER THRESHOLD FOR GRC PRODUCT
gfc_threshold <- 30

### AD grid results
ad_grid <- paste0(adg_dir,"ad_grid.csv")

### CLASSIFICATION RESULTS
res_segmode <- paste0(res_dir,"obia_classification_segmode_20171103.tif")
res_dectree <- paste0(res_dir,"decision_tree.tif")
the_result  <- res_segmode

#################### PERFORM SEGMENTATION USING THE OTB-SEG ALGORITHM

params   <- c(3,   # radius of smoothing (pixels)
              16,  # radius of proximity (pixels)
              0.1, # radiance threshold 
              50,  # iterations of algorithm
              10)  # segment minimum size (pixels)


the_segments <- paste0(seg_dir,"seg_lsms_",province,"_",paste0(params,collapse = "_"),".tif")

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