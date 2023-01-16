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

# Build OTP graph
log1 = otp_build_graph(otp = path_otp, dir = path_data)
# Launch OTP
log2 = otp_setup(otp = path_otp, dir = path_data, router = "tyne-and-wear")
# Connect to OTP
otpcon = otp_connect(hostname = "localhost",
                     router = "tyne-and-wear")
otp_stop()
