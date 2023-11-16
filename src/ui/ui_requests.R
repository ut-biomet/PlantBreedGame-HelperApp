# Author: Julien Diot juliendiot@ut-biomet.org
# 2020
#
# Description:
# ui file of the app module: "requests"

tabItem(tabName = "requests",
        # Inputs ----
        fluidRow(
          shinydashboard::box(
            width = 12,
            title = "Create Breeding Game's requests",
            div(
              id = "requestDesc",
              class = "",
              h3("Input file:"),
              tags$ul(
                      tags$li('".txt" file with tabulation as separator'),
                      tags$li('3 columns: "parent1", "parent2", "n_progeny"'),
                      tags$li(paste('Max total number of progenies:', MAX_G1,
                                    "for G1,", MAX_INDS, "for others."))
              )
            ),

            div(
              id = "requestInput",
              class = "",
              width = "20%",
              selectInput("prefix", "Generation",
                          paste0("G", seq(MAX_GEN))),
              fileInput("reqFile", "Request file:")
            )
          )
        ),




        # Outputs ----
        fluidRow(
          shinydashboard::box(
            width = 4,
            title = "Input",
            div(id = "req_inputMsg",
                uiOutput("reqInfoMsg1")),
            # div(id = "req_inputDT",
                dataTableOutput("reqDtaInput")
            # )
          ),
          shinydashboard::box(
            width = 4,
            title = "Plant material Request",
            div(id = "req_pltMatMsg",
                uiOutput("reqInfoMsg2")),
            div(id = "req_pltMatDT",
                dataTableOutput("reqPltMatReq")
            )
          ),
          shinydashboard::box(
            width = 4,
            title = "Genotyping Request",
            div(id = "req_genoMsg",
                uiOutput("reqInfoMsg3")),
            div(id = "req_genoDT",
                dataTableOutput("reqGenoReq")
            )
          ),
          shinydashboard::box(
            width = 12,
            title = "Download",
            id = "req_dwnld",
            style = "text-align: center;",#display: none;",
            downloadButton("dwnldReq", "Download your requests",
                           style = paste0("color: #fff;",
                                          "background-color: #25BD20;",
                                          "border-color: #32D62F;"))
          )
        )

)
