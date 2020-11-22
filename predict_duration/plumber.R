#
# This is a Plumber API. You can run the API by clicking
# the 'Run API' button above.
#
# Find out more about building APIs with Plumber here:
#
#    https://www.rplumber.io/
#

library(plumber)
library(tidymodels)
library(recipes)

model <- read_rds("bysykkel_modell.rds")
recipe <- read_rds("bysykkel_recipe.rds")

#* @apiTitle Predict duration
#* Predict duration of a bike ride
#* @param body JSON-body with data
#* @post /predict
function(body = "") {
    df <- jsonlite::fromJSON(body)
    df <- bake(recipe, new_data = df)
    
    pred <- predict(model, new_data = df) %>% pull()
    pred
}