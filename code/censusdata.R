
# Tyne and Wear census data -----------------------------------------------
library(pct)
library(tmap)
library(tidyverse)
library(stplanr)
library(sf)
library(lubridate)
tmap_mode("view")

northeast = get_pct_zones("north-east", geography = "msoa")
northumberland = get_pct_zones("northumberland", geography = "msoa")
wider_northeast = bind_rows(northeast, northumberland)
wider_northeast = wider_northeast %>% 
  select(geo_code)

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

# changed to get all vehicles not just car drivers
lines_drive = lines_matching %>% 
  filter(car_driver > 0 | taxi_other > 0 | motorbike > 0) %>% # excludes buses
  select(geo_code1, geo_code2, car_driver, taxi_other, motorbike) %>% 
  mutate(all_vehs = car_driver + taxi_other + motorbike)

# Jittered OD pairs ------------------------------------------------------

min_distance_meters = 500
disag_threshold = 50
set.seed(42)

# why does this give more routing errors than using "data/osm_drive_2023-01-17.Rds"?
osm_drive = osmextract::oe_read("OTP/graphs/tyne-and-wear/north-east.osm.pbf")

od_drive_jittered = odjitter::jitter(
  od = lines_drive,
  zones = wider_northeast,
  zone_name_key = "geo_code",
  subpoints = osm_drive,
  disaggregation_threshold = disag_threshold,
  disaggregation_key = "all_vehs",
  min_distance_meters = min_distance_meters
) 

saveRDS(od_drive_jittered, "data/od_drive_jittered.Rds")

# Figure 1
od_jit = readRDS("data/od_drive_jittered.Rds")
od_jit = od_jit %>% 
  arrange(-all_vehs) %>% 
  slice_head(n = 1000) %>% 
  arrange(all_vehs) %>% 
  rename(`Jittered trips` = all_vehs)
tm_shape(od_jit) + tm_lines("Jittered trips")

# Now do the routing in OTP using code/otp.R


# Route networks ----------------------------------------------------------

routes_drive_otp = readRDS("data/routes_drive_otp_3_counties.Rds")

car_rnet = overline(
  routes_drive_otp, 
  # attrib = c("car_driver", "motorbike", "taxi_other")
  attrib = "all_vehs",
  regionalise = 1e+07
  )
car_rnet = tibble::rowid_to_column(car_rnet, "ID")

saveRDS(car_rnet, "data/drive_rnet_jittered.Rds")

# tm_shape(car_rnet) + 
#   tm_lines("all_vehs", 
#            breaks = c(0, 500, 1000, 2000, 5000, 15000))


# UO coordinates ----------------------------------------------------------

# Need to find out whether some sensor locations are double-counted

# It includes all vehicles eg van / bus / HGV / taxi / motorbikes


# Validation --------------------------------------------------------------

car_rnet = readRDS("data/drive_rnet_jittered.Rds")
in_sum = readRDS("data/plates_in_stats_2021_2.Rds")
period = readRDS("data/plates_in_2021_2.Rds")
days_in_period = length(unique(period$day))

inn = in_sum %>% 
  mutate(`Mean daily plates in` = sum_plates/days_in_period)
map_net = car_rnet %>% 
  mutate(`Commute route network` = all_vehs) %>% 
  arrange(all_vehs) # so the high flow routes are plotted on top
# tm_shape(map_net) + tm_lines("Commute route network", 
#                              breaks = c(0, 500, 1000, 2000, 5000, 15000))

# Figure 2
tm_shape(map_net) + 
  tm_lines("Commute route network", 
           breaks = c(0, 500, 1000, 2000, 5000, 15000), lwd = 1.3) + 
  tm_shape(inn) + tm_dots("Mean daily plates in", size = 0.08, palette = "-magma")

# Join rnet with UO counts 

# Plates In
# Should find a way of removing residential/unclassified/service roads, these will be false matches

rnet_refs = st_nearest_feature(x = in_sum, y = car_rnet)
rnet_feats = car_rnet[rnet_refs, ]
rnet_joined = cbind(rnet_feats, in_sum)

# tm_shape(rnet_feats) + tm_lines("all_vehs", lwd = 3) +
#   tm_shape(in_sum) + tm_dots("sum_plates")

m1 = lm(sum_plates ~ all_vehs, data = rnet_joined)
summary(m1)
summary(m1)$r.squared
# Feb:
# [1] 0.326276 # plates in sum uncorrected
# [1] 0.3238171 # plates in sum corrected
# Jan:
# [1] 0.05131899 # car count mean
# [1] 0.2714064 # plates in mean
# [1] 0.2716468 # plates in sum

# Figure 3
ggplot(rnet_joined, aes(all_vehs, sum_plates/days_in_period)) + 
  geom_point() + 
  labs(y = "ANPR daily mean vehicles Feb 2021", x = "2011 Census car driver/taxi/motorbike/other commutes") +
  geom_smooth(method = "lm", se = FALSE, lty = "dashed") +
  expand_limits(y = 0, x = c(0, 12500)) # watch - done because 12000 label was going outside the graph area


# Time periods for EV charging --------------------------------------------

time_periods = plates_in_sd %>% 
  mutate(h3 = case_when(
    hour %in% c(0, 1, 2) ~ "0-3",
    hour %in% c(3, 4, 5) ~ "3-6",
    hour %in% c(6, 7, 8) ~ "6-9",
    hour %in% c(9, 10, 11) ~ "9-12",
    hour %in% c(12, 13, 14) ~ "12-15",
    hour %in% c(15, 16, 17) ~ "15-18",
    hour %in% c(18, 19, 20) ~ "18-21",
    hour %in% c(21, 22, 23) ~ "21-24"
    ))
time_group = time_periods %>% 
  st_drop_geometry() %>% 
  group_by(`Sensor Name`, day, h3, mean_reading, sd_reading) %>% 
  summarise(
    plates = sum(Value),
    count = n(),
    max_plates = max(Value)
    )
# Exclude time periods with less than 10 readings 
# or with a reading greater than 6 standard deviations higher than the mean reading
time_corrected = time_group %>% 
  filter(
    ! max_plates > (mean_reading + 6 * sd_reading),
    ! count < 10
    )
period_means = time_corrected %>% 
  group_by(`Sensor Name`, h3) %>% 
  summarise(mean_plates = mean(plates))
sensor_locations = time_periods %>% 
  select(`Sensor Name`) %>% 
  group_by(`Sensor Name`) %>% 
  filter(row_number() == 1)
sensor_periods = left_join(period_means, sensor_locations, by = "Sensor Name")
sensor_periods = st_as_sf(sensor_periods)
st_crs(sensor_periods) = 4326
# tm_shape(sensor_periods) + tm_dots("mean_plates")
saveRDS(sensor_periods, "data/sensor_periods_2021_2.Rds")
write_csv(sensor_periods, "data/sensor_periods_2021_2.csv")
