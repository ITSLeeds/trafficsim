plates_in_2021 = readRDS("data/plates_in_2021_2.Rds")

in_sd_mean = plates_in_2021 %>%
  st_drop_geometry() %>%
  group_by(`Sensor Name`) %>%
  summarise(n = n(),
            mean_reading = mean(Value),
            sd_reading = sd(Value)
  )

# Data quality checking
plates_in_sd = inner_join(plates_in_2021, in_sd_mean, by = "Sensor Name")

# Correction to remove extreme outliers (parked cars?) - not required in normal use:
# plates_in_corrected = plates_in_sd %>%
#   mutate(Value = case_when(Value > (mean_reading + 6 * sd_reading) ~ mean_reading,
#                            TRUE ~ Value)
#          )

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
