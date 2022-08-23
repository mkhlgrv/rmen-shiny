# TODO
# Обучить модели
# Определить, что делать при пропуске в данных
# при пропуске обучение новой модели
# Статистика по модели rmse (в таблице? на новом рисунке?)
# в таблицу добавить переменные? или сразу по клику на модель показывать все переменные
# Скачать прогноз, список использованных переменных
# пересчет моделей раз в неделю
# идеи отображать все прогнозы сразу

# Ключевой элемент - получить из скаченной базы данных актуальные

Sys.setenv("directory"="./data")
Sys.setenv("fredr_api_key"="b3253be67e9b6d9dfc03967a568b820f")
Sys.setenv("log_file"="current_log.log")

setwd("predict")
library(rmedb)
rmedb::download(sources = c("rosstat", "fred", "moex"))

back_horizon <- 2
max_lag <- 2
targets <- jsonlite::fromJSON(readLines("target.json"),simplifyDataFrame = FALSE,
                              simplifyVector = TRUE)

methods <- jsonlite::fromJSON(readLines("method.json"),simplifyDataFrame = FALSE,
                              simplifyVector = TRUE)

predictor_groups <-jsonlite::fromJSON(readLines("predictor_group.json"),simplifyDataFrame = FALSE,
                                      simplifyVector = TRUE)

# file.remove("nowcast.csv")

if(!file.exists("nowcast.csv")){
  cat(c("method","horizon","target","predictor_group", "date", "y_pred","y_test","forecast_date")
      , sep=",", file = "nowcast.csv")
  cat("\n", file = "nowcast.csv", append = TRUE)
}


grid <- expand.grid(targets = targets
                    , methods= methods
                    , predictor_groups = predictor_groups
                    , stringsAsFactors = FALSE)

for (i in 1:nrow(grid)){
  target <- grid[i,1]
  method <-  grid[i,2]

  predictor_group <-  grid[i,3]

  if(predictor_group=="all"){
    df <- rmedb::get.variables.df()
  } else{
    df <- dplyr::inner_join(rmedb::get.variables.df()
                            , rmedb::additional_info[,c("ticker", "group")]
                            , by = "ticker")[group %in% predictor_group,]
  }

  forecast_date <- rmedb:::get.next.weekday(Sys.Date(),day = 'Пт',-1)


  predictors <- 1:nrow(df) %>% lapply(function(i){


    ticker <-  df[i,ticker]
    deseason <- df[i,deseason]
    freq <- df[i,freq]


    filei <-  paste0(Sys.getenv("directory"),"/data/tf/", ticker, ".csv")
    if(file.exists(filei)){

      # проверяем что в предикторе нет пропусков
      dates <- data.table::fread(file=filei, select = c("date"))[,date]
      start_date_i <- ifelse(deseason=="level", '2007-01-01', '2006-01-01')
      as_year_period_i <- ifelse(freq=="q", zoo::as.yearqtr, zoo::as.yearmon)
      numenator_i <- ifelse(freq=="q", 4, 12)
      if(!all(seq.Date(as.Date(start_date_i), zoo::as.Date(as_year_period_i(forecast_date)-4/numenator_i), by = freq) %in% dates)){
        return(NULL)
      }


      # определяем порядок допустимого лага
      last_date <- max(data.table::fread(file=filei, select = c("date"))[,date])
      if(lubridate::is.Date(last_date)){
        if(freq=="q"){
          first_lag <- (zoo::as.yearqtr(forecast_date) -zoo::as.yearqtr(last_date))*4

        } else if(freq=="m"){
          first_lag <- (zoo::as.yearmon(forecast_date) - zoo::as.yearmon(last_date))*12

        }else if (freq %in% c("w", "d")){
          first_lag <- as.numeric(forecast_date - rmedb:::get.next.weekday(last_date,day = 'Пт',-1))/7

        }
        if(first_lag>max_lag){
          return(NULL)
        } else{
          lags <- as.integer(first_lag):max_lag
        }
        list(ticker = ticker,deseason = deseason, lag = lags)
      }

    }
    else{
      return(NULL)
    }
  }) %>% purrr::compact()
  ticker_info <- rmedb::get.variables.df()[ticker==target,]

  if(ticker_info[,freq]=="q"){
    test_start_date = zoo::as.yearmon(forecast_date) - back_horizon/4
  } else if(ticker_info[,freq]=="m"){
    test_start_date = zoo::as.yearmon(forecast_date) - back_horizon/12
  }


  test_start_date <- zoo::as.Date(test_start_date)


  tryCatch({
    nowcast_obj <- new("nowcast", target = target,name="" ,start_date="2007-01-01", horizon=1L
                       , oos_test= TRUE, test_start_date=test_start_date
                       , target_deseason=ticker_info[,deseason]
                       ,predictors=predictors, methods=method)
    nowcast_obj_fit <- nowcast_obj %>%
      rmen::collect.data()
    nowcast_obj_fit <- nowcast_obj_fit%>%
      rmen::fit()
  }, error=function(cond) {
    message("Here's the original error message:")
    message(cond)
  })

  if(nrow(nowcast_obj_fit@pred)==0){
    next
  } else{
    result <- nowcast_obj_fit@pred

    result[,"forecast_date"] <- forecast_date

    result[,"predictor_group"] <- predictor_group

    write.table(result[,c("method","horizon","target","predictor_group", "date", "y_pred","y_test","forecast_date")]
                ,file = "nowcast.csv",append=TRUE, row.names=FALSE
                , sep=","
                , col.names = FALSE)
  }


}


