
<!-- README.md is generated from README.Rmd. Please edit that file -->

# trafficsim

<!-- badges: start -->
<!-- badges: end -->

The goal of trafficsim is to simulate traffic levels on the network
starting with OD data.

To set-up the project with {targets} we ran the following commands:

``` r
library(targets)
```

``` r
use_targets()
```

To visualise the project data processing stages run the following:

``` r
tar_visnetwork()
```

To re-run the code in this project, use the following command:

``` r
tar_make()
```

For debugging, it’s useful to be able to load an object from the
pipeline. Do this with `tar_load()`.

``` r
tar_load(clean_traffic_data)
clean_traffic_data
#> # A tibble: 5 × 35
#>   Count_point_id Direc…¹  Year Count_date           hour Regio…² Regio…³ Regio…⁴
#>            <dbl> <chr>   <dbl> <dttm>              <dbl>   <dbl> <chr>   <chr>  
#> 1          37778 S        2011 2011-06-07 00:00:00    11      10 West M… E12000…
#> 2          37778 S        2011 2011-06-07 00:00:00    12      10 West M… E12000…
#> 3          37778 S        2011 2011-06-07 00:00:00    13      10 West M… E12000…
#> 4          37778 S        2011 2011-06-07 00:00:00    14      10 West M… E12000…
#> 5          37778 S        2011 2011-06-07 00:00:00    15      10 West M… E12000…
#> # … with 27 more variables: Local_authority_id <dbl>,
#> #   Local_authority_name <chr>, Local_authority_code <chr>, Road_name <chr>,
#> #   Road_category <chr>, Road_type <chr>, Start_junction_road_name <chr>,
#> #   End_junction_road_name <chr>, Easting <dbl>, Northing <dbl>,
#> #   Latitude <dbl>, Longitude <dbl>, Link_length_km <dbl>,
#> #   Link_length_miles <dbl>, Pedal_cycles <dbl>,
#> #   Two_wheeled_motor_vehicles <dbl>, Cars_and_taxis <dbl>, …
```
