
# newc_msoa = northeast %>% 
#   filter(lad_name == "Newcastle upon Tyne")
# tm_shape(newc_msoa) + tm_polygons() + 
#   tm_shape(pm10) + tm_dots()

# northeast_lsoa = get_pct_zones("north-east", geography = "lsoa")
# northeast_lsoa = st_make_valid(northeast_lsoa)
# tm_shape(northeast_lsoa) + tm_polygons()

# # Same with LSOAs ---------------------------------------------------------
# 
# # only 14 LSOAs match both datasets
# 
# join_lsoa = st_join(northeast_lsoa, pm10_osm) %>%
#   group_by(geo_code) %>%
#   summarise(mean_pm10 = mean(median_value)) %>%
#   filter(!is.na(mean_pm10))
# tm_shape(join_lsoa) + tm_polygons("mean_pm10")
# join_lsoa_traffic = st_join(join_lsoa, traffic_osm) %>%
#   group_by(geo_code, mean_pm10) %>%
#   summarise(mean_traffic = mean(sum_value)) %>%
#   filter(!is.na(mean_traffic))
# tm_shape(join_lsoa_traffic) + tm_polygons("mean_pm10")
# tm_shape(join_lsoa_traffic) + tm_polygons("mean_traffic")
# 
# ggplot(join_lsoa_traffic, aes(mean_traffic, mean_pm10)) + 
#   geom_point()
# m1 = lm(mean_pm10 ~ mean_traffic, data = join_lsoa_traffic)
# summary(m1)$r.squared
# # [1] 0.02452623


# Sensors on same road ----------------------------------------------------

# traffic_name_mean = traffic_osm %>% 
#   st_drop_geometry() %>% 
#   group_by(name) %>% 
#   summarise(mean_traffic = mean(sum_value)) %>% 
#   filter(! is.na(name))
# by_name = inner_join(pm10_missing, traffic_name_mean, by = "name")
# by_ref_name = bind_rows(by_ref, by_name)
# 
# ggplot(by_ref_name, aes(mean_traffic, median_value)) + 
#   geom_point()
# m1 = lm(median_value ~ mean_traffic, data = by_ref_name)
# summary(m1)$r.squared
# # [1] 0.0388554

# # Both MSOA and road ref
# join = st_join(northeast, pm10_missing) %>% 
#   group_by(geo_code) %>% 
#   summarise(mean_pm10 = mean(median_value)) %>% 
#   filter(!is.na(mean_pm10))
# tm_shape(join) + tm_polygons("mean_pm10")
# join_traffic = st_join(join, traffic_osm) %>% 
#   group_by(geo_code, mean_pm10) %>% 
#   summarise(mean_traffic = mean(sum_value)) %>% 
#   filter(!is.na(mean_traffic))
# tm_shape(join_traffic) + tm_polygons("mean_pm10") + 
#   tm_shape(pm10) + tm_dots("median_value")
# tm_shape(join_traffic) + tm_polygons("mean_pm10", alpha = 0.5) +
#   tm_shape(traffic) + tm_dots("sum_value", palette = "-magma") + 
#   tm_shape(pm10) + tm_bubbles("median_value")
# 
# ggplot(join_traffic, aes(mean_traffic, mean_pm10)) + 
#   geom_point()
# m1 = lm(mean_pm10 ~ mean_traffic, data = join_traffic)
# summary(m1)$r.squared
# # [1] 0.1479101
# 
# 
# # Sensors on same road type -----------------------------------------------
# 
# traffic_highway_mean = traffic_osm %>% 
#   st_drop_geometry() %>% 
#   group_by(highway) %>% 
#   summarise(mean_traffic = mean(sum_value)) %>% 
#   filter(! is.na(highway))
# pm10_highway_mean = pm10_osm %>% 
#   st_drop_geometry() %>% 
#   group_by(highway) %>% 
#   summarise(mean_pm10 = mean(median_value)) %>% 
#   filter(! is.na(highway))
# by_highway = inner_join(pm10_highway_mean, traffic_highway_mean, by = "highway")
# 
# ggplot(by_highway, aes(mean_traffic, mean_pm10)) + 
#   geom_point()
# m1 = lm(mean_pm10 ~ mean_traffic, data = by_highway)
# summary(m1)$r.squared
# # [1] 0.07241296
