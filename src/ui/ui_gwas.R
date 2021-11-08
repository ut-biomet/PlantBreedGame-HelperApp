# Author: Julien Diot juliendiot@ut-biomet.org
# 2020
#
# Description:
# ui file of the app module: "GWAS"


tabItem(tabName = "gwas",
        # Inputs ----
        fluidRow(
          shinydashboard::box(
            width = 12,
            title = "GWAS",
          tabPanel(
          "GWAS",
          tabsetPanel(
            id = "tabGWAS",
            # selected = 1,
            type = "tabs",

            ##### Data import ####
            tabPanel("Data importation",
                     value = 1,
                     fluidRow(
                       div(
                         class = "col-sm-12 col-md-12 col-lg-12",

                         # Pheno data
                         div(
                           class = "col-sm-12 col-md-6 col-lg-6",
                           h4("Phenotypic data", style = "text-align: center;"),
                           p(tags$ul(
                             tags$li(
                               "The file should be in",
                               code(".txt"),
                               "format with",
                               strong("tabulations"),
                               "separator and ",
                               strong(code("UTF-8"), "encoding"),
                               br(),
                               "or a file directly downloaded from the app (in",
                               code(".txt.gz"),
                               "format)."
                             ),
                             tags$li(
                               "The file must contain a",
                               code("ind"),
                               "colunm and at least one column between",
                               code("trait1"),
                               ",",
                               code("trait2"),
                               "or",
                               code("trait3"),
                               "."
                             ),
                             tags$li(
                               "The file must contain less than",
                               strong(MAX_OBS_GWAS),
                               "obeservations."
                             )
                           )),
                           fileInput("gwas_phenoFile", "Phenotypic data file"),
                           h5("Summary:"),
                           verbatimTextOutput("stat_sumPheno") %>% withSpinner(
                             type = 4,
                             size = 0.5,
                             proxy.height = "50px"
                           )
                         ),

                         # Geno data
                         div(
                           class = "col-sm-12 col-md-6 col-lg-6",
                           h4("Genotypic data", style = "text-align: center;"),
                           p(tags$ul(
                             tags$li(
                               "The file should be in",
                               code(".txt"),
                               "format with",
                               strong("tabulations"),
                               "separator and ",
                               strong(code("UTF-8"), "encoding"),
                               br(),
                               "or a file directly downloaded from the app (in",
                               code(".txt.gz"),
                               "format)."
                             ),
                             tags$li(
                               "The first line must be the names of the markers and the first columns must be the names of the individuals."
                             ),
                             tags$li(
                               "Only common individuals with the phenotypic data will be considered."
                             )
                           )),
                           fileInput("gwas_genoFile", "Genotypic data file"),
                           h5("Summary:"),
                           verbatimTextOutput("stat_sumGeno") %>% withSpinner(
                             type = 4,
                             size = 0.5,
                             proxy.height = "50px"
                           )
                         ),

                         # global summary
                         div(class = "col-sm-12 col-md-12 col-lg-12",
                             verbatimTextOutput("stat_sumGlobal"))
                       ),
                       div(
                         class = "col-sm-12 col-md-12 col-lg-12",
                         style = "text-align: center;",
                         uiOutput("stat_gwasNextButtonUI")
                       )
                     )),




            ##### Model parameters and outputs ####
            tabPanel("Model parameters and results",
                     value = 2,
                     fluidRow(
                       div(
                         class = "col-sm-12 col-md-4 col-lg-4",
                         div(
                           class = "col-sm-12 col-md-12 col-lg-12",
                           div(
                             class = "col-sm-12 col-md-12 col-lg-9",
                             # h4("Variable to explain"),
                             uiOutput("stat_gwasVarUI"),

                             # h4("Fixed effects"),
                             uiOutput("stat_gwasFixedUI")
                           ),
                           div(class = "col-sm-12 col-md-12 col-lg-3",
                               div(
                                 style = "min-width: 80px;",
                                 numericInput(
                                   "stat_gwasAlpha",
                                   label = "\\(\\alpha\\)",
                                   value = 0.05,
                                   min = 1e-9,
                                   max = 1,
                                   step = 0.01
                                 )
                               ))
                         ),
                         div(class = "col-sm-12 col-md-12 col-lg-12",
                             # actionButton("stat_calcGwasButton", "Calculation",
                             #              icon("play-circle"),
                             #              style = "background-color:green; color: white;")
                             uiOutput("stat_gwasCalcButtonUI"))

                       ),

                       div(class = "col-sm-12 col-md-8 col-lg-8",
                           plotlyOutput("gwas_plot") %>% withSpinner(type = 4))
                     ))
          )
          )
          )
        )
)
