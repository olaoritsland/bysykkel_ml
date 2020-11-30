

library(plumber)

plumb("predict_duration/plumber.R")$run(host='0.0.0.0', port=80)
