####### DOWN and UP From and To GoogleDRIVE / SEPAL
####### Exemple de cle autorisation : 4/QHH2DucZ-MI-GY0HnG6JyEfjMpfVvJsu6_TmHqbxBgQ
setwd("~/moz_lulc")
dir.create("mosaic")

setwd("mosaic")


system(sprintf("echo %s | drive init",
               "4/AWztNEA6HGIUoqdJitOckfcQ25oiLXF541CJasaqhwM"))


system(sprintf("drive list"))

object <- "zambezia_lsat_mosaic"

system(sprintf("drive pull %s",
                 object))

