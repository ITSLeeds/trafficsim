# OTP setup ---------------------------------------------------------------

library(opentripplanner)
library(tmap)
tmap_mode("view")

# Check Java
otp_check_java()

# For ubuntu:
# in terminal switch to java 8 (and switch back again afterwards?)
# sudo update-java-alternatives --set /usr/lib/jvm/java-1.8.0-openjdk-amd64

# to switch back to Java 11:
# sudo update-java-alternatives --set /usr/lib/jvm/java-1.11.0-openjdk-amd64

path_data = file.path("OTP")
dir.create(path_data)

# Download OTP
path_otp = otp_dl_jar(path_data, cache = FALSE)

# Isle of Wight example ---------------------------------------------------

# # Download example data
# otp_dl_demo(path_data)
# # Build OTP graph
# log1 = otp_build_graph(otp = path_otp, dir = path_data) # assigns 2GB memory by default
# # log1 = otp_build_graph(otp = path_otp, dir = path_data, memory = 10240) # to assign 10GB memory
# # Launch OTP
# log2 = otp_setup(otp = path_otp, dir = path_data)
# # Connect to OTP
# otpcon = otp_connect(hostname = "localhost",
#                      router = "default")
# # Get a route
# route <- otp_plan(otpcon, 
#                   fromPlace = c(-1.17502, 50.64590), 
#                   toPlace = c(-1.15339, 50.72266))
# qtm(route)
# otp_stop()

# Tyne and Wear -----------------------------------------------------------

# Currently only works for routes wholly within Tyne and Wear
# I need to add in OSM data for Durham and Northumberland

# Get OSM data as .osm.pbf and save in OTP directory
# Previously ran get-osm.R but this creates the wrong file type
View(osmextract::geofabrik_zones)
tw_match = osmextract::oe_match(place = "tyne and wear")
dir.create("OTP/graphs/tyne-and-wear")
north_match = osmextract::oe_match("northumberland")
durham_match = osmextract::oe_match("durham")
osmextract::oe_download(file_url = tw_match$url, download_directory = "data")
osmextract::oe_download(file_url = north_match$url, download_directory = "data")
osmextract::oe_download(file_url = durham_match$url, download_directory = "data")

# Run in terminal after installing osmium and osmconvert:
# osmium cat data/geofabrik_tyne-and-wear-latest.osm.pbf -o data/geofabrik_tyne-and-wear-latest.osm
# osmium cat data/geofabrik_northumberland-latest.osm.pbf -o data/geofabrik_northumberland-latest.osm
# osmium cat data/geofabrik_durham-latest.osm.pbf -o data/geofabrik_durham-latest.osm
# osmconvert data/geofabrik_tyne-and-wear-latest.osm data/geofabrik_northumberland-latest.osm data/geofabrik_durham-latest.osm -o=data/north-east.osm
# osmium cat data/north-east.osm -o OTP/graphs/tyne-and-wear/north-east.osm.pbf

# Build OTP graph
log1 = otp_build_graph(otp = path_otp, 
                       dir = path_data, 
                       router = "tyne-and-wear",
                       memory = 8192
                       )
# Launch OTP
log2 = otp_setup(otp = path_otp, dir = path_data, router = "tyne-and-wear")
# Connect to OTP
otpcon = otp_connect(hostname = "localhost",
                     router = "tyne-and-wear")
# Get routes
# route = otp_plan(otpcon,
#                  fromPlace = c(-1.617, 54.978),
#                  toPlace = c(-1.384, 54.907)
#                  )
desire_lines = readRDS("data/od_car_jittered.Rds")
library(tidyverse)
des_top = desire_lines %>% sample_n(5)
# o = lwgeom::st_startpoint(des_top)
# d = lwgeom::st_endpoint(des_top)
library(sf)
od = st_coordinates(desire_lines)
od = od[,-3]
# o = od %>% filter(row_number() %% 2 == 1)
# d = od %>% filter(row_number() %% 2 == 0)
even = if(nrow(od) %% 2 == 0) {
  nrow(od) 
} else {
    nrow(od) - 1 
}
odd = if(nrow(od) %% 2 == 1) {
  nrow(od) 
} else {
  nrow(od) - 1 
}
even_indexes<-seq(2,even,2)
odd_indexes<-seq(1,odd,2)
o = od[odd_indexes,]
d = od[even_indexes,]
route = otp_plan(otpcon,
                 fromPlace = o,
                 toPlace = d
                 )
# qtm(desire_lines)
# qtm(route)
saveRDS(route, "data/routes_car_otp_3_counties.Rds")

otp_stop()
