#
# This is a Plumber API. You can run the API by clicking
# the 'Run API' button above.
#
# Find out more about building APIs with Plumber here:
#
#    https://www.rplumber.io/
#

library(tidymodels)
library(recipes)
library(lubridate)

model <- readr::read_rds("bysykkel_modell.rds")
stations <- readr::read_rds("stations.RDS")

#* @apiTitle Predict duration
#* Predict duration of a bike ride
#* @param body JSON-body with data
#* @post /predict
function(req, res = NULL) {
    input <- tibble::as_tibble(req$body)
    # browser()
    df <- tibble(start_station_id = as.factor(input$start_station_id), 
                 end_station_id = as.factor(input$end_station_id), 
                 hour_started = as.factor(input$hour_started), 
                 started_at = input$started_at) %>% 
        mutate(started_at = as_date(started_at)) %>% 
        mutate(started_at_dow = as.factor(wday(started_at)))

    df1 <- df %>% 
        left_join(stations, by = c("start_station_id" = "stations.station_id")) %>% 
        left_join(stations, by = c("end_station_id" = "stations.station_id"), suffix = c("_start", "_end")) %>% 
        mutate(distance = round(geosphere::distCosine(
            cbind(stations.lon_start, stations.lat_start),
            cbind(stations.lon_end, stations.lat_end)))) %>% 
        select(start_station_id, end_station_id, hour_started, distance, started_at_dow)
    
    pred <- predict(model, df1)
    pred
}

# lag nytt api som gir stasjonsid

#* @apiTitle Predict duration
#* Predict duration of a bike ride
#* @param start_station_id
#* @param end_station_id
#* @param hour_started
#* @param started_at
#* @get /predict
function(start_station_id, end_station_id, hour_started, started_at) {
    # browser()
    df <- tibble(start_station_id = as.factor(start_station_id), 
                 end_station_id = as.factor(end_station_id), 
                 hour_started = as.factor(hour_started), 
                 started_at = as_date(started_at)) %>% 
        mutate(started_at_dow = as.factor(wday(started_at)))

    
    df1 <- df %>% 
        left_join(stations, by = c("start_station_id" = "stations.station_id")) %>% 
        left_join(stations, by = c("end_station_id" = "stations.station_id"), suffix = c("_start", "_end")) %>% 
        mutate(distance = round(geosphere::distCosine(
            cbind(stations.lon_start, stations.lat_start),
            cbind(stations.lon_end, stations.lat_end)))) %>% 
        select(start_station_id, end_station_id, hour_started, distance, started_at_dow)
    
    pred <- predict(model, df1)
    pred
}

#* @plumber
function(pr) {
    pr %>%
        pr_set_api_spec(yaml::read_yaml("openapi.yaml"))
}

#* @get /okay
function() {
    "I'm alive!"
}
