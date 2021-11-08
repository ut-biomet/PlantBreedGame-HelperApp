# Author: Julien Diot juliendiot@ut-biomet.org
# 2020
#
# Description:
# server file of the app module: "marker effect estimation"



#### Reactive variables ----
EffEst_genoDta <- reactive({
  if (is.null(input$EffEstGenoFile)) {
    return(NULL)
  }

  genoFile <- input$EffEstGenoFile$datapath
  # read file
  geno <- read.table(genoFile, sep = "\t")

  geno
})

EffEst_phenoDta <- reactive({
  if (is.null(input$EffEstPhenoFile)) {
    return(NULL)
  }

  phenoFile <- input$EffEstPhenoFile$datapath
  # read file
  pheno <- read.table(file = phenoFile,
                      sep = "\t", header = TRUE)
  pheno
})


EffEstWeights <- eventReactive(input$EffEstRun, {

  if (is.null(EffEst_genoDta()) | is.null(EffEst_phenoDta())) {
    return(NULL)
  }

  progressBar <- shiny::Progress$new(session, min=0, max=3)
  progressBar$set(value = 0.5,
                    message = "形質1・形質2の遺伝子型値の推定",
                    detail = "...")

  ### 形質1・形質2の遺伝子型値の推定
  estGenValRes <- estGenVal(phenoColl = EffEst_phenoDta())
  Y <- estGenValRes$Y  # 遺伝子型値
  tIntercepts <- estGenValRes$tIntercepts  # 切片情報を保存

  ### 形質3のデータの変換
  y3 <- convResistance(phenoColl = EffEst_phenoDta())



  ### 形質1・形質2に対するマーカー効果の推定
  #################### パラメータ（ここを変更） ####################
  multiTrait <- input$EffEstMultiT
  alpha <- input$EffEstAlpha
  ##################################################################

  X <- as.matrix(EffEst_genoDta()) - 1

  ## 推定の実施
  progressBar$set(value = 1,
                  message = "形質1&2に対するマーカー効果の推定",
                  detail = "...")

  t12Weights <- estMrkEff(Y = Y, X = X, tIntercepts = tIntercepts,
                          target = "quantitative", multiTrait = multiTrait,
                          alpha = alpha,
                          method = input$EffEstMethod)

  ### 形質3に対するマーカー効果の推定
  ## パラメータはあまり変える必要はない
  ## 推定の実施
  progressBar$set(value = 2,
                  message = "形質3に対するマーカー効果の推定",
                  detail = "...")
  t3Weight <- estMrkEff(Y = y3, X = X, tIntercepts = 0,
                        target = "qualitative", multiTrait = FALSE,
                        alpha = 1,
                        method = "glmnet")


  ### マーカー効果の集計・保存
  weight <- data.frame(t12Weights, t3Weight)
  rownames(weight) <- c("Intercept", colnames(X))
  colnames(weight) <- paste0("trait_", 1:3)

  progressBar$set(value = 3,
                  message = "終わりました！",
                  detail = "...")
  weight


}, ignoreNULL = FALSE)
#### Observer ----
observe({

  if (input$EffEstMethod == "glmnet") {
    shinyjs::show(id = "EffEstMultiT")
    shinyjs::show(id = "EffEstAlpha")
  } else if  (input$EffEstMethod == "GBLUP") {
    shinyjs::hide(id = "EffEstMultiT")
    shinyjs::hide(id = "EffEstAlpha")
  }
})

#### Outputs ----
output$EffEstDT <- renderDataTable({

  if (is.null(EffEstWeights())) {
    return(DT::datatable(data.frame("." = character())))
  }
  DT::datatable(EffEstWeights(),
                style = 'default')

})

output$EffEstDwnld <- downloadHandler(
  filename = function() {
    paste("markerWeights-", format(Sys.time(), "%F_%H-%M-%S"), ".csv", sep="")
  }, content = function(file) {
    write.csv(EffEstWeights(), file, quote = FALSE)
  })
