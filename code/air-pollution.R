library(tidyverse)
library(tmap)
tmap_mode("view")
library(sf)

pm10 = readRDS("data/pm10_stats_2021_2.Rds")
traffic = readRDS("data/plates_in_stats_2021_2.Rds")
pm10_records = readRDS("data/pm10_2021_2.Rds")

traffic = traffic %>% 
  mutate(`Sum plates` = sum_value)


# Get median daily traffic for the month ----------------------------------

# Sum traffic each day
traffic_detailed = readRDS("data/plates_in_2021_2.Rds")

traffic_daily = traffic_detailed %>% 
  st_drop_geometry() %>% 
  group_by(`Sensor Name`, day) %>% 
  summarise(
    daily_plates = sum(Value),
    count = n(),
    max_plates = max(Value)
  )
# Exclude time periods with less than 10 readings 
# or with a reading greater than 6 standard deviations higher than the mean reading
# time_corrected = time_group %>% 
#   filter(
#     ! max_plates > (mean_reading + 6 * sd_reading),
#     ! count < 10
#   )
# Median of these daily sums
monthly_median = traffic_daily %>% 
  group_by(`Sensor Name`) %>% 
  summarise(median_traffic = median(daily_plates))

sensor_locations = traffic_detailed %>% 
  select(`Sensor Name`) %>% 
  group_by(`Sensor Name`) %>% 
  filter(row_number() == 1)
traffic_median = left_join(monthly_median, sensor_locations, by = "Sensor Name")
traffic_median = st_as_sf(traffic_median)
st_crs(traffic_median) = 4326



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
nearest = st_nearest_feature(traffic_median, osm_nores)
nn = osm_nores[nearest,] %>% 
  st_drop_geometry()
traffic_osm = bind_cols(traffic_median, nn)

tm_shape(traffic_osm) + tm_dots("highway")

# Join OSM with PM10
nearest = st_nearest_feature(pm10, osm_nounc)
np = osm_nounc[nearest,] %>% 
  st_drop_geometry()
pm10_osm = bind_cols(pm10, np)
tm_shape(pm10_osm) + tm_dots("highway")


# Checking extreme values -------------------------------------------------

# Figure 4
per = pm10_records %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1913150")

ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  labs(y = "PM10", x = "")

per = pm10_records %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1976150")

ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  geom_point()

per = pm10_records %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1762150")

# Figure 4
ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  labs(y = "PM10", x = "")

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

# Population density
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

m1 = lm(mean_pm10 ~ `Pop density`, data = join)
summary(m1)$r.squared
ggplot(join, aes(mean_pm10, `Pop density`)) + 
  geom_point()

join_traffic = st_join(join, traffic_median) %>% 
  group_by(geo_code, mean_pm10, `Pop density`) %>% 
  summarise(mean_traffic = mean(median_traffic)) %>% 
  filter(!is.na(mean_traffic))
tm_shape(join_traffic) + tm_polygons("mean_pm10") + 
  tm_shape(pm10) + tm_dots("median_value")

# Figure 5
traffic_fig = traffic_median %>% 
  rename(`Median daily traffic` = median_traffic)
tm_shape(join_traffic) + tm_polygons("Pop density", alpha = 0.5) +
  tm_shape(traffic_fig) + tm_dots("Median daily traffic", palette = "-magma") + 
  tm_shape(pm10) + tm_bubbles("median_value")

ggplot(join_traffic, aes(mean_traffic, mean_pm10)) + 
  geom_point()
m1 = lm(mean_pm10 ~ mean_traffic, data = join_traffic)
summary(m1)$r.squared
# [1] 0.05554601
m2 = lm(mean_pm10 ~ mean_traffic + `Pop density`, data = join_traffic)
summary(m2)$r.squared
summary(m2)
# [1] 0.05794636


# Sensors on same road ----------------------------------------------------

traffic_ref_mean = traffic_osm %>% 
  st_drop_geometry() %>% 
  group_by(ref) %>% 
  summarise(mean_traffic = mean(median_traffic)) %>% 
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
# [1] 0.09644407

# pm10_missing = pm10_osm %>%
#   filter(!ref %in% by_ref$ref)

