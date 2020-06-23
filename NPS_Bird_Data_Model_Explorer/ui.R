#NPS Bird Data Model Explorer UI

#set working directory

#rm(list=ls())

#load packages
library(htmlwidgets)
library(leaflet)
library(shiny)
library(shinythemes)
library(shinydashboard)
library(shinyWidgets)
library(shinyjs)
library(plyr)
library(dplyr)
library(jsonlite, pos=100)
library(ggplot2)
library(reshape2)
library(pals)
library(lubridate)
library(magrittr)
library(tidyr)
library(unmarked)


# #load source functions
# source("Source/makePOccu_umf.R")
# source("Source/makePCount_umf.R")
# source("Source/summaryFunction.R")
# #new source functions for running analyses across all years
# source("Source/makePCountNetworkWide_umf.R")
# source("Source/makePOccuNetworkWide_umf.R")
# source("Source/AICcmodavg.gof.test_source.R")

#read in formatted data
data<-read.csv("./Data/NCRN_Forest_Bird_Data_Formatted.csv",header=TRUE)

#species to remove
removeList<-c("UNBI","UNCH","UNHA","UNCR","UNDU","UNFL","UNOW","UNSP","UNSW","UNTH","UNWA","UNWO","UNWR")
#remove unwanted AOU codes
data<-subset(data, ! AOU_Code %in% removeList)

#creat Year as date object
data$Date<-as.Date(data$Date, tryFormats = c("%Y-%m-%d", "%Y/%m/%d", "%m/%d/%y"))
# 
data$YearDate<-lubridate::year(data$Date)

#create modelList
modelList_abun<-c("~1~Year; Poisson","~1~Year; Negative Binomial","~Visit~Year; Poisson","~Visit~Year; Negative Binomial","~Visit+Observer~Year; Poisson","~Visit+Observer~Year; Negative Binomial")

modelList_occu<-c("~1~Year","~Visit~Year","~Visit+Observer~Year","~Visit+Observer+Time~Year")

########################################################################################################################
# Define UI for application that draws a histogram
ui <- 
  library(shinydashboard)
  dashboardPage(
  
  dashboardHeader(
    
    title = div(img(src="NPS_logo.png"), "National Park Service - Bird Monitoring Data Model Explorer",tags$head(includeCSS("./www/mainpageTest.css") )),titleWidth=600
  ),
  
  dashboardSidebar(width=200,
                   
                   #br(),
                   #hr(),
                   
                   sidebarMenu(startExpanded=TRUE,
                               #Select Loctation
                               div(id="LocationControls",
                                   tags$div(title="SelectLocation",
                                            selectInput(inputId="LocationSelect",label="Select Location", 
                                                        choices=c("NCRN",as.character(unique(data$Unit_Code))), multiple=FALSE,selected="NCRN")
                                   )),
                               
                               
                               #Select Taxa controls
                               div(id="SpeciesControls",
                                   tags$div(title="SelectSpecies",
                                            selectInput(inputId="SpeciesSelect",label="Select Species", 
                                                        choices=sort(c(as.character(unique(data$Common_Name)))), multiple=FALSE)
                                   )),
                               
                               
                               
                               #hr(),
                               br(),
                               
                               #Select range of years
                               div(id="Year Controls",
                                   tags$div(title="SelectYears",
                                            sliderInput(inputId="YearSelect",
                                                        label="Years:",
                                                        min = min(unique(data$Date)),
                                                        max = max(unique(data$Date)),
                                                        value=c(min(unique(data$Date)),max(unique(data$Date))),
                                                        timeFormat = "%Y",
                                                        step=1,
                                                        dragRange=TRUE
                                                        #animate = TRUE
                                            )
                                   )),
                               #hr(),
                               br(),
                               
                               div(id="Model Type",
                                   tags$div(title="TypeModel",
                                            selectInput(inputId="ModelType",label="Occupancy/Abundance", 
                                                        choices=c("Occupancy","Abundance"), multiple=FALSE)
                                   )),
                               
                               
                               #hr(),
                               br(),
                               
                               div(id="Model Controls",
                                   tags$div(title="SelectModel",
                                            selectInput(inputId="ModelSelect",label="Select Model", 
                                                        choices=modelList_occu, multiple=FALSE)
                                   )),
                               
                               
                               #hr(),
                               br(),
                               
                               
                               div(id="CheckboxControls", label="Options",
                                   tags$div(title="ControlButtons"),
                                   renderText("Options"),
                                   checkboxInput(inputId = "fitModel",  label = "Fit Model", value=FALSE),
                                   checkboxInput(inputId = "LinearTrend",  label = "Linear Trend",value=FALSE)
                               ),
                               
                               br(),
                               
                               # div(id="Info",label="ModelInformation",
                               #     tags$div(title="ModInfo"),
                               #     renderText("ModelTxt"),
                               #     htmlOutput(outputId = "mytext")
                               #     )
                               
                               div(id="Info",label="ModelInformation", style="marign-left:10px",
                                tags$div(class="header", checked=NA,
                                        tags$p("Models fit using 'unmarked' in R."),
                                        tags$a(href="https://cran.r-project.org/web/packages/unmarked/unmarked.pdf", strong("Model info here."))))
                   )),
  
  dashboardBody(id="dashboardBody",
                tags$head( tags$meta(name = "viewport", content = "width=1600"),uiOutput("body")),
                #Main Body
                useShinyjs(),
                div(class="outer",
                    tags$head(includeCSS("./www/mapstyles.css") ),
                    leafletOutput("StudyAreaMap", width = "100%", height = "52%"),
                    
                    br(),
                    
                    fluidRow(
                      column(width = 12,
                             div(style = "height:110px;width:100%;background-color: #000000;border-color: #000000",
                                 shinydashboard::valueBoxOutput("TotalDetections",width=6),
                                 shinydashboard::valueBoxOutput("GOF",width=6))),
                                 height="110px"),
                             
                             
                             fluidRow(
                               column(width = 12, offset = 0,
                                      div(style = "height:100px;width:100%;margin-top:-25px;margin-bottom:0;background-color: #000000",
                                              plotOutput("trendPlot",height="280px",width="98%")
                                      ))
                             )
                      )
                    )
)
