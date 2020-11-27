## code to prepare `stations` dataset goes here

usethis::use_data(stations, overwrite = TRUE)

stations <- httr::GET("https://gbfs.urbansharing.com/bergenbysykkel.no/station_information.json")
jsonlite::fromJSON(httr::content(stations, type = "text"))$data %>% 
  as.data.frame() %>% 
  write_rds("predict_duration/stations.RDS")
