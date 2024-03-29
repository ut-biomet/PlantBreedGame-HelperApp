# Author: Julien Diot juliendiot@ut-biomet.org
# 2020
#
# Description:
# global file for the application


#### OPTIONS ####
options(stringsAsFactors = FALSE)

#### PACKAGES ####
library(shiny)
library(shinydashboard) # dashboards with 'Shiny'
# library("shinydashboardPlus") # https://rinterface.com/shiny/shinydashboardPlus/
library(shinycssloaders) # Loading Animations
library(shinyjs) # javascript in shiny
stopifnot("sass" %in% installed.packages()) # use of SASS for generating CSS

library(DT)
library(plotly)
library(stringr)
library(RAINBOWR)
library(ggplot2)
library(dendextend)
library(lme4)

#### Functions ####
# load all file from "src/functions"
lapply(list.files("src/functions/",
                  pattern = ".R$",
                  full.names = TRUE), source)


#### Compile CSS style sheet ####
sass::sass(input = sass::sass_file("www/appStyle.scss"),
           output = "www/appStyle.css")




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
