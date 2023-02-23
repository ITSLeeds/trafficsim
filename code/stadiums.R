library(osmextract)
st_james_park = oe_get("St. James' Park")




# Time period around matches ----------------------------------------------

plates_5 = readRDS("data/plates_in_2021_5.Rds")
plates_6 = readRDS("data/plates_in_2021_6.Rds")
plates_7 = readRDS("data/plates_in_2021_7.Rds")
plates_8 = readRDS("data/plates_in_2021_8.Rds")
plates_9 = readRDS("data/plates_in_2021_9.Rds")
plates_10 = readRDS("data/plates_in_2021_10.Rds")
plates_11 = readRDS("data/plates_in_2021_11.Rds")
plates_12 = readRDS("data/plates_in_2021_12.Rds")

# Nearby sensors

nearby = plates_5 %>% 
  filter(
    `Sensor Name` %in% c("PER_NE_CAJT_NCA189_SJB2_SJB1", "PER_NE_CAJT_NCA189_BR3_GR",
                         "PER_NE_CAJT_NCA189_BR3_SJB2", "PER_NE_CAJT_NCA189_SJB2_BR3"))

# Get full list of home match days

match_1 = nearby %>% 
  filter(day == "2021-05-14")

# Check days without matches
no_match = nearby %>% 
  filter(! day == "2021-05-14",
         day_of_week == "Friday")

# Match day
sensor_hour = match_1 %>% 
  st_drop_geometry() %>% 
  group_by(`Sensor Name`, day, hour) %>% 
  summarise(
    plates = sum(Value),
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

hour_group = sensor_hour %>% 
  group_by(hour) %>% 
  summarise(days = length(unique(day)),
    daily_plates = sum(plates)/days
    )

ggplot(hour_group, aes(hour, daily_plates)) +
  geom_line()

# Other days
sensor_hour = no_match %>% 
  st_drop_geometry() %>% 
  group_by(`Sensor Name`, day, hour) %>% 
  summarise(
    plates = sum(Value),
    count = n(),
    max_plates = max(Value)
  )

hour_group = sensor_hour %>% 
  group_by(hour) %>% 
  summarise(days = length(unique(day)),
            daily_plates = sum(plates)/days
  )

ggplot(hour_group, aes(hour, daily_plates)) +
  geom_line()




# saveRDS(sensor_periods, "data/sensor_periods_2021_2.Rds")
# write_csv(sensor_periods, "data/sensor_periods_2021_2.csv")
