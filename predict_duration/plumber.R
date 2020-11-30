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

# Function that fixes data
fix_features <- function(data) {
    data %>%
        transmute(
            start_station_id = as.factor(start_station_id),
            end_station_id = as.factor(end_station_id),
            hour_started = as.factor(hour_started),
            started_at = as_date(started_at),
            started_at_dow = as.factor(wday(started_at))
        ) %>%
        left_join(stations, by = c("start_station_id" = "stations.station_id")) %>%
        left_join(
            stations,
            by = c("end_station_id" = "stations.station_id"),
            suffix = c("_start", "_end")
        ) %>%
        mutate(distance = round(geosphere::distCosine(
            cbind(stations.lon_start, stations.lat_start),
            cbind(stations.lon_end, stations.lat_end)
        ))) %>%
        select(start_station_id,
               end_station_id,
               hour_started,
               distance,
               started_at_dow)
}

#* @apiTitle Predict duration
#* Predict duration of a bike ride
#* @param body JSON-body with data
#* @post /predict
function(req, res = NULL) {
    input <- tibble::as_tibble(req$body)    
    df <- fix_features(input)
    pred <- predict(model, df)
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

# Vi kan også lage et GET-API, som er enklere å teste fra browseren
# Merk: Vanligvis brukes POST-API i denne konteksten, 
# spesielt for mer kompliserte use-cases

#* @apiTitle Predict duration
#* Predict duration of a bike ride
#* @param start_station_id
#* @param end_station_id
#* @param hour_started
#* @param started_at
#* @get /predict
function(start_station_id, end_station_id, hour_started, started_at) {

    input <- tibble(
        start_station_id = start_station_id,
        end_station_id = end_station_id,
        hour_started =  hour_started,
        started_at = started_at
    )
    
    df <- fix_features(input)
    
    pred <- predict(model, df)
    pred
}

