
# Tyne and Wear census data -----------------------------------------------
library(pct)
library(tmap)
library(tidyverse)
library(stplanr)
library(sf)
tmap_mode("view")

northeast = get_pct_zones("north-east", geography = "msoa")
northumberland = get_pct_zones("northumberland", geography = "msoa")
wider_northeast = bind_rows(northeast, northumberland)
wider_northeast = wider_northeast %>% 
  select(geo_code)

tyneandwear = northeast %>% 
  filter(lad_name == "Newcastle upon Tyne" | lad_name == "Sunderland" | 
           lad_name == "Gateshead" | lad_name == "North Tyneside" |  
           lad_name =="South Tyneside")
tm_shape(tyneandwear) + tm_polygons()

# Do either get_pct or get_pct_lines include intrazonal flows?
# should we use get_od?
lines = get_pct(region = "north-east", purpose = "commute", geography = "msoa", layer = "l")
lines_tyneandwear = lines %>% 
  filter(lad_name1 == "Newcastle upon Tyne" | lad_name1 == "Sunderland" | 
           lad_name1 == "Gateshead" | lad_name1 == "North Tyneside" |  
           lad_name1 =="South Tyneside" | lad_name2 == "Newcastle upon Tyne" | 
           lad_name2 == "Sunderland" | lad_name2 == "Gateshead" | 
           lad_name2 == "North Tyneside" |  lad_name2 =="South Tyneside"
         )
tm_shape(lines_tyneandwear) + tm_lines()

lines_matching = lines_tyneandwear %>% 
  filter(geo_code1 %in% wider_northeast$geo_code & geo_code2 %in% wider_northeast$geo_code)

lines_foot = lines_matching %>% 
  filter(foot > 0) %>% 
  # select(-c(car_driver:ebike_sico2), -bicycle) %>% 
  select(geo_code1, geo_code2, foot)

lines_bicycle = lines_matching %>% 
  filter(bicycle > 0) %>% 
  # select(-c(foot:ebike_sico2)) %>% 
  select(geo_code1, geo_code2, bicycle)

lines_car = lines_matching %>% 
  filter(car_driver > 0) %>% 
  # select(-bicycle, -foot, -c(govtarget_slc:ebike_sico2)) %>% 
  select(geo_code1, geo_code2, car_driver)


# Unjittered routes ------------------------------------------------------

# # coords = od_coords(lines_matching)
# # from = coords[, 1:2]
# # to = coords[, 3:4]
# # routes_osrm = route_osrm(from = from, to = to, osrm.profile = "foot") # not working]
# 
# # Only does one route at a time
# # library(osrm)
# # from = as.data.frame(from)
# # to = as.data.frame(to)
# # r_osrm = osrmRoute(src = from, dst = to, osrm.server = "https://routing.openstreetmap.de/", 
# #                    osrm.profile = "foot")
# 
# foot_osrm = route(l = lines_foot, route_fun = route_osrm) # default routing profile is "foot"
# bicycle_osrm = route(l = lines_bicycle, route_fun = route_osrm, osrm.profile = "bike")
# car_osrm = route(l = lines_car, route_fun = route_osrm, osrm.profile = "car")
# 
# saveRDS(foot_osrm, "data/foot_osrm.Rds")
# saveRDS(bicycle_osrm, "data/bicycle_osrm.Rds")
# saveRDS(car_osrm, "data/car_osrm.Rds")
# 
# foot_osrm = readRDS("data/foot_osrm.Rds")
# bicycle_osrm = readRDS("data/bicycle_osrm.Rds")
# car_osrm = readRDS("data/car_osrm.Rds")
# 
# # foot_some = head(foot_osrm)
# tm_shape(foot_osrm) + tm_lines("foot")
# tm_shape(bicycle_osrm) + tm_lines("bicycle")
# tm_shape(car_osrm) + tm_lines("car_driver")


# Jittered routes ---------------------------------------------------------

min_distance_meters = 500
disag_threshold = 50
set.seed(42)

osm_foot = readRDS("data/osm_foot_2022-12-07.Rds")

# Why do we get this error?
# Error in UseMethod("st_write") : 
#   no applicable method for 'st_write' applied to an object of class "NULL"
od_foot_jittered = odjitter::jitter(
  od = lines_foot,
  zones = wider_northeast,
  # zone_name_key = "geo_code",
  subpoints = osm_foot,
  disaggregation_threshold = disag_threshold,
  disaggregation_key = "foot",
  min_distance_meters = min_distance_meters
) 

osm_cycle = readRDS("data/osm_cycle_2022-12-07.Rds")

od_bicycle_jittered = odjitter::jitter(
  od = lines_bicycle,
  zones = wider_northeast,
  # zone_name_key = "geo_code",
  subpoints = osm_cycle,
  disaggregation_threshold = disag_threshold,
  disaggregation_key = "bicycle",
  min_distance_meters = min_distance_meters
) 

osm_drive = readRDS("data/osm_drive_2022-12-07.Rds")

od_car_jittered = odjitter::jitter(
  od = lines_car,
  zones = wider_northeast,
  zone_name_key = "geo_code",
  subpoints = osm_drive,
  disaggregation_threshold = disag_threshold,
  disaggregation_key = "car_driver",
  min_distance_meters = min_distance_meters
) 

saveRDS(od_foot_jittered, "data/od_foot_jittered.Rds")
saveRDS(od_bicycle_jittered, "data/od_bicycle_jittered.Rds")
saveRDS(od_car_jittered, "data/od_car_jittered.Rds")

foot_osrm = route(l = od_foot_jittered, route_fun = route_osrm) # default routing profile is "foot"
bicycle_osrm = route(l = od_bicycle_jittered, route_fun = route_osrm, osrm.profile = "bike")
car_osrm = route(l = od_car_jittered, route_fun = route_osrm, osrm.profile = "car")

saveRDS(foot_osrm, "data/foot_jittered_osrm.Rds")
saveRDS(bicycle_osrm, "data/bicycle_jittered_osrm.Rds")
saveRDS(car_osrm, "data/car_jittered_osrm.Rds")

foot_osrm = readRDS("data/foot_jittered_osrm.Rds")
bicycle_osrm = readRDS("data/bicycle_jittered_osrm.Rds")
car_osrm = readRDS("data/car_jittered_osrm.Rds")

tm_shape(foot_osrm) + tm_lines("foot")
tm_shape(bicycle_osrm) + tm_lines("bicycle")
tm_shape(car_osrm) + tm_lines("car_driver")


# Route networks ----------------------------------------------------------
# car_line = st_cast(car_osrm$geometry, "LINESTRING")
# car_osrm$geometry = car_line

foot_rnet = overline(foot_osrm, attrib = "foot", regionalise = 1e+07)
bicycle_rnet = overline(bicycle_osrm, attrib = "bicycle", regionalise = 1e+07)
car_rnet = overline(
  car_osrm, 
  # attrib = c("car_driver", "car_passenger", "motorbike", "taxi_other")
  attrib = "car_driver",
  regionalise = 1e+07
  )

saveRDS(foot_rnet, "data/foot_rnet_jittered.Rds")
saveRDS(bicycle_rnet, "data/bicycle_rnet_jittered.Rds")
saveRDS(car_rnet, "data/car_rnet_jittered.Rds")

foot_rnet = readRDS("data/foot_rnet_jittered.Rds")
bicycle_rnet = readRDS("data/bicycle_rnet_jittered.Rds")
car_rnet = readRDS("data/car_rnet_jittered.Rds")

tm_shape(foot_rnet) + tm_lines("foot")
tm_shape(bicycle_rnet) + tm_lines("bicycle")
tm_shape(car_rnet) + tm_lines("car_driver")

# rnet = get_pct_rnet(region = "north-east", purpose = "commute", geography = "lsoa")
# rnet = rnet[tyneandwear, ]
# tm_shape(rnet) + tm_lines("bicycle")

# For testing:
# library(odjitter)
# od = readr::read_csv("https://github.com/dabreegster/odjitter/raw/main/data/od.csv")
# zones = sf::read_sf("https://github.com/dabreegster/odjitter/raw/main/data/zones.geojson")
# road_network = sf::read_sf("https://github.com/dabreegster/odjitter/raw/main/data/road_network.geojson")
# od_jittered = jitter(od, zones, subpoints = road_network)
# od_jittered = jitter(od, zones, subpoints = road_network, show_command = TRUE)
# od_jittered = jitter(
#   od,
#   zones,
#   subpoints = road_network,
#   disaggregation_threshold = 50
# )


# Validation --------------------------------------------------------------

car_count_2021 = read_csv("data/2021-1-Car Count.csv")
car_count_2021 = st_as_sf(car_count_2021, wkt = "Location (WKT)")
st_crs(car_count_2021) = 4326

car_sum = car_count_2021 %>% 
  group_by(`Sensor Name`) %>% 
  summarise(cars = sum(Value), 
            n = n(),
            mean_cars = mean(Value)
            )
tm_shape(car_sum) + tm_dots("mean_cars")

tm_shape(car_rnet) + tm_lines("car_driver") + 
  tm_shape(car_sum) + tm_dots("cars")

speed_mean = average_speed_2021 %>% 
  group_by(`Sensor Name`) %>% 
  summarise(n = n(),
            mean_speed = mean(Value)
  )

tm_shape(speed_mean) + tm_dots("mean_speed")

congestion_mean = congestion_2021 %>% 
  group_by(`Sensor Name`) %>% 
  summarise(n = n(),
            mean_congestion = mean(Value)
  )

tm_shape(congestion_mean) + tm_dots("mean_congestion")

rnet_refs = st_nearest_feature(x = car_sum, y = car_rnet)
rnet_feats = car_rnet[rnet_refs, ]

tm_shape(rnet_feats) + tm_lines("car_driver", lwd = 3) +
  tm_shape(car_sum) + tm_dots("mean_cars")
