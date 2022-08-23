# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("ML наукаст"),


    fluidRow(
      column(4, DT::dataTableOutput('models'), downloadButton('downloadData', 'Загрузить', icon = shiny::icon("download"))),

      column(7, plotOutput('plot'))
    )
)
