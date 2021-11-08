# Author: Julien Diot juliendiot@ut-biomet.org
# 2020
#
# Description:
# ui file of the app module: "marker effect estimation"

tabItem(tabName = "EffEst",
        # Inputs ----
        fluidRow(
          shinydashboard::box(
            width = 12,
            title = "Makers' effect Estimation",
            div(
              id = "dtaVizGenoFiles",
              class = "col-sm-6",
              h4("Genotype file:"),
              tags$ul(
                tags$li('Use the file downloaded from the Breeding game'),
                tags$li('".txt.gz" or ".txt"')
              ),
              fileInput("EffEstGenoFile", "Genotypes file:")
            ),
            div(
              id = "dtaVizGenoFiles",
              class = "col-sm-6",
              h4("Phenotypic file:"),
              tags$ul(
                tags$li('Use the file downloaded from the Breeding game'),
                tags$li('".txt.gz" or ".txt"')
              ),
              fileInput("EffEstPhenoFile", "Phenotypes file:")
            )
          )
        ),


        fluidRow(
          shinydashboard::box(
            width = 4,
            title = "Settings",
            div(title = "`method = \"GBLUP\"`: GBLUPによるマーカー効果の予測\n`method = \"glmnet\"`: リッジ回帰、LASSO回帰などによるマーカー効果の予測",
                selectInput("EffEstMethod", "Method", choices = c("GBLUP", "glmnet"))
            ),
            div(title = "`Y`（形質1・2）に対し複数形質モデルを使う (`TRUE`) か単形質モデルを使うか (`FALSE`)。",
                checkboxInput("EffEstMultiT", "MultiTrait", value = TRUE)
            ),
            div(title = "`alpha = 0`ならリッジ回帰、`alpha = 1`ならLASSO回帰、`0 < alpha < 1`なら Elastic net（リッジ回帰とLASSO回帰のいいとこ取り、`alpha`が小さいほどリッジに近い）",
                sliderInput("EffEstAlpha", "alpha",
                            min = 0,
                            max = 1,
                            step = 0.01,
                            value = 0)
            ),

            actionButton("EffEstRun", "Estimate marker effects !")

          ),
          # Outputs ----
          shinydashboard::box(
            width = 8,
            title = "Table",
            div(id = "EffEst_table",
                withSpinner(dataTableOutput("EffEstDT"), type = 3,
                            color.background = "#fff"),
                downloadButton("EffEstDwnld", "Download")
            )
          )
        )

)
