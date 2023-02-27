library(tidyverse)
library(tmap)
tmap_mode("view")
library(sf)

pm10 = readRDS("data/pm10_stats_2021_2.Rds")
traffic = readRDS("data/plates_in_stats_2021_2.Rds")
pm10_records = readRDS("data/pm10_2021_2.Rds")

traffic = traffic %>% 
  mutate(`Sum plates` = sum_plates)

# OSM data ----------------------------------------------------------------

# Check the number of lanes, road names, road refs, speed limits, etc
# Use number of lanes to improve the correlation with 2011 Census data?
# Need to consider whether road is dual carriageway and whether it has bus lanes, 
# and how many lanes the camera covers

osm = readRDS("data/osm_drive_2023-01-17.Rds")

# Prevent false matches with minor roads
osm_nores = osm %>% 
  filter(
    !highway == "service",
    !highway == "unclassified",
    !highway == "residential"
    )
osm_nounc = osm %>% 
  filter(
    !highway == "service",
    !highway == "unclassified"
  )


# Join OSM with plates in
nearest = st_nearest_feature(traffic, osm_nores)
nn = osm_nores[nearest,] %>% 
  st_drop_geometry()
traffic_osm = bind_cols(traffic, nn)

tm_shape(traffic_osm) + tm_dots("highway")

# Join OSM with PM10
nearest = st_nearest_feature(pm10, osm_nounc)
np = osm_nounc[nearest,] %>% 
  st_drop_geometry()
pm10_osm = bind_cols(pm10, np)
tm_shape(pm10_osm) + tm_dots("highway")

# Checking extreme values -------------------------------------------------

per = pm10_records %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1913150")

ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  geom_point()

per = pm10_records %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1976150")

ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  geom_point()

per = pm10_records %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1762150")

ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  geom_point()

#############################

per = traffic_osm %>% 
  filter(`Sensor Name` == "PER_NE_CAJT_GHA167_DR3_DR2A")

per = traffic_osm %>% 
  filter(`Sensor Name` == "PER_NE_CAJT_NTA1058_CR4_SR3")

per = traffic_osm %>% 
  filter(`Sensor Name` == "PER_NE_CAJT_NCA189_SL6_JDR4")


# Now check the number of lanes

# Get LSOA/MSOA zones and check for zones with both sensor types ----------

library(pct)
northeast = get_pct_zones("north-east", geography = "msoa")
newc_msoa = northeast %>% 
  filter(lad_name == "Newcastle upon Tyne")
tm_shape(newc_msoa) + tm_polygons() + 
  tm_shape(pm10) + tm_dots()

northeast_lsoa = get_pct_zones("north-east", geography = "lsoa")
northeast_lsoa = st_make_valid(northeast_lsoa)
tm_shape(northeast_lsoa) + tm_polygons()

pop = read_csv("data/popn-2020.csv")
pop = pop %>% 
  rename(population = `All Ages`)
msoa_pop = inner_join(northeast, pop, by = c("geo_code" = "MSOA Code"))
msoa_pop = msoa_pop %>% 
  mutate(area = units::drop_units(st_area(msoa_pop)/1000000),
         `Pop density` = population/area)

# Find MSOAs that contain both sensor types
join = st_join(msoa_pop, pm10_osm) %>% 
  group_by(geo_code, population, area, `Pop density`) %>% 
  summarise(mean_pm10 = mean(median_value)) %>% 
  filter(!is.na(mean_pm10))
tm_shape(join) + tm_polygons("pop_density")
join_traffic = st_join(join, traffic_osm) %>% 
  group_by(geo_code, mean_pm10, `Pop density`) %>% 
  summarise(mean_traffic = mean(sum_plates)) %>% 
  filter(!is.na(mean_traffic))
tm_shape(join_traffic) + tm_polygons("mean_pm10") + 
  tm_shape(pm10) + tm_dots("median_value")
tm_shape(join_traffic) + tm_polygons("Pop density", alpha = 0.5) +
  tm_shape(traffic) + tm_dots("Sum plates", palette = "-magma") + 
  tm_shape(pm10) + tm_bubbles("median_value")

ggplot(join_traffic, aes(mean_traffic, mean_pm10)) + 
  geom_point()
m1 = lm(mean_pm10 ~ mean_traffic, data = join_traffic)
summary(m1)$r.squared
# [1] 0.05653983
m2 = lm(mean_pm10 ~ mean_traffic + `Pop density`, data = join_traffic)
summary(m2)$r.squared
summary(m2)
# [1] 0.05794636

# Same with LSOAs ---------------------------------------------------------

# only 14 LSOAs match both datasets

join_lsoa = st_join(northeast_lsoa, pm10_osm) %>%
  group_by(geo_code) %>%
  summarise(mean_pm10 = mean(median_value)) %>%
  filter(!is.na(mean_pm10))
tm_shape(join_lsoa) + tm_polygons("mean_pm10")
join_lsoa_traffic = st_join(join_lsoa, traffic_osm) %>%
  group_by(geo_code, mean_pm10) %>%
  summarise(mean_traffic = mean(sum_plates)) %>%
  filter(!is.na(mean_traffic))
tm_shape(join_lsoa_traffic) + tm_polygons("mean_pm10")
tm_shape(join_lsoa_traffic) + tm_polygons("mean_traffic")

ggplot(join_lsoa_traffic, aes(mean_traffic, mean_pm10)) + 
  geom_point()
m1 = lm(mean_pm10 ~ mean_traffic, data = join_lsoa_traffic)
summary(m1)$r.squared
# [1] 0.02452623

# Get built-up area bounds or calculate population density


# Sensors on same road ----------------------------------------------------

traffic_ref_mean = traffic_osm %>% 
  st_drop_geometry() %>% 
  group_by(ref) %>% 
  summarise(mean_traffic = mean(sum_plates)) %>% 
  filter(! is.na(ref))
pm10_ref_mean = pm10_osm %>% 
  st_drop_geometry() %>% 
  group_by(ref) %>% 
  summarise(mean_pm10 = mean(median_value)) %>% 
  filter(! is.na(ref))
by_ref = inner_join(pm10_ref_mean, traffic_ref_mean, by = "ref")

ggplot(by_ref, aes(mean_traffic, mean_pm10)) + 
  geom_point()
m1 = lm(mean_pm10 ~ mean_traffic, data = by_ref)
summary(m1)$r.squared
# [1] 0.1020857

pm10_missing = pm10_osm %>%
  filter(!ref %in% by_ref$ref)

# traffic_name_mean = traffic_osm %>% 
#   st_drop_geometry() %>% 
#   group_by(name) %>% 
#   summarise(mean_traffic = mean(sum_plates)) %>% 
#   filter(! is.na(name))
# by_name = inner_join(pm10_missing, traffic_name_mean, by = "name")
# by_ref_name = bind_rows(by_ref, by_name)
# 
# ggplot(by_ref_name, aes(mean_traffic, median_value)) + 
#   geom_point()
# m1 = lm(median_value ~ mean_traffic, data = by_ref_name)
# summary(m1)$r.squared
# # [1] 0.0388554

# Both MSOA and road ref
join = st_join(northeast, pm10_missing) %>% 
  group_by(geo_code) %>% 
  summarise(mean_pm10 = mean(median_value)) %>% 
  filter(!is.na(mean_pm10))
tm_shape(join) + tm_polygons("mean_pm10")
join_traffic = st_join(join, traffic_osm) %>% 
  group_by(geo_code, mean_pm10) %>% 
  summarise(mean_traffic = mean(sum_plates)) %>% 
  filter(!is.na(mean_traffic))
tm_shape(join_traffic) + tm_polygons("mean_pm10") + 
  tm_shape(pm10) + tm_dots("median_value")
tm_shape(join_traffic) + tm_polygons("mean_pm10", alpha = 0.5) +
  tm_shape(traffic) + tm_dots("sum_plates", palette = "-magma") + 
  tm_shape(pm10) + tm_bubbles("median_value")

ggplot(join_traffic, aes(mean_traffic, mean_pm10)) + 
  geom_point()
m1 = lm(mean_pm10 ~ mean_traffic, data = join_traffic)
summary(m1)$r.squared
# [1] 0.1479101


# Sensors on same road type -----------------------------------------------

traffic_highway_mean = traffic_osm %>% 
  st_drop_geometry() %>% 
  group_by(highway) %>% 
  summarise(mean_traffic = mean(sum_plates)) %>% 
  filter(! is.na(highway))
pm10_highway_mean = pm10_osm %>% 
  st_drop_geometry() %>% 
  group_by(highway) %>% 
  summarise(mean_pm10 = mean(median_value)) %>% 
  filter(! is.na(highway))
by_highway = inner_join(pm10_highway_mean, traffic_highway_mean, by = "highway")

ggplot(by_highway, aes(mean_traffic, mean_pm10)) + 
  geom_point()
m1 = lm(mean_pm10 ~ mean_traffic, data = by_highway)
summary(m1)$r.squared
# [1] 0.07241296
