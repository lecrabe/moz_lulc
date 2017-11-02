####################################################################################
####### Object:  Harmonize and merge training shapefiles            
####### Author:  remi.dannunzio@fao.org                               
####### Update:  2017/10/31                                     
####################################################################################

######## SET YOUR WORKING DIRECTORY
rootdir <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/mozambique/training/"
date    <- 20171101

######## LOAD PACKAGES & OPTIONS
library(raster)
library(rgeos)
library(rgdal)

library(foreign)
library(plyr)
library(ggplot2)
library(stringr)

options(stringsAsFactors = F)

######## FOLDER WITH SHAPEFILES EXPORTED FROM ENVI
inp_dir <- paste0(rootdir,"envi_export/")

######## FOLDER TO OUTPUT HARMONIZED SHAPEFILES
out_dir <- paste0(rootdir,"harmonized/")
merge_dir <- paste0(rootdir,"harm_merged/")

dir.create(out_dir)
dir.create(merge_dir)

######## SET WORKING DIRECTORY
setwd(inp_dir)

######## LIST OF SHP AND DBF
list_shp <- list.files(".",pattern=glob2rx("*.shp"),recursive = T)
list_dbf <- list.files(".",pattern=".dbf",recursive = T)

######## LIST OF ATTRIBUTES IN ALL SHAPEFILES
list_col <- c()
for(dbf in list_dbf){
  dbf <- read.dbf(dbf)
  list_col <- unique(c(list_col,names(dbf)))
}

######## FUNCTION TO EVALUATE VALUES OF AN ATTRIBUTE
list_values <- function(x){
  the_list <- c()
  
  for(dbf in list_dbf){
    dbf <- read.dbf(dbf)
    if(x %in% names(dbf)){
      the_list <- unique(c(the_list,levels(as.factor(dbf[,x]))))
    }
  }
  the_list
}

######## APPLY FUNCTION TO A SUBSET OF THE ATTRIBUTES
sapply(list_col[grep(c("class"),list_col,ignore.case = T)],list_values)
sapply("nome",list_values)
sapply(list_col[grep(c("lulc"),list_col,ignore.case = T)],list_values)
sapply(list_col,list_values)

######## SET VALID ATTRIBUTES LIST
valid <- c("lulc_nivel","nome","Classes","classes","CLASS_NAME")

######## CHECK HOW MANY VALID ATTRIBUTES PER SHAPEFILE
for(dbf_name in list_dbf){
  dbf <- read.dbf(dbf_name)
  #print(length(names(dbf)[names(dbf) %in% valid]))
  if(length(names(dbf)[names(dbf) %in% valid]) > 1){
    print(dbf_name)
  }
}

i<- 1
######## HARMONIZATION LOOP
for(i in 1:length(list_shp)){
  ######## STORE CHARACTERISTICS OF SHAPE IN VARIABLES
  shp  <- list_shp[i]
  base <- substr(basename(shp),1,nchar(basename(shp))-4)
  orig <- unlist(strsplit(shp,"/"))[1]
  auth <- unlist(strsplit(orig,"_"))[1]
  tile <- unlist(strsplit(orig,"_"))[2]
  layr <- paste0("harm_",orig,"_",i)
  print(paste0("Shape: ",shp," Rank: ",i))
  
  tryCatch({
    ######## READ SHAPEFILE
    shp  <- readOGR(shp,base,verbose = F)
    dbf  <- shp@data
    plot(shp)
    
    ######## CREATE HARMONIZATION COLUMN
    dbf$tmp_harm <- "none"
    if(length(names(dbf)[names(dbf) %in% valid]) == 1){
      dbf$tmp_harm <- dbf[,names(dbf)[names(dbf) %in% valid]]
    }
    
    ######## CREATE AUTHOR< GRANULE AND ORIGINAL FILE NAME COLUMN
    dbf$author   <- auth
    dbf$granule  <- tile
    dbf$tmp_file <- base
    
    ######## SELECT ONLY HARMONIZED COLUMNS AND EXPORT
    shp@data <- dbf[,c("author","granule","tmp_file","tmp_harm")]
    writeOGR(shp,paste0(out_dir,layr,".shp"),layr,"ESRI Shapefile",overwrite_layer = T)
    
  },error=function(e){cat(paste0("Can't read shapefile :"),shp)
  })
  
}

######## CHANGE WORKING DIRECTORY (OUTPUT DIRECTORY)
setwd(out_dir)

######## LIST OF HARMONIZED SHAPEFILES
list_harm <- list.files(".",pattern=glob2rx("*.shp"),recursive = T)

######## LIST OF AUTHORS
authors <- c("alismo","hercilo","muri","credencio","delfio")

######## MERGE ALL SHAPEFILES PER AUTHOR
for(author in authors){
  list_author    <- list_harm[grep(author,list_harm)] 
  for(shp in list_author){
    system(sprintf("ogr2ogr -update -append %s %s -skipfailure -nln %s",
                   paste0(merge_dir,"tmp_harm_",author,".shp"),
                   shp,
                   paste0("tmp_harm_",author)
    ))
  }
  }
    
######## LIST OF HARMONIZED MERGED SHAPEFILES
setwd(merge_dir)
list_harm <- list.files(".",pattern=glob2rx("tmp*.shp"))
for(shp in list_harm){
  print(shp)
  shp <- readOGR(shp)
  print(table(shp$tmp_harm))
}


########### CLEAN ALISMO
shp <- readOGR("tmp_harm_alismo.shp")
dbf <- shp@data

table(dbf$tmp_harm)

dbf$class_harm <- str_split_fixed(dbf$tmp_harm,"_",3)[,1]
dbf$comment    <- str_split_fixed(dbf$tmp_harm,"_",3)[,2]

table(dbf$class_harm)
table(dbf$comment)

shp@data <- dbf
writeOGR(shp,"harm_alismo.shp","harm_alismo","ESRI Shapefile",overwrite_layer = T)

########### CLEAN DELFIO
shp <- readOGR("tmp_harm_delfio.shp")
dbf <- shp@data

table(dbf$tmp_harm)
dbf$class_harm <- dbf$tmp_harm
dbf$comment    <- "none"

shp@data <- dbf
writeOGR(shp,"harm_delfio.shp","harm_delfio","ESRI Shapefile",overwrite_layer = T)
           
########### CLEAN CREDENCIO 
shp <- readOGR("tmp_harm_credencio.shp")
dbf <- shp@data

table(dbf$tmp_harm)
dbf$class_harm <- str_split_fixed(dbf$tmp_harm," ",2)[,1]
dbf$comment    <- str_split_fixed(dbf$tmp_harm," ",2)[,2]
table(dbf$class_harm)
table(dbf$comment)
shp@data <- dbf
writeOGR(shp,"harm_credencio.shp","harm_credencio","ESRI Shapefile",overwrite_layer = T)

########### CLEAN MURI
shp <- readOGR("tmp_harm_muri.shp")
dbf <- shp@data

table(dbf$tmp_harm)

dbf$class_harm <- str_split_fixed(dbf$tmp_harm,"_",3)[,2]
dbf$comment    <- str_split_fixed(dbf$tmp_harm,"_",3)[,3]

table(dbf$class_harm)
table(dbf$comment)

shp@data <- dbf
writeOGR(shp,"harm_muri.shp","harm_muri","ESRI Shapefile",overwrite_layer = T)

########### CLEAN HERCILO
shp <- readOGR("tmp_harm_hercilo.shp")
dbf <- shp@data

table(dbf$tmp_harm)

dbf$class_harm <- str_split_fixed(dbf$tmp_harm,"_",3)[,2]
dbf$comment    <- str_split_fixed(dbf$tmp_harm,"_",3)[,3]

table(dbf$class_harm)
table(dbf$comment)

shp@data <- dbf
writeOGR(shp,"harm_hercilo.shp","harm_hercilo","ESRI Shapefile",overwrite_layer = T)

########### MERGE ALL TOGETHER
for(shp in list.files(".",pattern=glob2rx("harm*.shp"))){
  system(sprintf("ogr2ogr -update -append %s %s -skipfailure -nln %s",
                 paste0(rootdir,"merged_harm.shp"),
                 shp,
                 paste0("merged_harm")
  ))
}

########### COMPUTE AREAS
setwd(rootdir)
shp <- readOGR("merged_harm.shp")
dbf <- shp@data

proj4string(shp)
dbf$area <- gArea(shp,byid = T)/10000
tapply(dbf$area,dbf$class_harm,sum)
summary(dbf$area)
hist(log(dbf$area))

table(dbf$class_harm,dbf$granule)

########### READ CODES
codes <- read.csv("code_list_lc.csv")
codes
codes$nivel3_code
names(codes)

dbf$unique_id <- row(dbf)[,1]
head(dbf)

########### MERGE CODES FOR CLASSIFICATION
df <- merge(dbf,
            codes[,c("nivel1_code","nivel2_code","nivel3_code","nivel3_label_pt","code_l2","code_l3")],
            by.x="class_harm",
            by.y="nivel3_code",
            all.x=T)
names(df)[1] <- "nivel3_code"

########### CHECK DISTRIBUTION OF TRAINING DATA PER CLASS
table(df$nivel3_code,df$nivel1_code,useNA="always")
table(dbf$class_harm)
table(shp$nivel2_code,shp$granule)

########### OVERWRITE DBF WITH MERGED DATAFRAME, SORT FIRST BY POLYGON ID
shp@data <- arrange(df,unique_id)


########### TRUNCATE NAMES TO 10 DIGITS
names(shp)
shp@data <- shp@data[,c("unique_id","author","granule","tmp_file","area",
                        "nivel1_code","nivel2_code","nivel3_code","nivel3_label_pt",
                        "code_l2","code_l3","comment")]

names(shp) <- c("poly_id","author","granule","orig_file","area",
                "lev1_code","lev2_code","lev3_code","lev3_label",
                "code_l2","code_l3","comment")

########### EXPORT
writeOGR(shp,
         paste0(rootdir,"all_training_",date,".shp"),
         paste0("all_training_",date),
         "ESRI Shapefile",
         overwrite_layer = T)

