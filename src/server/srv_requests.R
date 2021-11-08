# Author: Julien Diot juliendiot@ut-biomet.org
# 2020
#
# Description:
# server file of the app module: "menu 2"





#### Reactive variables ----
inputReq <- reactive({
  if (is.null(input$reqFile)) {
    return(NULL)
  }

  reqFile <- input$reqFile$datapath
  # read file
  req <- read.table(reqFile,
                    header = T,
                    sep = "\t",
                    na.strings = "")
  req
})

goodRequest <- reactive({
  checkRequest(inputReq(), input$prefix)
})

pltMatReq <- reactive({
  if (is.null(inputReq())) {
    return(NULL)
  }
  # check request
  if (!isTRUE(goodRequest())) {
    return(NULL)
  }

  pltMatReq <- createPltMatReq(inputReq(), input$prefix)
  pltMatReq
})

genoReq <- reactive({
  if (is.null(pltMatReq())) {
    return(NULL)
  }
  genoReq <- createGenoReq(pltMatReq(), SNP_CHIP)
  genoReq
})

#### Observer ----
observe({
  if (is.null(inputReq()) | is.null(genoReq()) ) {
    shinyjs::hide(id = "req_dwnld")
  } else {
    shinyjs::show(id = "req_dwnld")
  }

})


#### Outputs ----
output$reqInfoMsg1 <- output$reqInfoMsg2 <- output$reqInfoMsg3 <- renderUI({

  if (is.null(inputReq())) {
    return(
      p(style = "color: #999;", "No file uploaded.")
    )
  } else if (!isTRUE(goodRequest())) {
    return(
        p(style = "color: red;", goodRequest())
    )
  } else {
    return(NULL)
  }

  p(style = "color: #999;", "Hello")

})

output$reqDtaInput <- renderDataTable({
  inputReq()
})

output$reqPltMatReq <- renderDataTable({
  pltMatReq()
})

output$reqGenoReq <- renderDataTable({
  genoReq()
})


output$dwnldReq <- downloadHandler(

  filename = function(){
    paste0("requests_", input$prefix, ".zip")
    },

  content = function(file) {
    tmpdir <- tempdir()
    prevWd <- getwd()
    setwd(tempdir())

    dir.create(paste0(tmpdir, "/requests_", input$prefix))
    tmpdir <- paste0(tmpdir, "/requests_", input$prefix)


    # pltMatFile <- paste0(tmpdir,
    #                          "/plantMaterialRequest_", input$prefix,
    #                          ".txt")
    pltMatFile <- paste0("plantMaterialRequest_", input$prefix, ".txt")
    write.table(pltMatReq(), pltMatFile,
                sep = "\t", col.names = T, row.names = F,
                quote = FALSE)

    # genoFile <- paste0(tmpdir,
    #                      "/genoRequest_", input$prefix,
    #                      ".txt")
    genoFile <- paste0("genoRequest_", input$prefix, ".txt")
    write.table(genoReq(), genoFile,
                sep = "\t", col.names = T, row.names = F,
                quote = FALSE)

    zip(zipfile = file, files = c(genoFile, pltMatFile))
    setwd(prevWd)

  }
)
