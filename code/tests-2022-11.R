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

people_group = people_count_jan %>%
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

first = people_count_jan %>% 
  filter(Timestamp < "2021-01-01 00:01:00")