library(sf)
source("R/download.R")
# library(tmap)
# tmap_mode("view")
library(tidyverse)
options(tidyverse.quiet = TRUE)
sf::sf_use_s2(TRUE)

year = 2021
periods = paste0(year, "-", 1:12)
sensor = "Plates In"
sensor_lc = tolower(sensor)
sensor_lc = sub(pattern = " ", replacement = "_", sensor_lc)
for(i in periods) {
  sensor_mod = sub(pattern = " ", replacement = "%20", sensor)
  download_urban_data(period = i, dataset = sensor_mod)
}
for(i in periods) {
  i_formatted = gsub(pattern = "-", replacement = "_", x = i)
  newfile = file.path("data", paste0(sensor_lc, "_", i_formatted, ".Rds"))
  if(!file.exists(newfile)) {
    filepath = paste0("data/", i, "-", sensor, ".csv")
    x = read_csv(filepath)
    x = x %>%
      filter(str_detect(pattern = "DUMMY", `Sensor Name`) == FALSE) %>%
      filter(str_detect(pattern = "TEST", `Sensor Name`) == FALSE)
    if(grepl("plates", sensor_lc)) {
      x = x %>% 
        filter(str_detect(pattern = "BUS", `Sensor Name`) == FALSE) # To exclude bus lane cameras when using Plates In / Plates Out 
    }
    x = x %>%
      mutate(day = as.Date(Timestamp))
    in_day = x %>%
      group_by(`Sensor Name`, day) %>%
      summarise(
        sum_readings_day = sum(Value),
        n_readings_day = n()
      )
    in_max = in_day %>%
      group_by(`Sensor Name`) %>%
      summarise(
        sum_readings_max = max(sum_readings_day),
        sum_readings_medi = median(sum_readings_day),
        n_readings_max = max(n_readings_day),
        n_readings_medi = median(n_readings_day)
      )
    in_sensor_days = inner_join(in_day, in_max, by = "Sensor Name")
    if(grepl("plates", sensor_lc)) {
      in_full_days = in_sensor_days %>%
        filter(
          sum_readings_day > (sum_readings_max/5) # for plates, 20% of max traffic counts as a full record
        )
    } else {
      in_full_days = in_sensor_days %>%
        filter(
          n_readings_day > (n_readings_max/5) # for other sensors, 20% of max n_readings counts as a full record
        )
    }
    day_by_day = in_full_days %>%
      group_by(day) %>%
      summarise(n = n())
    keep_days = day_by_day %>%
      filter(
        n > nrow(in_max)/2  # need full records for at least half of all sensors
      )
    keep_days = keep_days$day
    # kept = c(kept, keep_days)
    if(grepl("plates", sensor_lc)) {
      working_sensors = in_sensor_days %>%
        filter(
          sum_readings_medi > 0 # for plates (less than half of days have zero traffic)
        ) %>%
        select(`Sensor Name`) %>%
        distinct()
    } else {
      working_sensors = in_sensor_days %>%
        filter(
          n_readings_medi > 0 # for other sensors (less than half of days have zero readings)
        ) %>%
        select(`Sensor Name`) %>%
        distinct()
    }
    x = x %>%
      filter(day %in% keep_days, # only include days with full records for sufficient sensors
             `Sensor Name` %in% working_sensors$`Sensor Name`) # exclude sensors with 0 cars/0 readings on most days
    x = x %>%
      mutate(day_of_week = weekdays(as.Date(Timestamp)),
             time = hms::as_hms(Timestamp),
             hour = lubridate::hour(time))
    x = x %>%
      mutate(coords = sub(pattern = ",.*", replacement = "", `Location (WKT)`),
             coords = sub(pattern = ".*\\(", replacement = "", coords),
             coords = sub(pattern = "\\)", replacement = "", coords))
    x = x %>%
      mutate(long = sub(pattern = " .*", replacement = "", coords),
             lat = sub(pattern = ".* ", replacement = "", coords),
             day = as.Date(Timestamp))
    x = st_as_sf(x, coords = c("long", "lat"))
    st_crs(x) = 4326
    assign(paste0(sensor_lc, "_", i_formatted), x)
    saveRDS(x, newfile)
  }
  groupfile = file.path("data", paste0(sensor_lc, "_stats_", i_formatted, ".Rds"))
  if(!file.exists(groupfile)) {
    x = readRDS(newfile)
    in_sd_mean = x %>% 
      st_drop_geometry() %>% 
      group_by(`Sensor Name`) %>% 
      summarise(n = n(),
                median_reading = median(Value),
                mean_reading = mean(Value),
                sd_reading = sd(Value)
      )
    sensor_sd = inner_join(x, in_sd_mean, by = "Sensor Name")
    # Optional further data cleaning:
    # Now remove any delayed readings if doing analysis based on short time periods
    # sensor_peak = sensor_sd %>% 
    #   filter(!(day_of_week == "Sunday" | day_of_week == "Saturday")
    #          , hour %in% c(7,8,9,16,17,18)
    #   )
    sensor_group = sensor_sd %>% 
      st_drop_geometry() %>% 
      group_by(`Sensor Name`) %>% 
      summarise(
        n = n(),
        median_value = median(Value),
        mean_value = mean(Value),
        sd_value = sd(Value),
        sum_value = sum(Value)
      )
    sensor_locations = sensor_sd %>% 
      select(`Sensor Name`) %>% 
      group_by(`Sensor Name`) %>% 
      filter(row_number() == 1)
    sensor_stats = left_join(sensor_group, sensor_locations, by = "Sensor Name")
    sensor_stats = st_as_sf(sensor_stats)
    st_crs(sensor_stats) = 4326
    
    filename = paste0("data/", sensor_lc, "_stats_", i_formatted, ".Rds")
    saveRDS(sensor_stats, filename)
    # tm_shape(sensor_stats) + tm_dots("median_value")
  }
}