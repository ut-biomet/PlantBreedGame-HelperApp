# Author: Julien Diot juliendiot@ut-biomet.org
# 2020
#
# Description:
# server file of the app module: "data vizualisation"



#### Reactive variables ----
dtaViz_genoDta <- reactive({
  if (is.null(input$dtaVizGenoFile)) {
    return(NULL)
  }

  genoFile <- input$dtaVizGenoFile$datapath
  # read file
  geno <- read.table(genoFile, sep = "\t")

  geno
})

dtaViz_markerDta <- reactive({
  if (is.null(input$dtaVizMakerFile)) {
    return(NULL)
  }

  markerFile <- input$dtaVizMakerFile$datapath
  # read file
  markers <- read.csv(markerFile, row.names = 1)
  markers
})


dtaViz_predInds <- reactive({
  if (is.null(dtaViz_genoDta()) | is.null(dtaViz_markerDta())) {
    return(NULL)
  }

  pred <- predGenVal(dtaViz_genoDta(), dtaViz_markerDta(),
                     includeIntercept = TRUE)
  pred <- as.data.frame(pred)
  pred$trait3 <- as.factor(pred$trait3)
  pred$trait1xtrait2 <- pred$trait1 * pred$trait2
  pred$ind <- row.names(pred)
  row.names(pred) <- NULL
  colnames(pred) <- c("Trait1", "Trait2", "Trait3", "Trait1 x Trait2", "ind")
  pred <- pred[,c("ind", "Trait1", "Trait2", "Trait3", "Trait1 x Trait2")]

  pred
})
#### Observer ----


#### Outputs ----
output$dtaVizPlot <- renderPlotly({
  if (is.null(dtaViz_predInds())) {
    return(plot_ly(type = "scatter",
                  mode = "markers"))
  }
  SeePlot(dtaViz_predInds(), input$dtaVizDT_rows_selected)
})

output$dtaVizDT <- renderDataTable({

  if (is.null(dtaViz_predInds())) {
    return(DT::datatable(data.frame("." = character())))
  }
  DT::datatable(dtaViz_predInds(),
                style = 'default')

})

output$dtaVizDwnld <- downloadHandler(
  filename = function() {
    paste("estimatedBreedingValues-", format(Sys.time(), "%F_%H-%M-%S"), ".txt", sep="")
  }, content = function(file) {
    write.table(dtaViz_predInds(), file,
                sep = "\t", quote = FALSE,
                row.names = FALSE, )
  })
