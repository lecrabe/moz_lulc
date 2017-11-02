setwd("~/moz_lulc/gfc_data/")
system(sprintf("mv %s %s",
               "*",
               gfc_dir
))

setwd("~/downloads/ESA_2016/")
system(sprintf("mv %s %s",
               "tmp_ESACCI_mozambique.tif",
               paste0(esa_dir,"esa_cci_moz.tif")
               ))
