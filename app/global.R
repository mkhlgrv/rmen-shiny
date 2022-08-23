# Sys.setenv("directory"="./data")

# library(rmen)
library(ggplot2)
library(dplyr)


prediction_table_full <- read.table("nowcast_old.csv", header = TRUE, sep=","
                                    , colClasses = c("character", "integer", "character", "character", "Date", "numeric", "numeric", "Date"))
prediction_table_full <- dplyr::inner_join(prediction_table_full,
                                           rmedb::get.variables.df(),
                  by = c("target"="ticker"))[,
                                             c("method", "horizon", "name_rus_short", "target", "predictor_group"
                                               , "date", "y_pred", "y_test", "forecast_date")]
models <-  unique(prediction_table_full[,c("method", "target","name_rus_short","predictor_group")])
