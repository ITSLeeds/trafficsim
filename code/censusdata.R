
# Tyne and Wear census data -----------------------------------------------
library(pct)
library(tmap)
library(tidyverse)
library(stplanr)
library(sf)
library(lubridate)
tmap_mode("view")

northeast = get_pct_zones("north-east", geography = "msoa")
northumberland = get_pct_zones("northumberland", geography = "msoa")
wider_northeast = bind_rows(northeast, northumberland)
wider_northeast = wider_northeast %>% 
  select(geo_code)

# Do either get_pct or get_pct_lines include intrazonal flows?
# should we use get_od?
lines = get_pct(region = "north-east", purpose = "commute", geography = "msoa", layer = "l")
lines_tyneandwear = lines %>% 
  filter(lad_name1 == "Newcastle upon Tyne" | lad_name1 == "Sunderland" | 
           lad_name1 == "Gateshead" | lad_name1 == "North Tyneside" |  
           lad_name1 =="South Tyneside" | lad_name2 == "Newcastle upon Tyne" | 
           lad_name2 == "Sunderland" | lad_name2 == "Gateshead" | 
           lad_name2 == "North Tyneside" |  lad_name2 =="South Tyneside"
         )
# tm_shape(lines_tyneandwear) + tm_lines()

lines_matching = lines_tyneandwear %>% 
  filter(geo_code1 %in% wider_northeast$geo_code & geo_code2 %in% wider_northeast$geo_code)

# changed to get all vehicles not just car drivers
lines_drive = lines_matching %>% 
  filter(car_driver > 0 | taxi_other > 0 | motorbike > 0) %>% # excludes buses
  select(geo_code1, geo_code2, car_driver, taxi_other, motorbike) %>% 
  mutate(all_vehs = car_driver + taxi_other + motorbike)

# Jittered OD pairs ------------------------------------------------------

min_distance_meters = 500
disag_threshold = 50
set.seed(42)

# why does this give more routing errors than using "data/osm_drive_2023-01-17.Rds"?
osm_drive = osmextract::oe_read("OTP/graphs/tyne-and-wear/north-east.osm.pbf")

od_drive_jittered = odjitter::jitter(
  od = lines_drive,
  zones = wider_northeast,
  zone_name_key = "geo_code",
  subpoints = osm_drive,
  disaggregation_threshold = disag_threshold,
  disaggregation_key = "all_vehs",
  min_distance_meters = min_distance_meters
) 

saveRDS(od_drive_jittered, "data/od_drive_jittered.Rds")

# Figure 1
od_jit = readRDS("data/od_drive_jittered.Rds")
od_jit = od_jit %>% 
  arrange(-all_vehs) %>% 
  slice_head(n = 1000) %>% 
  arrange(all_vehs) %>% 
  rename(`Jittered trips` = all_vehs)
tm_shape(od_jit) + tm_lines("Jittered trips")

# Now do the routing in OTP using code/otp.R


# Route networks ----------------------------------------------------------

routes_drive_otp = readRDS("data/routes_drive_otp_3_counties.Rds")

car_rnet = overline(
  routes_drive_otp, 
  # attrib = c("car_driver", "motorbike", "taxi_other")
  attrib = "all_vehs",
  regionalise = 1e+07
  )
car_rnet = tibble::rowid_to_column(car_rnet, "ID")

saveRDS(car_rnet, "data/drive_rnet_jittered.Rds")

# tm_shape(car_rnet) + 
#   tm_lines("all_vehs", 
#            breaks = c(0, 500, 1000, 2000, 5000, 15000))


# UO coordinates ----------------------------------------------------------

# Need to find out whether some sensor locations are double-counted

# It includes all vehicles eg van / bus / HGV / taxi / motorbikes


# Validation --------------------------------------------------------------

car_rnet = readRDS("data/drive_rnet_jittered.Rds")
in_sum = readRDS("data/plates_in_stats_2021_2.Rds")

period = readRDS("data/plates_in_2021_2.Rds")
days_in_period = length(unique(period$day))

# For Figure 2
inn = in_sum %>% 
  mutate(`Mean daily plates in` = sum_plates/days_in_period)
map_net = car_rnet %>% 
  mutate(`Commute route network` = all_vehs) %>% 
  arrange(all_vehs) # so the high flow routes are plotted on top
# tm_shape(map_net) + tm_lines("Commute route network", 
#                              breaks = c(0, 500, 1000, 2000, 5000, 15000))

# Figure 2
tm_shape(map_net) + 
  tm_lines("Commute route network", 
           breaks = c(0, 500, 1000, 2000, 5000, 15000), lwd = 1.3) + 
  tm_shape(inn) + tm_dots("Mean daily plates in", size = 0.08, palette = "-magma")

# Join rnet with UO counts 

# Plates In
# Should find a way of removing residential/unclassified/service roads, these will be false matches

rnet_refs = st_nearest_feature(x = in_sum, y = car_rnet)
rnet_feats = car_rnet[rnet_refs, ]
rnet_joined = cbind(rnet_feats, in_sum)

# tm_shape(rnet_feats) + tm_lines("all_vehs", lwd = 3) +
#   tm_shape(in_sum) + tm_dots("sum_plates")

m1 = lm(sum_plates ~ all_vehs, data = rnet_joined)
summary(m1)
summary(m1)$r.squared
# Feb:
# [1] 0.326276 # plates in sum uncorrected (the normal one)

# [1] 0.3238171 # plates in sum corrected by removing extreme outliers in traffic volumes
# Jan:
# [1] 0.05131899 # car count mean
# [1] 0.2714064 # plates in mean
# [1] 0.2716468 # plates in sum

# Figure 3
ggplot(rnet_joined, aes(all_vehs, sum_plates/days_in_period)) + 
  geom_point() + 
  labs(y = "ANPR daily mean vehicles Feb 2021", x = "2011 Census car driver/taxi/motorbike/other commutes") +
  geom_smooth(method = "lm", se = FALSE, lty = "dashed") +
  expand_limits(y = 0, x = c(0, 12500)) # watch - done because 12000 label was going outside the graph area


# Map Fig 3 residuals -----------------------------------------------------

rnet_resid = rnet_joined %>% 
  mutate(residuals = residuals(m1),
         fitted = fitted.values(m1))

# Negative residuals mean the ANPR counts are lower than the fitted value from the model with the Census rnet, positive residuals mean the ANPR counts are higher than the fitted value
# The greatest residuals are often related to dual carriageways where the rnet has much greater traffic flows in one direction than the other
tm_shape(rnet_resid) + 
  tm_lines("all_vehs", lwd = 3) + 
  tm_dots("residuals", size = 0.08, 
          breaks = c(-300000, -150000, -50000, 0, 50000, 150000, 300000),
          palette = "RdYlGn")
