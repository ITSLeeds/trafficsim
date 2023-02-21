library(tidyverse)
library(tmap)
tmap_mode("view")

# pm10_grouped = readRDS("data/pm10_grouped_2021_1.Rds")
# View(pm10_grouped)
# tm_shape(pm10_grouped) + tm_dots("median_value")


tm_shape(sensor_stats) + tm_dots("median_value")



# Checking extreme values -------------------------------------------------

per = sensor_sd %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1913150")

ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  geom_point()

per = sensor_sd %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1976150")

ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  geom_point()

per = sensor_sd %>% 
  filter(`Sensor Name` == "PER_AIRMON_MESH1762150")

ggplot(per, aes(x = Timestamp, y = Value)) +
  geom_line() + 
  geom_point()


