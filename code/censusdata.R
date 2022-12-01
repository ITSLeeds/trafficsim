
# Tyne and Wear census data -----------------------------------------------
library(pct)
library(tmap)
library(tidyverse)
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

lines_foot = lines %>% 
  filter(foot > 0) %>% 
  select(-c(car_driver:ebike_sico2), -bicycle)

lines_bicycle = lines %>% 
  filter(bicycle > 0) %>% 
  select(-c(foot:ebike_sico2))

lines_car = lines %>% 
  filter(car_driver > 0) %>% 
  select(-bicycle, -foot, -c(govtarget_slc:ebike_sico2))

library(stplanr)
# coords = od_coords(lines)
# from = coords[, 1:2]
# to = coords[, 3:4]
# routes_osrm = route_osrm(from = from, to = to, osrm.profile = "foot") # not working
# lines_some = head(lines)
foot_osrm = route(l = lines_foot, route_fun = route_osrm) # default routing profile is "foot"
bicycle_osrm = route(l = lines_bicycle, route_fun = route_osrm(osrm.profile = "bike"))
car_osrm = route(l = lines_car, route_fun = route_osrm(osrm.profile = "car"))

# foot_some = slice_sample(foot_osrm, n = 0.01)
tm_shape(foot_osrm) + tm_lines("foot")
tm_shape(bicycle_osrm) + tm_lines("bicycle")
tm_shape(car_osrm) + tm_lines("car")

# Only does one route at a time
# library(osrm)
# from = as.data.frame(from)
# to = as.data.frame(to)
# r_osrm = osrmRoute(src = from, dst = to, osrm.server = "https://routing.openstreetmap.de/", 
#                    osrm.profile = "foot")

rnet = get_pct_rnet(region = "north-east", purpose = "commute", geography = "lsoa")
rnet = rnet[tyneandwear, ]
tm_shape(rnet) + tm_lines("bicycle")



# l1 = od_data_lines[49, ]
# l1m = od_coords(l1)
# from = l1m[, 1:2]
# to = l1m[, 3:4]
# if(curl::has_internet()) {
# r_foot = route_osrm(from, to)
# r_bike = route_osrm(from, to, osrm.profile = "bike")
# r_car = route_osrm(from, to, osrm.profile = "car")
# plot(r_foot$geometry, lwd = 9, col = "grey")
# plot(r_bike, col = "blue", add = TRUE)
# plot(r_car, col = "red", add = TRUE)
# }