server <- function(input, output) {

  output$models = DT::renderDataTable(models, server = FALSE
                                      , options=list(columnDefs = list(list(visible=FALSE, targets=c(2))))
                                      ,  colnames=c("Метод", "Целевая переменная (тикер)","Целевая переменная",  "Группа предикторов"))
  reactive_list <- reactiveValues()
  observe({
    if(!is.null(input$models_rows_selected)){
      reactive_list$prediction_table <-
        dplyr::inner_join(prediction_table_full
                          , models[input$models_rows_selected,]
                          , by = c("method", "target","predictor_group","name_rus_short"))
      }})

  output$downloadData <- downloadHandler(
      filename = function() {
        paste('ml_nowcast-', Sys.Date(), '.csv', sep='')
      },
      content = function(con) {
        write.csv(reactive_list$prediction_table, con)
      }
    )
    #
    # # In ui.R:
    #


  # highlight selected rows in the scatterplot
  output$plot = renderPlot({
    if(!is.null(reactive_list$prediction_table)){
      reactive_list$prediction_table %>%
        ggplot(aes(x = date))+
        geom_point(aes( y = y_test, color = "Факт"), size = 3, show.legend = FALSE)+
        geom_line(aes( y = y_test, color = "Факт"),  show.legend = FALSE)+
        # geom_point(aes( y = y_test, size = 2, alpha = 0.5), color = "black")+
        geom_line(aes(y = y_pred, color = interaction(method, predictor_group)),linetype=2,size=0.8)+
        facet_wrap(vars(name_rus_short), scales="free")+
        labs(x="Дата", y = "", color = "Метод, данные\n")+
        ylab("")+
        theme_bw()
    }

  })
}

