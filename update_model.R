# Script to create and update model
library(bysykkel)
library(tidyverse)
library(tidymodels)
library(lubridate)

# Collect data from june to current month
cur_month <- lubridate::month(today())
bergen_trips <- map_dfr(6:cur_month, fread_trips_data, year = 2020, city = "Bergen")

split <- initial_split(bergen_trips)
train <- training(split)
test <- testing(split)

# Create the recipe that specifies which operations we want to do.
rec <- recipe(duration ~ ., data = train) %>%
  step_mutate(started_at = lubridate::as_date(started_at)) %>% 
  step_date(started_at) %>%
  step_mutate(distance = round(geosphere::distCosine(
    cbind(start_station_longitude, start_station_latitude),
    cbind(end_station_longitude, end_station_latitude)
  ))) %>% 
  step_mutate(hour_started = hour(started_at)) %>%
  step_holiday(started_at)

# Train the recipe on the training set.
prep_rec <- prep(rec, training = train)

# Bake the data (i.e. apply the recipe and get the final datasets)
mod_train <- bake(prep_rec, new_data = train)
mod_test <- bake(prep_rec, new_data = test)

model <- boost_tree(mode = "regression", 
                    learn_rate = 0.3,
                    tree_depth = 12, 
                    min_n = 1, 
                    sample_size = 0.8) %>%
  set_engine("xgboost") %>%
  fit(duration ~ 
        start_station_id
      + end_station_id
      + hour_started
      + distance
      + started_at_dow
      + started_at_month,
      data = mod_train)

# Save model
readr::write_rds(model, "bysykkel_modell.rds")

# Validate model
mod_test <- mod_test %>% 
  mutate(pred = predict(model, new_data = .) %>% pull())

multi_metric <- yardstick::metric_set(rsq, ccc, mape, rmse)

res <- mod_test %>% 
  multi_metric(truth = duration, estimate = pred)

# Save results
readr::write_csv(res, "model_results.csv")