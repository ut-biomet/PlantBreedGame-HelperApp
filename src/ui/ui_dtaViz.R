# Author: Julien Diot juliendiot@ut-biomet.org
# 2020
#
# Description:
# ui file of the app module: "data vizualisation"

tabItem(tabName = "dtaViz",
        # Inputs ----
        fluidRow(
          shinydashboard::box(
            width = 12,
            title = "Data Visualisation",
            div(
              id = "dtaVizGenoFiles",
              class = "col-sm-6",
              h4("Genotype file:"),
              tags$ul(
                tags$li('Use the file downloaded from the Breeding game'),
                tags$li('".txt.gz" or ".txt"')
              ),
              fileInput("dtaVizGenoFile", "Genotypes file:")
            ),
            div(
              id = "dtaVizMarkerFiles",
              class = "col-sm-6",
              h4("Markers weight file:"),
              tags$ul(
                tags$li('Use the file downloaded from the menu "Marker effect estimation"'),
                tags$li('".csv"')
              ),
              fileInput("dtaVizMakerFile", "Markers weight file:", accept = ".csv")
            )
          )
        ),




        # Outputs ----
        fluidRow(
          shinydashboard::box(
            width = 6,
            title = "Graph",
            div(id = "dtaViz_plots",
            plotlyOutput("dtaVizPlot")
            )
          ),
          shinydashboard::box(
            width = 6,
            title = "Table",
            div(id = "dtaViz_table",
                p("You can click on some individuals to highlight them on the plot."),
                dataTableOutput("dtaVizDT"),
                downloadButton("dtaVizDwnld", "Download")
            )
          )
        )

)
