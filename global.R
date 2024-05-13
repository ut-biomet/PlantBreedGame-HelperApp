# Author: Julien Diot juliendiot@ut-biomet.org
# 2020
#
# Description:
# global file for the application


#### OPTIONS ####
options(stringsAsFactors = FALSE)

#### PACKAGES ####
suppressPackageStartupMessages({
  library(shiny)
  library(shinydashboard) # dashboards with 'Shiny'
  # library("shinydashboardPlus") # https://rinterface.com/shiny/shinydashboardPlus/
  library(shinycssloaders) # Loading Animations
  library(shinyjs) # javascript in shiny

  library(DT)
  library(plotly)
  library(stringr)
  library(RAINBOWR)
  library(ggplot2)
  library(dendextend)
  library(lme4)
})

#### Functions ####
# load all file from "src/functions"
lapply(list.files("src/functions/",
  pattern = ".R$",
  full.names = TRUE
), source)

if (!file.exists("www/appStyle.css")) {
  stop("CSS file have not been initialised. Please run `sass www/appStyle.scss www/appStyle.css` before launching this application")
}

#### Global Variables ####
APP_VERSION <- "0.0.0"
COMMIT_ID <- getCommitID()

APP_TITLE <- "Breeding game's tools"
AUTHOR <- "Julien Diot"

## UI related variables ##
W_sideBar <- 300

## App related variables ##
MAX_GEN <- 4
MAX_INDS <- 300
MAX_G1 <- 20
SNP_CHIP <- "hd"

# GWAS
MAX_OBS_GWAS <- 1000
