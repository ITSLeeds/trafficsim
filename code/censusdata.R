
# Tyne and Wear census data -----------------------------------------------
library(pct)
library(tmap)
tmap_mode("view")

tyneandwear = get_pct_zones("north-east")
tyneandwear = tyneandwear %>% 
  filter(lad_name == "Newcastle upon Tyne" | lad_name == "Sunderland" | 
           lad_name == "Gateshead" | lad_name == "North Tyneside" |  
           lad_name =="South Tyneside")
tm_shape(tyneandwear) + tm_polygons()

lines = get_pct_lines(region = "north-east", purpose = "commute", geography = "msoa")
lines = lines %>% 
  filter(lad_name1 == "Newcastle upon Tyne" | lad_name1 == "Sunderland" | 
           lad_name1 == "Gateshead" | lad_name1 == "North Tyneside" |  
           lad_name1 =="South Tyneside" | lad_name2 == "Newcastle upon Tyne" | 
           lad_name2 == "Sunderland" | lad_name2 == "Gateshead" | 
           lad_name2 == "North Tyneside" |  lad_name2 =="South Tyneside"
         )
tm_shape(lines) + tm_lines()

rnet = get_pct_rnet(region = "north-east", purpose = "commute", geography = "lsoa")
rnet = rnet[tyneandwear, ]
tm_shape(rnet) + tm_lines()

