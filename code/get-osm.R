library(tidyverse)
# Cycling -----------------------------------------------------------------

# Download osm data
et = c(
  "maxspeed",
  "oneway",
  "bicycle",
  "cycleway",
  "cycleway:left",
  "cycleway:right",
  "cycleway:both",
  "lanes",
  "sidewalk",
  "ref",
  "surface",
  "segregated",
  "route",           # for proposed routes
  "state",
  "lcn",
  "rcn",
  "ncn",
  "network"
)

# Read-in road network data
# box = sf::st_bbox(c(xmin = -1.2, xmax = 2.22, ymin = 54.73, ymax = 55.2))
osm_lines1 = osmextract::oe_get_network(
  place = "Tyne and Wear",
  mode = "cycling",
  extra_tags = et
  # , force_download = TRUE # keep it up-to date
)
osm_lines2 = osmextract::oe_get_network(
  place = "Northumberland",
  mode = "cycling",
  extra_tags = et
  # , force_download = TRUE # keep it up-to date
)
osm_lines3 = osmextract::oe_get_network(
  place = "Durham",
  mode = "cycling",
  extra_tags = et
  # , force_download = TRUE # keep it up-to date
)
osm_lines = bind_rows(osm_lines1, osm_lines2, osm_lines3)

# Simple exploratory analysis
osm_lines %>%
  filter(highway == "track") %>%
  sample_n(200) %>% 
  qtm()
osm_lines %>%
  filter(highway == "trunk") %>%
  sample_n(500) %>% 
  qtm()

unique(osm_lines$highway)
to_exclude = "motorway|motorway_link|services|bridleway|disused|emergency|escap|far|foot|path|pedestrian|rest|road|track"


osm_highways = osm_lines %>%
  filter(!str_detect(string = highway, pattern = to_exclude))


dim(osm_highways) 
# [1] 142142     30
saveRDS(osm_highways, "data/osm_cycle_2023-01-11.Rds") # 100 MB file


# Driving -----------------------------------------------------------------

# Download osm data
et = c(
  "maxspeed",
  "oneway",
  "lanes",
  "ref",
  "surface",
  "segregated",
  "state",
  "network"
)

# Read-in road network data
osm_lines1 = osmextract::oe_get_network(
  place = "Tyne and Wear",
  mode = "driving",
  extra_tags = et
  # , force_download = TRUE # keep it up-to date
)
osm_lines2 = osmextract::oe_get_network(
  place = "Northumberland",
  mode = "driving",
  extra_tags = et
  # , force_download = TRUE # keep it up-to date
)
osm_lines3 = osmextract::oe_get_network(
  place = "Durham",
  mode = "driving",
  extra_tags = et
  # , force_download = TRUE # keep it up-to date
)
osm_lines = bind_rows(osm_lines1, osm_lines2, osm_lines3)

# Simple exploratory analysis
osm_lines %>%
  filter(highway == "track") %>%
  sample_n(200) %>% 
  qtm()
osm_lines %>%
  filter(highway == "trunk") %>%
  sample_n(500) %>% 
  qtm()

unique(osm_lines$highway)
to_exclude = "services|bridleway|disused|emergency|escap|far|foot|path|pedestrian|rest|road|track|bus_guideway|raceway|busway|cycleway"

osm_highways = osm_lines %>%
  filter(!str_detect(string = highway, pattern = to_exclude))


dim(osm_highways) 
# [1] 138569    20

# tm_shape(osm_highways) + tm_lines()

saveRDS(osm_highways, "data/osm_drive_2023-01-17.Rds") # 12.6 MB file

# Walking -----------------------------------------------------------------

# Download osm data
et = c(
  "maxspeed",
  "lanes",
  "sidewalk",
  "ref",
  "surface",
  "segregated",
  "state"
)

# Read-in road network data
# box = sf::st_bbox(c(xmin = -1.2, xmax = 2.22, ymin = 54.73, ymax = 55.2))
osm_lines1 = osmextract::oe_get_network(
  place = "Tyne and Wear",
  mode = "walking",
  extra_tags = et
  # , force_download = TRUE # keep it up-to date
)
osm_lines2 = osmextract::oe_get_network(
  place = "Northumberland",
  mode = "walking",
  extra_tags = et
  # , force_download = TRUE # keep it up-to date
)
osm_lines3 = osmextract::oe_get_network(
  place = "Durham",
  mode = "walking",
  extra_tags = et
  # , force_download = TRUE # keep it up-to date
)
osm_lines = bind_rows(osm_lines1, osm_lines2, osm_lines3)

# Simple exploratory analysis
osm_lines %>%
  filter(highway == "track") %>%
  sample_n(200) %>% 
  qtm()
osm_lines %>%
  filter(highway == "trunk") %>%
  qtm()

unique(osm_lines$highway)
to_exclude = "motorway|motorway_link|disused|emergency|escap|far|bus_guideway|raceway|busway"

osm_highways = osm_lines %>%
  filter(!str_detect(string = highway, pattern = to_exclude))

dim(osm_highways) 
# [1] 216351     20
saveRDS(osm_highways, "data/osm_foot_2023-01-11.Rds") # 100 MB file

