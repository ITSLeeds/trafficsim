
# setup -------------------------------------------------------------------

library(targets)
# remotes::install_github("itsleeds/dfttrafficcounts")
# library(tidyverse)
# library(sf)
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
    }
    # years = as.character(2019:2021)
    # for(i in years) {
    #   download_urban_data(period = i, dataset = "People%20Count")
    #   download_urban_data(period = i, dataset = "People%20Count")
    # }
  }),
  tar_target(car_count_2021, {
    # hourly aggregated
    car_count_2021 = read_csv("data/2021-1-Car Count.csv")
    # 207 sensors, 4000-8000 hours of data each (8760hrs in a yr)
    # car_count_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    car_count_2021 = st_as_sf(car_count_2021, wkt = "Location (WKT)")
  }), 
  tar_target(traffic_flow_2021, {
    # hourly aggregated
    traffic_flow_2021 = read_csv("data/2021-1-Traffic Flow.csv")
    # 207 sensors, 4000-8000 hours of data each (8760hrs in a yr)
    # car_count_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    traffic_flow_2021 = st_as_sf(traffic_flow_2021, wkt = "Location (WKT)")
  }), 
  tar_target(average_speed_2021, {
    # hourly aggregated
    average_speed_2021 = read_csv("data/2021-1-Average Speed.csv")
    # 207 sensors, 4000-8000 hours of data each (8760hrs in a yr)
    # car_count_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    average_speed_2021 = st_as_sf(average_speed_2021, wkt = "Location (WKT)")
  }), 
  tar_target(congestion_2021, {
    # hourly aggregated
    congestion_2021 = read_csv("data/2021-1-Congestion.csv")
    # 207 sensors, 4000-8000 hours of data each (8760hrs in a yr)
    # car_count_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    congestion_2021 = st_as_sf(congestion_2021, wkt = "Location (WKT)")
  }), 
tar_target(car_sum, {
  car_sum = car_count_2021 %>% 
    group_by(`Sensor Name`) %>% 
    summarise(cars = sum(Value),
              n = n())
  })
  # tar_target(walking_routes, {
  #   remotes::install_github("ipeaGIT/r5r", subdir = "r-package")
  #   options(java.parameters = "-Xmx40G")
  #   library(r5r)
  #   rJava::.jinit()
  #   wyca_match = osmextract::oe_match(place = "West Yorkshire")
  #   osmextract::oe_download(file_url = wyca_match$url, download_directory = "data_r5")
  #   r5r_core = r5r::setup_r5(data_path = "data_r5")
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
  #   
  # })
# ,
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

# tm_shape(car_sum) + tm_dots("cars")
