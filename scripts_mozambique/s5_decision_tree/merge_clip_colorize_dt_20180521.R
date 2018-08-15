####################################################################################################
####################################################################################################
## GET REFERENCE DATA FROM AD GRID FOR ACCURACY ASSESSMENT OF RESULTS
## Contact remi.dannunzio@fao.org 
## 2018/04/06
####################################################################################################
####################################################################################################

#############################################################
### MERGE AS VRT
system(sprintf("gdalbuildvrt %s %s",
               paste0(res_dir,"tmp_merge.vrt"),
               paste0(res_dir,"segment_tile*_decision_tree_20180523.tif")
))

system(sprintf("gdalwarp -t_srs %s -co COMPRESS=LZW %s %s",
               paste0(res_dir,"lamb_azim.txt"),
               paste0(res_dir,"tmp_merge.vrt"),
               paste0(res_dir,"tmp_map_prj.tif")
))


#############################################################
### CROP TO COUNTRY BOUNDARIES
system(sprintf("python %s/s7_misc/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
               scriptdir,
               paste0(limit_dir,"districtos_laea.shp"),
               paste0(res_dir,"tmp_map_prj.tif"),
               paste0(res_dir,"tmp_dt_merge_clip.tif"),
               "id"
))

#################### CREATE COLOR TABLE
pct <- data.frame(cbind(my_classes,
                        my_colors[1,],
                        my_colors[2,],
                        my_colors[3,]))

write.table(pct,paste0(seg_dir,"/color_table.txt"),row.names = F,col.names = F,quote = F)

################################################################################
#################### Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(seg_dir,"/custom_color_table.txt"),
               paste0(res_dir,"tmp_dt_merge_clip.tif"),
               paste0(res_dir,"tmp_pct_dt_merge_clip.tif")
))

################################################################################
#################### COMPRESS
system(sprintf("gdal_translate -ot Byte -co COMPRESS=LZW %s %s",
               paste0(res_dir,"tmp_pct_dt_merge_clip.tif"),
               paste0(res_dir,"moz_lulc2016_20180525.tif")
))
# #############################################################
# ### CLEAN
system(sprintf("rm %s",
               paste0(res_dir,"tmp_*")
))
