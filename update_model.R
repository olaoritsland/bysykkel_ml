# Script to create and update model
library(bysykkel)
library(tidyverse)
library(tidymodels)
library(lubridate)

# Collect data from june to current month
cur_month <- lubridate::month(today() - 1)
bergen_trips <- map_dfr(9:cur_month, fread_trips_data, year = 2020, city = "Bergen")

trips <- bergen_trips %>% 
  mutate(hour_started = as.factor(hour(started_at))) %>% 
  mutate(started_at = as_date(started_at)) %>% 
  mutate(
    distance = round(geosphere::distCosine(
      cbind(start_station_longitude, start_station_latitude),
      cbind(end_station_longitude, end_station_latitude))),
    started_at_dow = as.factor(wday(started_at)), 
    start_station_id = as.factor(start_station_id), 
    end_station_id = as.factor(end_station_id))

split <- initial_split(trips)
train <- training(split)
test <- testing(split)

model <- boost_tree(mode = "regression", 
                    trees = 50,
                    learn_rate = 0.05,
                    tree_depth = 8, 
                    min_n = 1, 
                    sample_size = 0.8) %>%
  set_engine("xgboost") %>%
  fit(duration ~ 
        start_station_id
      + end_station_id
      + hour_started
      + distance
      + started_at_dow,
      data = train)

# Save model
readr::write_rds(model, "predict_duration/bysykkel_modell.rds")


# Validate model
mod_test <- test %>% 
  mutate(pred = predict(model, new_data = .) %>% pull())

multi_metric <- yardstick::metric_set(rsq, ccc, mape, rmse)

res <- mod_test %>% 
  multi_metric(truth = duration, estimate = pred)

# Save results
readr::write_csv(res, "model_results.csv")