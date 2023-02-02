
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
# tm_shape(tyneandwear) + tm_polygons()

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
# tm_shape(lines_tyneandwear) + tm_lines()

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


# Jittered OD pairs ------------------------------------------------------

min_distance_meters = 500
disag_threshold = 50
set.seed(42)

osm_foot = readRDS("data/osm_foot_2023-01-11.Rds")

# Previous error when subpoints were incorrect:
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

osm_cycle = readRDS("data/osm_cycle_2023-01-11.Rds")

od_bicycle_jittered = odjitter::jitter(
  od = lines_bicycle,
  zones = wider_northeast,
  # zone_name_key = "geo_code",
  subpoints = osm_cycle,
  disaggregation_threshold = disag_threshold,
  disaggregation_key = "bicycle",
  min_distance_meters = min_distance_meters
) 

osm_drive = readRDS("data/osm_drive_2023-01-11.Rds")

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


# Routing the jittered OD with OSRM (plan to use OTP instead) --------------

# foot_osrm = route(l = od_foot_jittered, route_fun = route_osrm) # default routing profile is "foot"
# bicycle_osrm = route(l = od_bicycle_jittered, route_fun = route_osrm, osrm.profile = "bike")
# car_osrm = route(l = od_car_jittered, route_fun = route_osrm, osrm.profile = "car")
# 
# saveRDS(foot_osrm, "data/foot_jittered_osrm.Rds")
# saveRDS(bicycle_osrm, "data/bicycle_jittered_osrm.Rds")
# saveRDS(car_osrm, "data/car_jittered_osrm.Rds")
# 
# foot_osrm = readRDS("data/foot_jittered_osrm.Rds")
# bicycle_osrm = readRDS("data/bicycle_jittered_osrm.Rds")
# car_osrm = readRDS("data/car_jittered_osrm.Rds")
# 
# tm_shape(foot_osrm) + tm_lines("foot")
# tm_shape(bicycle_osrm) + tm_lines("bicycle")
# tm_shape(car_osrm) + tm_lines("car_driver")


# Route networks ----------------------------------------------------------
# car_line = st_cast(car_osrm$geometry, "LINESTRING")
# car_osrm$geometry = car_line

routes_car_otp = readRDS("data/routes_car_otp_3_counties.Rds")

foot_rnet = overline(foot_osrm, attrib = "foot", regionalise = 1e+07)
bicycle_rnet = overline(bicycle_osrm, attrib = "bicycle", regionalise = 1e+07)
car_rnet = overline(
  routes_car_otp, 
  # attrib = c("car_driver", "car_passenger", "motorbike", "taxi_other")
  attrib = "car_driver",
  regionalise = 1e+07
  )

car_rnet = tibble::rowid_to_column(car_rnet, "ID")

saveRDS(foot_rnet, "data/foot_rnet_jittered.Rds")
saveRDS(bicycle_rnet, "data/bicycle_rnet_jittered.Rds")
saveRDS(car_rnet, "data/car_rnet_jittered.Rds")

foot_rnet = readRDS("data/foot_rnet_jittered.Rds")
bicycle_rnet = readRDS("data/bicycle_rnet_jittered.Rds")
car_rnet = readRDS("data/car_rnet_jittered.Rds")

tm_shape(foot_rnet) + tm_lines("foot")
tm_shape(bicycle_rnet) + tm_lines("bicycle")
tm_shape(car_rnet) + 
  tm_lines("car_driver", 
           breaks = c(0, 500, 1000, 2000, 5000, 15000))

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


# UO coordinates ----------------------------------------------------------

# Need to find out whether some sensor locations are double-counted

# Plates In
plates_in_2021 = read_csv("data/2021-1-Plates In.csv")

# Remove bus sensors and test/dummy sensors
plates_in_2021 = plates_in_2021 %>% 
  filter(str_detect(pattern = "BUS", `Sensor Name`) == FALSE) %>% 
  filter(str_detect(pattern = "DUMMY", `Sensor Name`) == FALSE) %>% 
  filter(str_detect(pattern = "TEST", `Sensor Name`) == FALSE)

plates_in_2021 = plates_in_2021 %>% 
  mutate(coords = sub(pattern = ",.*", replacement = "", `Location (WKT)`),
         coords = sub(pattern = ".*\\(", replacement = "", coords))
plates_in_2021 = plates_in_2021 %>% 
  mutate(long = sub(pattern = " .*", replacement = "", coords),
         lat = sub(pattern = ".* ", replacement = "", coords),
         day = as.Date(Timestamp))
)
plates_in_2021 = st_as_sf(plates_in_2021, coords = c("long", "lat"))
st_crs(plates_in_2021) = 4326

saveRDS(plates_in_2021, "data/plates-in-2021-1.Rds")

# needs calibrating to avoid outlying high values due to parked cars
in_sum = plates_in_2021 %>% 
  st_drop_geometry() %>% 
  group_by(`Sensor Name`) %>% 
  summarise(cars = sum(Value), 
            n = n(),
            mean_cars = mean(Value)
  )

saveRDS(in_sum, "data/in_sum.Rds")
tm_shape(in_sum) + tm_dots("cars")

# Plates Out
plates_out_2021 = read_csv("data/2021-1-Plates Out.csv")

# Remove bus sensors and test/dummy sensors
plates_out_2021 = plates_out_2021 %>% 
  filter(str_detect(pattern = "BUS", `Sensor Name`) == FALSE) %>% 
  filter(str_detect(pattern = "DUMMY", `Sensor Name`) == FALSE) %>% 
  filter(str_detect(pattern = "TEST", `Sensor Name`) == FALSE)

plates_out_2021 = plates_out_2021 %>% 
  mutate(coords = sub(pattern = ".*, ", replacement = "", `Location (WKT)`),
         coords = sub(pattern = "\\).*", replacement = "", coords))
plates_out_2021 = plates_out_2021 %>% 
  mutate(long = sub(pattern = " .*", replacement = "", coords),
         lat = sub(pattern = ".* ", replacement = "", coords),
         day = as.Date(Timestamp))
)
plates_out_2021 = st_as_sf(plates_out_2021, coords = c("long", "lat"))
st_crs(plates_out_2021) = 4326

saveRDS(plates_out_2021, "data/plates-out-2021-1.Rds")

# needs calibrating to avoid outlying high values due to parked cars
out_sum = plates_out_2021 %>% 
  st_drop_geometry() %>% 
  group_by(`Sensor Name`) %>% 
  summarise(cars = sum(Value), 
            n = n(),
            mean_cars = mean(Value)
  )

saveRDS(out_sum, "data/out_sum.Rds")
tm_shape(out_sum) + tm_dots("cars")


# Read in 
plates_in_2021 = readRDS("data/plates-in-2021-1.Rds")
plates_out_2021 = readRDS("data/plates-out-2021-1.Rds")
in_sum = readRDS("data/in_sum.Rds")
out_sum = readRDS("data/out_sum.Rds")

# these are in the same location but have different car counts:
per = plates_in_2021 %>% 
  filter(`Sensor Name` == "PER_NE_CAJT_GHA167_DR3_DR2A" | `Sensor Name` == "PER_NE_CAJT_GHA167_DR3_DR2")
# opposite side of the road
per2 = plates_in_2021 %>% 
  filter(`Sensor Name` == "PER_NE_CAJT_GHA167_DR3_NB4")

per1 = plates_in_2021 %>% 
  filter(`Sensor Name` == "PER_NE_CAJT_GHA167_DR3_DR2")
sum(per1$Value)
# [1] 33097
in_sum = plates_in_2021 %>% 
  group_by(`Sensor Name`) %>% 
  summarise(cars = sum(Value), 
            n = n(),
            mean_cars = mean(Value)
  )
i1 = in_sum %>% 
  filter(`Sensor Name` == "PER_NE_CAJT_GHA167_DR3_DR2")
sum(i1$cars)
# [1] 33097


# Time plots --------------------------------------------------------------

ggplot(per1, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  geom_point() +
  labs(y = "PER_NE_CAJT_GHA167_DR3_DR2")

per1_daily = per1 %>% 
  st_drop_geometry() %>% 
  group_by(day) %>% 
  summarise(cars = sum(Value))


# Validation --------------------------------------------------------------


tm_shape(car_rnet) + 
  tm_lines("car_driver", 
           breaks = c(0, 500, 1000, 2000, 5000, 15000)) + 
  tm_shape(in_sum) + tm_dots("cars")

tm_shape(car_2013_sum) + tm_dots() +
  tm_shape(car_rnet) + tm_lines("car_driver")

# # Speed and flow (small area only)
# speed_mean = average_speed_2021 %>% 
#   group_by(`Sensor Name`) %>% 
#   summarise(n = n(),
#             mean_speed = mean(Value)
#   )
# tm_shape(speed_mean) + tm_dots("mean_speed")
# 
# congestion_mean = congestion_2021 %>% 
#   group_by(`Sensor Name`) %>% 
#   summarise(n = n(),
#             mean_congestion = mean(Value)
#   )
# tm_shape(congestion_mean) + tm_dots("mean_congestion")

# Join rnet with UO counts
rnet_refs = st_nearest_feature(x = in_sum, y = car_rnet)
rnet_feats = car_rnet[rnet_refs, ]
rnet_joined = cbind(rnet_feats, in_sum)

tm_shape(rnet_feats) + tm_lines("car_driver", lwd = 3) +
  tm_shape(in_sum) + tm_dots("cars")

m1 = lm(cars ~ car_driver, data = rnet_joined)
summary(m1)$r.squared
# [1] 0.05131899 # car count mean
# [1] 0.2331099 # plates in mean
# [1] 0.2368261 # plates in sum

ggplot(rnet_joined, aes(car_driver, cars)) + 
  geom_point() + 
  labs(y = "Sum 'Plates In' Jan 2021", x = "2011 Census car driver commute trips")

# Join rnet with UO counts
rnet_refs = st_nearest_feature(x = car_2013_sum, y = car_rnet)
rnet_feats = car_rnet[rnet_refs, ]
rnet_joined = cbind(rnet_feats, car_2013_sum)

tm_shape(rnet_feats) + tm_lines("car_driver", lwd = 3) +
  tm_shape(car_2013_sum) + tm_dots("mean_cars")

m1 = lm(mean_cars ~ car_driver, data = rnet_joined)
summary(m1)$r.squared
# [1] 0.008347389

ggplot(rnet_joined, aes(car_driver, mean_cars)) + 
  geom_point() + 
  labs(y = "Mean cars in UO images 2013", x = "2011 Census car driver commute trips")
