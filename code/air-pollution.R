library(tidyverse)
library(tmap)
tmap_mode("view")
tmap_options(check.and.fix = TRUE)

# pm10_grouped = readRDS("data/pm10_grouped_2021_1.Rds")
# View(pm10_grouped)
# tm_shape(pm10_grouped) + tm_dots("median_value")


tm_shape(sensor_stats) + tm_dots("median_value")



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


# Get LSOA/MSOA zones and check for zones with both sensor types ----------

pm10 = readRDS("data/pm10_stats_2021_2.Rds")
traffic = readRDS("data/plates_in_stats_2021_2.Rds")

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
tm_shape(join_traffic) + tm_polygons("mean_traffic", alpha = 0.5) +
  tm_shape(traffic) + tm_dots("sum_plates", palette = "-magma") + 
  tm_shape(pm10) + tm_bubbles("median_value")

# join = st_join(northeast_lsoa, pm10) %>% 
#   group_by(geo_code) %>% 
#   summarise(mean_pm10 = mean(median_value)) %>% 
#   filter(!is.na(mean_pm10))
# tm_shape(join) + tm_polygons("mean_pm10")
# join_traffic = st_join(join, traffic) %>% 
#   group_by(geo_code, mean_pm10) %>% 
#   summarise(mean_traffic = mean(sum_plates)) %>% 
#   filter(!is.na(mean_traffic))
# tm_shape(join_traffic) + tm_polygons("mean_pm10")
# tm_shape(join_traffic) + tm_polygons("mean_traffic")

# Get built-up area bounds or calculate population density
