
# Tyne and Wear census data -----------------------------------------------
library(pct)
library(tmap)
library(tidyverse)
tmap_mode("view")

northeast = get_pct_zones("north-east")
tyneandwear = northeast %>% 
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


# Unjittered routes ------------------------------------------------------

library(stplanr)
# coords = od_coords(lines)
# from = coords[, 1:2]
# to = coords[, 3:4]
# routes_osrm = route_osrm(from = from, to = to, osrm.profile = "foot") # not working]

# Only does one route at a time
# library(osrm)
# from = as.data.frame(from)
# to = as.data.frame(to)
# r_osrm = osrmRoute(src = from, dst = to, osrm.server = "https://routing.openstreetmap.de/", 
#                    osrm.profile = "foot")

foot_osrm = route(l = lines_foot, route_fun = route_osrm) # default routing profile is "foot"
bicycle_osrm = route(l = lines_bicycle, route_fun = route_osrm, osrm.profile = "bike")
car_osrm = route(l = lines_car, route_fun = route_osrm, osrm.profile = "car")

saveRDS(foot_osrm, "data/foot_osrm.Rds")
saveRDS(bicycle_osrm, "data/bicycle_osrm.Rds")
saveRDS(car_osrm, "data/car_osrm.Rds")

foot_osrm = readRDS("data/foot_osrm.Rds")
bicycle_osrm = readRDS("data/bicycle_osrm.Rds")
car_osrm = readRDS("data/car_osrm.Rds")

# foot_some = head(foot_osrm)
tm_shape(foot_osrm) + tm_lines("foot")
tm_shape(bicycle_osrm) + tm_lines("bicycle")
tm_shape(car_osrm) + tm_lines("car_driver")


# Jittered routes ---------------------------------------------------------

min_distance_meters = 500
disag_threshold = 50

osm_cycle = readRDS("data/osm_cycle_2022-12-07.Rds")

od_bicycle_jittered = odjitter::jitter(
  od = lines_bicycle,
  zones = northeast,
  zone_name_key = "geo_code",
  subpoints = osm_cycle,
  disaggregation_threshold = disag_threshold,
  disaggregation_key = "bicycle",
  min_distance_meters = min_distance_meters
) 

osm_drive = readRDS("data/osm_drive_2022-12-07.Rds")

od_car_jittered = odjitter::jitter(
  od = lines_car,
  zones = northeast,
  zone_name_key = "geo_code",
  disaggregation_threshold = disag_threshold,
  disaggregation_key = "car_driver",
  min_distance_meters = min_distance_meters
) 


# Route networks ----------------------------------------------------------

foot_rnet = overline(foot_osrm, attrib = "foot")
bicycle_rnet = overline(bicycle_osrm, attrib = "bicycle") # error
# 2022-12-07 11:35:36 constructing segments
# 2022-12-07 11:35:39 building geometry
# |++++++++++++++++++++++++++++++++++++++++++++++++++| 100% elapsed=01s  
# 2022-12-07 11:35:41 simplifying geometry
# large data detected, using regionalisation, nrow = 106771
# Error in FUN(X[[i]], ...) : subscript out of bounds
car_rnet = overline(car_osrm, 
                    attrib = c("car_driver", "car_passenger", "motorbike", "taxi_other")
                    )

saveRDS(foot_rnet, "data/foot_rnet.Rds")
saveRDS(bicycle_rnet, "data/bicycle_rnet.Rds")
saveRDS(car_rnet, "data/car_rnet.Rds")

foot_rnet = readRDS("data/foot_rnet.Rds")
bicycle_rnet = readRDS("data/bicycle_rnet.Rds")
car_rnet = readRDS("data/car_rnet.Rds")

tm_shape(foot_rnet) + tm_lines("foot")
tm_shape(bicycle_rnet) + tm_lines("bicycle")
tm_shape(car_rnet) + tm_lines("car_driver")

# rnet = get_pct_rnet(region = "north-east", purpose = "commute", geography = "lsoa")
# rnet = rnet[tyneandwear, ]
# tm_shape(rnet) + tm_lines("bicycle")

