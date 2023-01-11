# Test code to demonstrate R5 (needs R5 installed on the computer that runs this code)

library(tidyverse)
system("gh release download 0.1")
desire_lines = readRDS("data/od_car_jittered.Rds")

remotes::install_github("ipeaGIT/r5r", subdir = "r-package")
options(java.parameters = '-Xmx40G')
library(r5r)
rJava::.jinit()
# View(osmextract::geofabrik_zones)
wyca_match = osmextract::oe_match(place = "tyne and wear")
dir.create("data_r5")
osmextract::oe_download(file_url = wyca_match$url, download_directory = "data_r5")
r5r_core = r5r::setup_r5(data_path = "data_r5")
mode = c("CAR")
max_distance = 100
max_trip_duration_hrs = max_distance / 3.6
max_trip_duration_min = max_trip_duration_hrs * 60
# r5_network = r5r::street_network_to_sf(r5r_core = r5r_core)
# saveRDS(r5_network$edges, "r5_network_edges.Rds")
remotes::install_github("robinlovelace/router")

start_time = Sys.time()
routes = router::route(desire_lines, route_fun = detailed_itineraries,
                       r5r_core = r5r_core,
                       max_trip_duration = max_trip_duration_min,
                       mode = mode, shortest_path = FALSE, 
                       verbose = FALSE, progress = TRUE)
# list(r5_network = r5_network, routes = routes)
end_time = Sys.time()
routes %>% 
  sample_n(99) %>% 
  mapview::mapview()

timings = data.frame(
  start = start_time,
  end = end_time,
  n_routes = nrow(routes),
  duration = round(as.numeric(end_time) - as.numeric(start_time)),
  duration_min = round((as.numeric(end_time) - as.numeric(start_time))/60),
  routes_per_s = round(nrow(routes) / (round(as.numeric(end_time) - as.numeric(start_time))), 3)
)

start_time = Sys.time()
routes2 = stplanr::route(l = desire_lines, route_fun = route_osrm, osrm.profile = "car")
end_time = Sys.time()

timings2 = data.frame(
  start = start_time,
  end = end_time,
  n_routes = nrow(routes),
  duration = round(as.numeric(end_time) - as.numeric(start_time)),
  duration_min = round((as.numeric(end_time) - as.numeric(start_time))/60),
  routes_per_s = round(nrow(routes) / (round(as.numeric(end_time) - as.numeric(start_time))), 3)
)