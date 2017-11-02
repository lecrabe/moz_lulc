setwd("~/moz_lulc/")
for(file in list.files(".",glob2rx("gfc_data*.tif"))){
  print(file)
  new <- substr(file,9,nchar(file))
  system(sprintf("mv %s %s",
                 file,
                 paste0("gfc_data/",new)))
}
moz_dir <- "~/moz_lulc/"
esa_dir <- paste0(moz_dir,"esa_data")
dir.create(esa_dir)
setwd("~/downloads/ESA_2016/")
system(sprintf("mv %s %s",
               "tmp_ESACCI_mozambique.tif",
               paste0(esa_dir,"esa_cci_moz.tif")
               ))
