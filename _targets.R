
# setup -------------------------------------------------------------------

library(targets)
# remotes::install_github("itsleeds/dfttrafficcounts")
# library(tidyverse)
# library(sf)
# # source("R/functions.R")
# library(tmap)
# tmap_mode("view")
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
  tar_target(car_count_2021, {
    # hourly aggregated
    car_count_2021 = read_csv("data/uo-newcastle/2021-3600-Car Count.csv")
    # 207 sensors, 4000-8000 hours of data each (8760hrs in a yr)
    # car_count_2021 %>% 
    #   group_by(`Sensor Name`) %>% 
    #   summarise(n = n())
    car_count_2021 = st_as_sf(car_count_2021, wkt = "Location (WKT)")
  }),
  # The linestring WKT geometries are not being shown correctly in the csv files
  # this needs editing by hand or new code
  tar_target(plates_match_2021, {
    # hourly aggregated
    plates_match_2021 = read_csv("data/uo-newcastle/2021-day-Plates Matching.csv")
    # 311 sensors, around 100-360 days of data each 
    # plates_match_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    plates_match_2021 = st_as_sf(plates_match_2021, wkt = "Location (WKT)")  
  }),
  tar_target(traffic_flow_2021, {
    # hourly aggregated
    traffic_flow_2021 = read_csv("data/uo-newcastle/2021-86400-Traffic Flow.csv")
    # there is only data for a small area around the Metro Centre
    # traffic_flow_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    traffic_flow_2021 = st_as_sf(traffic_flow_2021, wkt = "Location (WKT)")
  }),
  tar_target(people_count_2021, {
    # hourly aggregated
    people_count_2021 = read_csv("data/uo-newcastle/2021-3600-People Count.csv")
    # 205 sensors, ~1500 hours of data each (8760hrs in a yr)
    # people_count_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    people_count_2021 = st_as_sf(people_count_2021, wkt = "Location (WKT)")
  }),
  tar_target(walking_2021, {
    # hourly aggregated
    walking_2021 = read_csv("data/uo-newcastle/2021-3600-Walking.csv")
    # 74 sensors, 6000-8000 hours of data each (8760hrs in a yr)
    # walking_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    walking_2021 = st_as_sf(walking_2021, wkt = "Location (WKT)")
  }),
  tar_target(cycling_2021, {
    # hourly aggregated
    cycling_2021 = read_csv("data/uo-newcastle/2021-86400-Cycle Count.csv")
    # 205 sensors, 71-72 days of data each 
    # cycling_2021 %>%
    #   group_by(`Sensor Name`) %>%
    #   summarise(n = n())
    cycling_2021 = st_as_sf(cycling_2021, wkt = "Location (WKT)")
  })
)

# car_group = car_count_2021 %>%
#   group_by(`Sensor Name`) %>%
#   summarise(n = n())
# tm_shape(car_group) + tm_dots()

# plate_group = plates_match_2021 %>%
#   group_by(`Sensor Name`) %>%
#   summarise(n = n())
# tm_shape(plate_group) + tm_lines()

traffic_flow = traffic_flow_2021 %>%
  group_by(`Sensor Name`) %>%
  summarise(n = n())
tm_shape(traffic_flow) + tm_lines()

people_group = people_count_2021 %>%
  group_by(`Sensor Name`) %>%
  summarise(n = n())
tm_shape(people_group) + tm_dots()

# most of the walking count points are around a single square in central Newcastle
walking_group = walking_2021 %>%
  group_by(`Sensor Name`) %>%
  summarise(n = n())
tm_shape(walking_group) + tm_dots()

cycling_group = cycling_2021 %>%
  group_by(`Sensor Name`) %>%
  summarise(n = n())
tm_shape(cycling_group) + tm_dots()
