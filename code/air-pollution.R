library(tidyverse)
library(tmap)
tmap_mode("view")

pm10 = readRDS("data/pm10_stats_2021_2.Rds")
traffic = readRDS("data/plates_in_stats_2021_2.Rds")


# Checking extreme values -------------------------------------------------

per = sensor_sd %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1913150")

ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  geom_point()

per = sensor_sd %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1976150")

ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  geom_point()

per = sensor_sd %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1762150")

ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  geom_point()

# OSM data ----------------------------------------------------------------

# Check the number of lanes, road names, road refs, speed limits, etc
# Use number of lanes to improve the correlation with 2011 Census data?
# Need to consider whether road is dual carriageway and whether it has bus lanes, 
# and how many lanes the camera covers

osm = readRDS("data/osm_drive_2023-01-17.Rds")

traffic_osm = st_join(traffic, osm)

nearest = st_nearest_feature(traffic, osm)
nn = osm[nearest,] %>% 
  st_drop_geometry()
traffic_osm = bind_cols(traffic, nn)

tm_shape(traffic_osm) + tm_dots("lanes")


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

# Count number of LSOAs/MSOAs that contain both sensor types
join = st_join(northeast, pm10) %>% 
  group_by(geo_code) %>% 
  summarise(mean_pm10 = mean(median_value)) %>% 
  filter(!is.na(mean_pm10))
tm_shape(join) + tm_polygons("mean_pm10")
join_traffic = st_join(join, traffic) %>% 
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
# [1] 0.05653983


# Same with LSOAs ---------------------------------------------------------

# only 14 LSOAs match both datasets

join_lsoa = st_join(northeast_lsoa, pm10) %>%
  group_by(geo_code) %>%
  summarise(mean_pm10 = mean(median_value)) %>%
  filter(!is.na(mean_pm10))
tm_shape(join_lsoa) + tm_polygons("mean_pm10")
join_lsoa_traffic = st_join(join_lsoa, traffic) %>%
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


