
# setup -------------------------------------------------------------------

library(targets)
# remotes::install_github("itsleeds/dfttrafficcounts")
# library(tidyverse)
library(sf)
source("R/download.R")
# library(tmap)
# tmap_mode("view")
library(tidyverse)
options(tidyverse.quiet = TRUE)
sf::sf_use_s2(TRUE)
tar_option_set(packages = c("tidyverse", "tmap", "sf"))


# targets for workflow management -----------------------------------------

list(
  tar_target(raw_count_data, {
    # u = "https://storage.googleapis.com/dft-statistics/road-traffic/downloads/data-gov-uk/dft_traffic_counts_raw_counts.zip"
    # f = basename(u)
    # download.file(u, f)
    # unzip(f)
    count_data_raw = read_csv("dft_traffic_counts_raw_counts.csv")
  }),
  tar_target(clean_traffic_data, {
    raw_count_data %>% 
      na.omit()
  }),
  tar_target(newcastle_data, {
    newcastle_data = clean_traffic_data %>% 
      filter(Local_authority_name == "Newcastle upon Tyne")
    newcastle_data = newcastle_data %>% 
      sf::st_as_sf(coords = c("Longitude", "Latitude"), crs = 4326)
    # tm_shape(newcastle_data) + tm_dots()
  }),
  tar_target(newc_2021, {
    newc_2021 = newcastle_data %>% 
      filter(Year == 2021)
    # 12 unique count points in 2021, each of which has 24 hours of data, each from a different day
    # newc_2021 %>% 
    #   group_by(Count_point_id) %>% 
    #   summarise(n = n())
    # newc_2021 %>% 
    #   group_by(Count_date) %>% 
    #   summarise(n = n())
  }),
  tar_target(download, {
    # period data:
    periods = paste0("2021-", 1:12)
    for(i in periods) {
      download_urban_data(period = i, dataset = "Average%20Speed")
      # https://archive.dev.urbanobservatory.ac.uk/file/month_file/2021-1-Car%20Count.csv.zip
      download_urban_data(period = i, dataset = "Car%20Count")
      download_urban_data(period = i, dataset = "Congestion")
      download_urban_data(period = i, dataset = "Traffic%20Flow")
      download_urban_data(period = i, dataset = "Plates%20In")
      download_urban_data(period = i, dataset = "Plates%20Out")
    }
    # years = as.character(2019:2021)
    # for(i in years) {
    #   download_urban_data(period = i, dataset = "People%20Count")
    #   download_urban_data(period = i, dataset = "People%20Count")
    # }
  }),
  tar_target(plates_2021, {
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
    
  }),
  # tar_target(download_2013, {
  #   periods = paste0("201", 3:9, "-86400")
  #   for (i in periods) {
  #     download_urban_data(period = i, 
  #                         dataset = "Vehicle%20Count",
  #                         base_url = "https://archive.dev.urbanobservatory.ac.uk/file/year_agg_file/")
  #   }
  # }),
  tar_target(car_count_2021, {
    # hourly aggregated
    car_count_2021 = read_csv("data/2021-1-Car Count.csv")
    # 207 sensors, 4000-8000 hours of data each (8760hrs in a yr)
    # car_count_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    car_count_2021 = st_as_sf(car_count_2021, wkt = "Location (WKT)")
    st_crs(car_count_2021) = 4326
  }), 
  # tar_target(plates_2021, {
  #   # hourly aggregated
  #   plates_in_2021 = read_csv("data/2021-1-Plates In.csv")
  #   # 207 sensors, 4000-8000 hours of data each (8760hrs in a yr)
  #   # plates_2021 %>%
  #   #   group_by(`Sensor Name`) %>%
  #   #   summarise(n = n())
  #   plates_in_2021 = st_as_sf(plates_in_2021, wkt = "Location (WKT)")
  #   st_crs(plates_in_2021) = 4326
  #   plates_out_2021 = read_csv("data/2021-1-Plates Out.csv")
  #   # 207 sensors, 4000-8000 hours of data each (8760hrs in a yr)
  #   # plates_2021 %>%
  #   #   group_by(`Sensor Name`) %>%
  #   #   summarise(n = n())
  #   plates_out_2021 = st_as_sf(plates_out_2021, wkt = "Location (WKT)")
  #   st_crs(plates_out_2021) = 4326
  # }), 
  tar_target(traffic_flow_2021, {
    # hourly aggregated
    traffic_flow_2021 = read_csv("data/2021-1-Traffic Flow.csv")
    # 207 sensors, 4000-8000 hours of data each (8760hrs in a yr)
    # car_count_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    traffic_flow_2021 = st_as_sf(traffic_flow_2021, wkt = "Location (WKT)")
    st_crs(traffic_flow_2021) = 4326
  }), 
  tar_target(average_speed_2021, {
    # hourly aggregated
    average_speed_2021 = read_csv("data/2021-1-Average Speed.csv")
    # 207 sensors, 4000-8000 hours of data each (8760hrs in a yr)
    # car_count_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    average_speed_2021 = st_as_sf(average_speed_2021, wkt = "Location (WKT)")
    st_crs(average_speed_2021) = 4326
  }), 
  tar_target(congestion_2021, {
    # hourly aggregated
    congestion_2021 = read_csv("data/2021-1-Congestion.csv")
    # 207 sensors, 4000-8000 hours of data each (8760hrs in a yr)
    # car_count_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    congestion_2021 = st_as_sf(congestion_2021, wkt = "Location (WKT)")
    st_crs(congestion_2021) = 4326
#   }), 
# tar_target(car_sum, {
#   car_sum = car_count_2021 %>% 
#     group_by(`Sensor Name`) %>% 
#     summarise(cars = sum(Value),
#               n = n())
#   }),
# tar_target(car_2017, { # 21 locations
#   car_2017 = read.csv("data/2022-86400-Plates%20In.csv")
#   car_2017 = st_as_sf(car_2017, wkt = "Location..WKT.")
#   st_crs(car_2017) = 4326
#   car_2017_sum = car_2017 %>% 
#     group_by(Sensor.Name) %>% 
#     summarise(mean_cars = mean(Mean.Value),
#               n = n())
})
# ,
# tar_target(walking_routes, {
#   remotes::install_github("ipeaGIT/r5r", subdir = "r-package")
#   options(java.parameters = '-Xmx40G')
#   library(r5r)
#   rJava::.jinit()
#   wyca_match = osmextract::oe_match(place = "West Yorkshire")
#   osmextract::oe_download(file_url = wyca_match$url, download_directory = "data_r5")
#   r5r_core = r5r::setup_r5(data_path = "data_r5") # Message on ubuntu at Leeds Uni - "No internet connection"
#   mode = c("WALK")
#   max_distance = 10
#   max_trip_duration_hrs = max_distance / 3.6
#   max_trip_duration_min = max_trip_duration_hrs * 60
#   r5_network = r5r::street_network_to_sf(r5r_core = r5r_core)
#   saveRDS(r5_network$edges, "r5_network_edges.Rds")
#   routes = router::route(od_jittered, route_fun = detailed_itineraries,
#                          max_lts = 2, r5r_core = r5r_core,
#                          max_trip_duration = max_trip_duration_min,
#                          mode = mode, shortest_path = FALSE,
#                          verbose = FALSE, progress = TRUE)
#   list(r5_network = r5_network, routes = routes)
# }),
  # # The linestring WKT geometries are not being shown correctly in the csv files
  # # this needs editing by hand or new code
  # tar_target(plates_match_2021, {
  #   # hourly aggregated
  #   plates_match_2021 = read_csv("data/uo-newcastle/2021-day-Plates Matching.csv")
  #   # 311 sensors, around 100-360 days of data each 
  #   # plates_match_2021 %>%
  #   #   group_by(`Sensor Name`) %>%
  #   #   summarise(n = n())
  #   plates_match_2021 = st_as_sf(plates_match_2021, wkt = "Location (WKT)")  
  # }),
  # tar_target(traffic_flow_2021, {
  #   # hourly aggregated
  #   traffic_flow_2021 = read_csv("data/uo-newcastle/2021-86400-Traffic Flow.csv")
  #   # there is only data for a small area around the Metro Centre
  #   # traffic_flow_2021 %>%
  #   #   group_by(`Sensor Name`) %>%
  #   #   summarise(n = n())
  #   traffic_flow_2021 = st_as_sf(traffic_flow_2021, wkt = "Location (WKT)")
  # }),
  # tar_target(people_count_2021, {
  #   # hourly aggregated
  #   people_count_2021 = read_csv("data/uo-newcastle/2021-3600-People Count.csv")
  #   # 205 sensors, ~1500 hours of data each (8760hrs in a yr)
  #   # people_count_2021 %>%
  #   #   group_by(`Sensor Name`) %>%
  #   #   summarise(n = n())
  #   people_count_2021 = st_as_sf(people_count_2021, wkt = "Location (WKT)")
  # }),
  # # Raw data for January
  # tar_target(people_count_jan, {
  #   # hourly aggregated
  #   people_count_jan = read_csv("data/uo-newcastle/2021-1-People Count.csv")
  #   # 206 sensors, 2000-5000 minutes of data each 
  #   # people_count_jan %>%
  #   #   group_by(`Sensor Name`) %>%
  #   #   summarise(n = n())
  #   people_count_jan = st_as_sf(people_count_jan, wkt = "Location (WKT)")
  # }),
  # tar_target(walking_2021, {
  #   # hourly aggregated
  #   walking_2021 = read_csv("data/uo-newcastle/2021-3600-Walking.csv")
  #   # 74 sensors, 6000-8000 hours of data each (8760hrs in a yr)
  #   # walking_2021 %>%
  #   #   group_by(`Sensor Name`) %>%
  #   #   summarise(n = n())
  #   walking_2021 = st_as_sf(walking_2021, wkt = "Location (WKT)")
  # }),
  # tar_target(cycling_2021, {
  #   # hourly aggregated
  #   cycling_2021 = read_csv("data/uo-newcastle/2021-86400-Cycle Count.csv")
  #   # 205 sensors, 71-72 days of data each 
  #   # cycling_2021 %>%
  #   #   group_by(`Sensor Name`) %>%
  #   #   summarise(n = n())
  #   cycling_2021 = st_as_sf(cycling_2021, wkt = "Location (WKT)")
  # })
)


