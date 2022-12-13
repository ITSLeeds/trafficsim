# Test code to demonstrate R5 (needs R5 installed on the computer that runs this code)

library(tidyverse)
system("gh release download 0.1")
desire_lines = readRDS("od_car_jittered.Rds")

remotes::install_github("ipeaGIT/r5r", subdir = "r-package")
options(java.parameters = "-Xmx40G")
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
routes = router::route(desire_lines, route_fun = detailed_itineraries,
                       r5r_core = r5r_core,
                       max_trip_duration = max_trip_duration_min,
                       mode = mode, shortest_path = FALSE, 
                       verbose = FALSE, progress = TRUE)
list(r5_network = r5_network, routes = routes)
routes %>% 
  sample_n(99) %>% 
  mapview::mapview()
