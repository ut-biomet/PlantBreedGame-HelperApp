# Author: Julien Diot juliendiot@ut-biomet.org
# 2020
#
# Description:
# ui file of the app module: "parent selection"

tabItem(tabName = "selectTools",
        # Inputs ----
        fluidRow(
          shinydashboard::box(
            width = 12,
            title = "Data Visualisation",
            div(
              id = "selectGenoFiles",
              class = "col-sm-6",
              h4("Genotype file:"),
              tags$ul(
                tags$li('Use the file downloaded from the Breeding game'),
                tags$li('".txt.gz" or ".txt"')
              ),
              fileInput("select_GenoFile", "Genotypes file:")
            ),
            div(
              id = "selectMarkerFiles",
              class = "col-sm-6",
              h4("Markers weight file:"),
              tags$ul(
                tags$li('Use the file downloaded from the menu "Marker effect estimation"'),
                tags$li('".csv"')
              ),
              fileInput("select_MakerFile", "Markers weight file:", accept = ".csv")
            )
          )
        ),




        # Outputs ----
        fluidRow(
          shinydashboard::tabBox(
            width = 12,
            # title = "",
            # Parents selection ----
            tabPanel("Parents selection",
                     fluidRow(
                       div(id = "clust_input",
                           class = "col-sm-2",
                           div(title="遺伝的距離に基づくクラスタの数。`nCluster`個のクラスタそれぞれで上位の系統を調べる。",
                               numericInput("n_clust", label = "N cluster",
                                            value = 5, min = 1, max = 300,
                                            step = 1)
                           ),
                           div(title="どの形質に基づいて選抜するか。数字で指定。1:2などとすれば、形質1×形質2を目標値にする。形質1・形質2の選抜を別々に1回ずつやって両者の結果を総合するやり方もあり？",
                               selectInput("trait_clust", "Trait",
                                           choices = c("Trait1", "Trait2", "Trait3", "Trait1 x Trait2"))
                           ),
                           div(title="`nCluster`個のクラスタのうち、各クラスタの上位`nTopEach`系統の平均値の上位`topCluster`個のクラスタから、親候補を選ぶ。（`nCluster >= topCluster` を満たす必要あり）",
                               numericInput("top_clust", label = "Top Cluster",
                                            value = 5, min = 1, max = 300,
                                            step = 1)
                           ),
                           div(title="各クラスタの上位何系統を親の候補とするか",
                               numericInput("nTopEach_clust", label = "nTopEach",
                                            value = 1, min = 1, max = 300,
                                            step = 1)
                           ),
                           div(title="何系統まで親候補に耐病性をもたない系統を許すか。",
                               numericInput("nMaxT3_clust", label = "nMaxDisease",
                                            value = 20, min = 1, max = 300,
                                            step = 1)
                           ),
                           div(title="多くとも上位何系統まで親候補として選抜するか。",
                               numericInput("nTop_clust", label = "nTop",
                                            value = 20, min = 1, max = 300,
                                            step = 1)
                           ),
                           actionButton("clust_autoSelect", "Select individuals"),
                           actionButton("clust_clear", "Clear", icon = icon("broom")),
                           downloadButton("selectDwnld", "Download")
                       ),
                       shinydashboard::tabBox(
                         width = 10,
                         tabPanel("Tables",
                                  dataTableOutput("selectDT")
                         ),
                         tabPanel("Clusters",
                                  withSpinner(plotlyOutput("clust_clustPlot",
                                                           height = "500px"),
                                              type = 3,
                                              color.background = "#fff")
                         ),
                         tabPanel("Plot",
                                  withSpinner(plotlyOutput("clust_t1t2Plot",
                                                           height = "500px"),
                                              type = 3,
                                              color.background = "#fff")
                         )

                       )
                     )

            ),







            # mating ----
            tabPanel("Mating",
                     fluidRow(
                             div(id = "clust_input",
                                 class = "col-sm-2",
                                 div(title = paste0("交配親のペアを作る手法。以下の3つから選択\n",
                                                  "round-robin : 親を無作為に並び替え、1番目の親を2番目、...、n-1番目をn番目、n番目を1番目の親と交配。\n",
                                                  "max-distance : 最も遺伝的距離が遠い親候補の系統同士を交配親の組とする。\n",
                                                  "all-combination : 親候補の系統間の全ての組合せを交配親の組とする。"),
                                     selectInput("mateMethod_mate", "Mating Method",
                                                 choices = c("round-robin",
                                                             "max-distance",
                                                             "all-combination",
                                                             "autofecundation"))
                                 ),
                                 div(title="TRUEなら全ての親候補の系統を自殖させる。",
                                     checkboxInput("includeSelfing", "Include Selfing", value = FALSE),
                                 ),
                                 div(title="TRUEなら耐病性をもたない系統同士から交配親の組を除外する。",
                                     checkboxInput("removeDxD", "Remove D x D", value = FALSE),
                                 ),
                                 div(title = paste0("各交配組にどうやって次世代個体数を割り振るか。以下の2つから選択。\n",
                                                  "equal : 各交配組に等しい次世代個体数を割り当てる。\n",
                                                  "weighted : 各交配組の目標値の大きさに応じて次世代個体数を割り当てる。"),
                                     selectInput("allocateMethod", "Allocation Method",
                                                 choices = c("equal", "weighted"))
                                 ),
                                 div(title="allocateMethod = \"weighted\"の時、にどの形質に基づいて重み付けるか。数字で指定。1:2などとすれば、形質1×形質2を目標値にして重み付け。",
                                     selectInput("trait_mate", "Trait",
                                                 choices = c("Trait1", "Trait2", "Trait3", "Trait1 x Trait2"))
                                 ),
                                 div(title = "allocateMethod = \"weighted\"の時に、各交配組の目標値の大きさに対して、次世代個体数をにどの程度重みをつけるか。`h`が大きいほど、目標値の差に対して重み付けを大きくする。",
                                     sliderInput("h_mate", "h", min = 0, max = 2, value = 0.1, step = 0.01)
                                 ),
                                 div(title = "",
                                     selectInput("currentPop", "Current population",
                                                 choices = paste0("G", 0:4))
                                 ),
                                 div(title = "",
                                     numericInput("nNew", "Number of offsprings",
                                                 value = 20, min = 1, max = 300)
                                 ),
                                 actionButton("mate_btn", "Mate"),
                                 # actionButton("clust_clear", "Clear", icon = icon("broom")),
                                 downloadButton("mateDwnld", "Download")
                             ),

                             shinydashboard::tabBox(
                                     width = 10,
                                     tabPanel("Crossing Tables",
                                              dataTableOutput("crossTableDT")
                                     ),
                                     tabPanel("Plot",
                                              withSpinner(plotlyOutput("mate_plot",
                                                                       height = "500px"),
                                                          type = 3,
                                                          color.background = "#fff")
                                     )

                             )






                             )
            )


          )
        )

)
