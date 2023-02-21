# tar_target(download_2013, {
#   periods = paste0("201", 3:9, "-86400")
#   for (i in periods) {
#     download_urban_data(period = i,
#                         dataset = "Vehicle%20Count",
#                         base_url = "https://archive.dev.urbanobservatory.ac.uk/file/year_agg_file/")
#   }
# }),
# tar_target(car_count_2021, {
#   pm10 = read_csv("data/2022-1-PM10.csv")
#   pm10 = st_as_sf(pm10, wkt = "Location (WKT)")
#   st_crs(pm10) = 4326
# }),
}), 
tar_target(car_count, {
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