library(osmextract)
st_james_park = oe_get("St. James' Park")




# Time period around matches ----------------------------------------------

# Half season Aug-Dec 2021
# plates_5 = readRDS("data/plates_in_2021_5.Rds")
# plates_6 = readRDS("data/plates_in_2021_6.Rds")
# plates_7 = readRDS("data/plates_in_2021_7.Rds")
plates_8 = readRDS("data/plates_in_2021_8.Rds")
plates_9 = readRDS("data/plates_in_2021_9.Rds")
plates_10 = readRDS("data/plates_in_2021_10.Rds")
plates_11 = readRDS("data/plates_in_2021_11.Rds")
plates_12 = readRDS("data/plates_in_2021_12.Rds")

# Nearby sensors
plates_8 = plates_8 %>% 
  filter(
    `Sensor Name` %in% c("PER_NE_CAJT_NCA189_SJB2_SJB1", "PER_NE_CAJT_NCA189_BR3_GR",
                         "PER_NE_CAJT_NCA189_BR3_SJB2", "PER_NE_CAJT_NCA189_SJB2_BR3"))
plates_9 = plates_9 %>% 
  filter(
    `Sensor Name` %in% c("PER_NE_CAJT_NCA189_SJB2_SJB1", "PER_NE_CAJT_NCA189_BR3_GR",
                         "PER_NE_CAJT_NCA189_BR3_SJB2", "PER_NE_CAJT_NCA189_SJB2_BR3"))
plates_10 = plates_10 %>% 
  filter(
    `Sensor Name` %in% c("PER_NE_CAJT_NCA189_SJB2_SJB1", "PER_NE_CAJT_NCA189_BR3_GR",
                         "PER_NE_CAJT_NCA189_BR3_SJB2", "PER_NE_CAJT_NCA189_SJB2_BR3"))
plates_11 = plates_11 %>% 
  filter(
    `Sensor Name` %in% c("PER_NE_CAJT_NCA189_SJB2_SJB1", "PER_NE_CAJT_NCA189_BR3_GR",
                         "PER_NE_CAJT_NCA189_BR3_SJB2", "PER_NE_CAJT_NCA189_SJB2_BR3"))
plates_12 = plates_12 %>% 
  filter(
    `Sensor Name` %in% c("PER_NE_CAJT_NCA189_SJB2_SJB1", "PER_NE_CAJT_NCA189_BR3_GR",
                         "PER_NE_CAJT_NCA189_BR3_SJB2", "PER_NE_CAJT_NCA189_SJB2_BR3"))
half_season = bind_rows(plates_8, plates_9, plates_10, plates_11, plates_12)

# All home match days 21-22 season
match_days = half_season %>% 
  filter(day == "2021-08-07" | day == "2021-08-15" | day == "2021-08-25" | day == "2021-08-28" | day == "2021-09-17"
         | day == "2021-10-17" | day == "2021-10-30" | day == "2021-11-20" | day == "2021-11-30" | day == "2021-12-04"
         | day == "2021-12-19" | day == "2021-12-27")
match_days = match_days %>% 
  filter(day_of_week == "Sunday" | day_of_week == "Saturday")

# Days without home matches
other_days = half_season %>% 
  filter(day != "2021-08-07" & day != "2021-08-15" & day != "2021-08-25" & day != "2021-08-28" & day != "2021-09-17"
                  & day != "2021-10-17" & day != "2021-10-30" & day != "2021-11-20" & day != "2021-11-30" & day != "2021-12-04"
                  & day != "2021-12-19" & day != "2021-12-27")
other_days = other_days %>% 
  filter(day_of_week == "Sunday" | day_of_week == "Saturday")

# Match day
sensor_hour = match_days %>% 
  st_drop_geometry() %>% 
  group_by(`Sensor Name`, day, hour) %>% 
  summarise(
    hourly_plates = sum(Value),
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

hour_match = sensor_hour %>% 
  group_by(hour) %>% 
  summarise(days = length(unique(day)),
    hourly_plates = sum(hourly_plates)/days
    )


# Other days
sensor_hour = other_days %>% 
  st_drop_geometry() %>% 
  group_by(`Sensor Name`, day, hour) %>% 
  summarise(
    hourly_plates = sum(Value),
    count = n(),
    max_plates = max(Value)
  )

hour_other = sensor_hour %>% 
  group_by(hour) %>% 
  summarise(days = length(unique(day)),
            hourly_plates = sum(hourly_plates)/days
  )

ggplot() +
  geom_line(data = hour_other, aes(hour, hourly_plates), col = "black", lwd = 1) +
  geom_line(data = hour_match, aes(hour, hourly_plates), col = "red", lwd = 1) +
  labs(x = "Time", y = "Mean hourly vehicles")




# saveRDS(sensor_periods, "data/sensor_periods_2021_2.Rds")
# write_csv(sensor_periods, "data/sensor_periods_2021_2.csv")
