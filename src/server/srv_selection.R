# Author: Julien Diot juliendiot@ut-biomet.org
# 2020
#
# Description:
# server file of the app module: "data vizualisation"



#### PARENTS SELECTION ---- ----

#### Reactive variables ----
select_genoDta <- reactive({
  if (is.null(input$select_GenoFile)) {
    return(NULL)
  }

  genoFile <- input$select_GenoFile$datapath
  # read file
  geno <- read.table(genoFile, sep = "\t")

  geno
})

select_markerDta <- reactive({
  if (is.null(input$select_MakerFile)) {
    return(NULL)
  }

  markerFile <- input$select_MakerFile$datapath
  # read file
  markers <- read.csv(markerFile, row.names = 1)
  markers
})


select_predInds <- reactive({

  if (is.null(select_genoDta()) | is.null(select_markerDta()) | is.na(input$n_clust)) {
    return(NULL)
  }

  pred <- predGenVal(select_genoDta(), select_markerDta(),
                     includeIntercept = TRUE)
  pred <- as.data.frame(pred)
  pred$trait1xtrait2 <- pred$trait1 * pred$trait2
  pred <- round(pred, 4)
  pred$ind <- row.names(pred)
  pred$trait3 <- as.factor(pred$trait3)

  row.names(pred) <- NULL
  colnames(pred) <- c("Trait1", "Trait2", "Trait3", "Trait1 x Trait2", "ind")
  pred <- pred[,c("ind", "Trait1", "Trait2", "Trait3", "Trait1 x Trait2")]


  if (input$n_clust > nrow(pred)) {
    pred$group <- NA
  } else {
    pred$group <- as.factor(cutree(select_cluster(), input$n_clust))
  }
  pred

})



select_dist <- reactive({
  if (is.null(select_genoDta())) {
    return(NULL)
  }

  d <- dist(select_genoDta(), method = "euclidean") # dist関数で系統間の距離が求められる
  d

})

select_cluster <- reactive({
  if (is.null(select_dist())) {
    return(NULL)
  }

  d <- select_dist()
  cluster <- hclust(d , method = "ward.D2")

})


#### Observer ----
observe({
  if (is.null(select_predInds())) {
    return(NULL)
  }
  minClustSize <- floor(nrow(select_predInds()) / input$n_clust) ########## <- TO change
  maxClustSize <- ceiling(nrow(select_predInds()) / input$n_clust)######### <- TO change

  updateNumericInput(session, "n_clust",
                     max = nrow(select_predInds()))

  if (input$n_clust > nrow(select_predInds())) {
    updateNumericInput(session, "n_clust",
                       value = nrow(select_predInds()))
  }

  # updateSelectInput(session, "trait_clust",
  #                   choices = colnames(select_predInds())[-1])
  updateNumericInput(session, "top_clust",
                     max = input$n_clust, value = input$n_clust)
  updateNumericInput(session, "nTopEach_clust",
                     max = maxClustSize)
  updateNumericInput(session, "nMaxT3_clust",
                     max = nrow(select_predInds()))
  updateNumericInput(session, "nTop_clust",
                     max = nrow(select_predInds()))


})


observeEvent(input$clust_autoSelect, {
  if (is.null(select_predInds()) | is.null(select_cluster())) {
    return(NULL)
  }
  # browser()

  selInds <- selectParentCands(YPred = select_predInds(),
                               tre = select_cluster(),
                               traitNo = input$trait_clust,
                               nCluster = input$n_clust,
                               topCluster = input$top_clust,
                               nTopEach = input$nTopEach_clust,
                               nMaxDisease = input$nMaxT3_clust,
                               nTop = input$nTop_clust)

  manSel <- input$selectDT_rows_selected
  autoSel <- which(select_predInds()$ind %in% selInds)
  if (is.null(manSel)) {
    selLines <- autoSel
  } else {
    selLines <- unique(c(manSel, autoSel))
  }
  selectRows(selectDT_proxy, selLines, ignore.selectable = FALSE)
})

observeEvent(input$clust_clear, {
  selectRows(selectDT_proxy, c(), ignore.selectable = FALSE)
})


#### Outputs ----
output$clust_clustPlot <- renderPlotly({
  if (is.null(select_cluster())) {
    return(plot_ly(type = "scatter",
                   mode = "markers"))
  }

  if (input$n_clust > nrow(select_predInds())) {
    return(NULL)
  }
  dend <- as.dendrogram(select_cluster())
  dend <- color_branches(dend, input$n_clust)

  p <- ggplot(dend, horiz = T, offset_labels = -3)
  ggplotly(p)

})

output$clust_t1t2Plot <- renderPlotly({
  if (is.null(select_predInds())) {
    return(plot_ly(type = "scatter",
                   mode = "markers"))
  }

  dat <- select_predInds()
  selected <- input$selectDT_rows_selected

  if (length(selected) > 0) {
    annot <- list(
      x = dat[selected, "Trait1"],
      y = dat[selected, "Trait2"],
      text = paste0(dat[selected, "ind"], " -- Group ", dat[selected, "group"]),
      xref = "x",
      yref = "y",
      showarrow = TRUE,
      arrowhead = 7,
      ax = 20,
      ay = -40
    )
  } else {
    annot <- list()
  }

  # plot the individuals
  plt <- plot_ly(type = "scatter",
                 mode = "markers",
                 data = dat,

                 x = ~Trait1,
                 y = ~Trait2,
                 # symbol = ~Trait3,
                 color = ~group,

                 hoverinfo = "text",
                 opacity = 0.7,
                 text = apply(dat, 1, function(l) {
                   paste(names(l), ":", l, collapse = "\n")
                 })) %>%
    plotly::layout(xaxis = list(title = list(text = "Trait1")),
                   yaxis = list(title = list(text = "Trait2")),
                   annotations = annot,
                   title = paste(length(selected), "selected individuals"))
  plt

})

selectDT_proxy <- DT::dataTableProxy("selectDT")
output$selectDT <- renderDataTable({

  if (is.null(select_predInds())) {
    return(DT::datatable(data.frame("." = character())))
  }
  DT::datatable(select_predInds(),
                options = list(scrollX = T),
                filter = "top",
                style = 'default')

})

output$selectDwnld <- downloadHandler(
  filename = function() {
    paste("selectedInds-", format(Sys.time(), "%F_%H-%M-%S"), ".txt", sep="")
  }, content = function(file) {
    inds <- select_predInds()[input$selectDT_rows_selected, "ind"]
    write.table(data.frame(parents = inds), file,
                sep = "\t", quote = FALSE,
                row.names = FALSE, )
  })





#### MATING ---- ----

#### Reactive variables ----
crossTab <- eventReactive(input$mate_btn, {

  if (is.null(select_dist()) | is.null(select_predInds())) {
    return(NULL)
  }

  selInds <- select_predInds()[input$selectDT_rows_selected, "ind"]

  if (length(selInds) == 0) {
    alert("No parents selected")
    return(NULL)
  }

  matePairs(
    parentCands = selInds,
    YPred = select_predInds(),
    d = select_dist(),
    targetPop = input$currentPop,
    mateMethod = input$mateMethod_mate,
    includeSelfing = input$includeSelfing,
    removeDxD = input$removeDxD,
    allocateMethod = input$allocateMethod,
    nTotal = input$nNew,
    traitNo = input$trait_mate,
    h = input$h_mate
  )

})
#### Observer ----
observe({
  indName <- select_predInds()[,"ind"]
  if (all(grepl("^Coll", indName, perl = TRUE))) {
    updateSelectInput(session, "currentPop", selected = "F0")
  } else if (all(grepl("^F1", indName, perl = TRUE))) {
    updateSelectInput(session, "currentPop", selected = "F1")
  } else if (all(grepl("^F2", indName, perl = TRUE))) {
    updateSelectInput(session, "currentPop", selected = "F2")
  } else if (all(grepl("^F3", indName, perl = TRUE))) {
    updateSelectInput(session, "currentPop", selected = "F3")
  } else if (all(grepl("^F4", indName, perl = TRUE))) {
    updateSelectInput(session, "currentPop", selected = "F4")
  }

  if (input$allocateMethod == "weighted") {
    shinyjs::show(id = "h_mate")
    shinyjs::show(id = "trait_mate")

  } else {
    shinyjs::hide(id = "h_mate")
    shinyjs::hide(id = "trait_mate")
  }

  if (input$mateMethod_mate == "all-combination") {
    shinyjs::show(id = "includeSelfing")

  } else {
    shinyjs::hide(id = "includeSelfing")
  }

})


observe({
  updateNumericInput(session, "nNew",
                     max = ifelse(input$currentPop == "F0", 20, 300))
})

# check cross table
observe({

  if (is.null(crossTab()) | is.null(select_predInds())) {
    return(NULL)
  }


  nProj <- sum(crossTab()[,"n_progeny"])
  actualParents <- unique(c(crossTab()[,"parent1"], crossTab()[,"parent2"]))
  selectedParents <- select_predInds()[input$selectDT_rows_selected, "ind"]
  if (nProj != input$nNew) {
    msg = paste("Mating algorithm faild to match the requiered number of progeny.",
                sum(crossTab()[,"n_progeny"]), "instead of", input$nNew)
    alert(msg)
  }

  if (any(!selectedParents %in% actualParents)) {
    msg = paste("Mating algorithm faild to include all selected individuals Missing selected individuals:",
                paste(selectedParents[which(!selectedParents %in% actualParents)],
                      collapse = ", "))
    alert(msg)
  }
})
#### Outputs ----
output$crossTableDT <- renderDataTable({

  if (is.null(crossTab())) {
    return(DT::datatable(data.frame("." = character())))
  }
  DT::datatable(crossTab(),
                options = list(scrollX = T),
                style = 'default')

})



output$mate_plot <- renderPlotly({
  # browser()
  if (is.null(select_predInds()) | is.null(crossTab())) {
    return(plot_ly(type = "scatter",
                   mode = "markers"))
  }

  dat <- select_predInds()
  parents <- unique(c(crossTab()[,"parent1"], crossTab()[,"parent2"]))
  dat$parent <- dat$ind %in% parents


  # plot the individuals
  plt <- plot_ly(type = "scatter",
                 mode = "markers") %>%
    add_markers(data = dat[!dat$parent,],
      x = ~Trait1,
      y = ~Trait2,
      name = "Unselected",
      # symbol = ~Trait3,
      marker=list(color="gray" , opacity=0.5),
      colors = "#000",
      hoverinfo = "text",
      opacity = 0.7,
      text = apply(dat[!dat$parent,], 1, function(l) {
        paste(names(l), ":", l, collapse = "\n")
      }))

  for (l in seq(nrow(crossTab()))) {
    dta2 <- dat[dat$ind %in% crossTab()[l,c("parent1","parent2")],]
    if (nrow(dta2) >=1 ) {
      dta2$n_progeny <- crossTab()[l, c("n_progeny")]
      plt <- plt %>% add_trace(
        mode = "lines+markers",
        data = dta2,
        name = paste("Cross",l, ", n proj =", crossTab()[l,c("n_progeny")]),
        x = ~Trait1,
        y = ~Trait2,
        hoverinfo = "text",
        text = apply(dta2, 1, function(l) {
          paste(names(l), ":", l, collapse = "\n")
        }))
    }


  }

  plt  %>% plotly::layout(xaxis = list(title = list(text = "Trait1")),
                          yaxis = list(title = list(text = "Trait2")),
                          # annotations = annot,
                          title = paste(nrow(crossTab()), "different crosses"))
  plt

})


output$mateDwnld <- downloadHandler(
  filename = function() {
    paste("Request-", format(Sys.time(), "%F_%H-%M-%S"), ".txt", sep="")
  }, content = function(file) {
    write.table(x = crossTab(), file = file,
                sep = "\t", row.names = F, quote = FALSE)
  })



