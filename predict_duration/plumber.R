#
# This is a Plumber API. You can run the API by clicking
# the 'Run API' button above.
#
# Find out more about building APIs with Plumber here:
#
#    https://www.rplumber.io/
#

# library(plumber)
library(tidymodels)
library(recipes)

model <- readr::read_rds("./bysykkel_modell.rds")
recipe <- readr::read_rds("./bysykkel_recipe.rds")

#* @apiTitle Predict duration
#* Predict duration of a bike ride
#* @param body JSON-body with data
#* @post /predict
function(req, res = NULL) {
    df <- tibble::as_tibble(req$body)
    # df <- bake(recipe, new_data = df)
    
    pred <- predict(model, df)
    pred
}

# #* @plumber
# function(pr) {
#     pr %>%
#         pr_set_api_spec(yaml::read_yaml("openapi.yaml"))
# }

#* @get /okay
function() {
    "I'm alive!"
}
