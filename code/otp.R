# For ubuntu:
# in terminal switch to java 8 (and switch back again afterwards?)
# sudo update-java-alternatives --set /usr/lib/jvm/java-1.8.0-openjdk-amd64

# to switch back to Java 11:
# sudo update-java-alternatives --set /usr/lib/jvm/java-1.11.0-openjdk-amd64

# OTP setup ---------------------------------------------------------------

path_data = file.path("OTP")
dir.create(path_data)

path_otp = otp_dl_jar(path_data, cache = FALSE)
otp_dl_demo(path_data)
log1 = otp_build_graph(otp = path_otp, dir = path_data) # assigns 2GB memory by default
log1 = otp_build_graph(otp = path_otp, dir = path_data, memory = 10240) # to assign 10GB memory
log2 = otp_setup(otp = path_otp, dir = path_data)
otpcon = otp_connect(hostname = "localhost",
                     router = "default")
otp_stop()
