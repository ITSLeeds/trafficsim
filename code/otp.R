# OTP setup ---------------------------------------------------------------

library(opentripplanner)

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
# # install.packages("tmap") # Only needed if you don't have tmap
# library(tmap)              # Load the tmap package
# tmap_mode("view")          # Set tmap to interactive viewing
# qtm(route)                 # Plot the route on a map
# otp_stop()

# Tyne and Wear -----------------------------------------------------------

# Currently only works for routes wholly within Tyne and Wear
# I need to add in OSM data for Durham and Northumberland

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
od = st_coordinates(des_top)
od = od[,-3]
# o = od %>% filter(row_number() %% 2 == 1)
# d = od %>% filter(row_number() %% 2 == 0)
even_indexes<-seq(2,10,2)
odd_indexes<-seq(1,9,2)
o = od[odd_indexes,]
d = od[even_indexes,]
route = otp_plan(otpcon,
                 fromPlace = o,
                 toPlace = d
                 )
qtm(des_top)
qtm(route)

otp_stop()
