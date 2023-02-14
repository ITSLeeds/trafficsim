periods = paste0("2021-", 1:12)
for(i in periods) {
  filepath = paste0("data/", i, "-Plates In.csv")
  x = read_csv(filepath)
  x = x %>% 
    filter(str_detect(pattern = "BUS", `Sensor Name`) == FALSE) %>% 
    filter(str_detect(pattern = "DUMMY", `Sensor Name`) == FALSE) %>% 
    filter(str_detect(pattern = "TEST", `Sensor Name`) == FALSE)
  i_formatted = gsub(pattern = "-", replacement = "_", x = i)
  assign(paste0("plates_in_", i_formatted), x)
}

# Find out which days have incomplete data
months = paste0("2021_", 1:12)
# kept = as.Date(NULL)
for(i in months) {
  x = get(paste0("plates_in_", i))
  x = x %>% 
    mutate(day = as.Date(Timestamp))
  in_day = x %>% 
    group_by(`Sensor Name`, day) %>% 
    summarise(cars_day = sum(Value))
  in_max = in_day %>% 
    group_by(`Sensor Name`) %>% 
    summarise(day_max = max(cars_day),
              day_medi = median(cars_day)) 
  in_sensor_days = inner_join(in_day, in_max, by = "Sensor Name")
  in_full_days = in_sensor_days %>%
    filter(cars_day > (day_max/5)) # 20% of peak traffic counts as a full record
  day_by_day = in_full_days %>% 
    group_by(day) %>% 
    summarise(n = n())
  keep_days = day_by_day %>% 
    filter(n > 100) # need full records for at least 100 sensors
  keep_days = keep_days$day
  # kept = c(kept, keep_days)
  working_sensors = in_sensor_days %>% 
    filter(day_medi > 0) %>% 
    select(`Sensor Name`) %>% 
    distinct()
  x = x %>% 
    filter(day %in% keep_days, # only include days with full records for 100 sensors
           `Sensor Name` %in% working_sensors$`Sensor Name`) # exclude sensors with 0 cars on most days
  x = x %>% 
    mutate(day_of_week = weekdays(as.Date(Timestamp)),
           time = hms::as_hms(Timestamp),
           hour = lubridate::hour(time))
  x = x %>% 
    mutate(coords = sub(pattern = ",.*", replacement = "", `Location (WKT)`),
           coords = sub(pattern = ".*\\(", replacement = "", coords))
  x = x %>% 
    mutate(long = sub(pattern = " .*", replacement = "", coords),
           lat = sub(pattern = ".* ", replacement = "", coords),
           day = as.Date(Timestamp))
  x = st_as_sf(x, coords = c("long", "lat"))
  st_crs(x) = 4326
  assign(paste0("plates_in_", i), x)
  filename = paste0("data/plates_in_", i, ".Rds")
  saveRDS(x, filename)
}

# Combined data frame is too large to work with easily

# plates_in = as.data.frame(NULL)
# for(i in months) {
#   x = get(paste0("plates_in_", i))
#   plates_in = bind_rows(plates_in, x)
# }

