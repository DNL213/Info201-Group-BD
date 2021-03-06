library(shiny)
library("dplyr")
library("ggplot2")
library("png")
library("grid")
library(lubridate)
library(plotly)

Stats <- read.csv("Stats_Better.csv", stringsAsFactors = FALSE, encoding = 'UTF-8', fileEncoding = 'ISO8859-1')
erangelData <- read.csv("data_subset.csv", stringsAsFactors = FALSE, encoding = 'UTF-8', fileEncoding = 'ISO8859-1')

#Function that filters and gathers data on selected user.
getPlayerStats <- function(playername, mode) {
  if (mode == "Squad") {
    size <- 4
  } else if (mode == "Duo") {
    size <- 2
  } else {
    size <- 1
  }
  Stats_Filtered <- subset(Stats, player_name == playername & party_size == size)
  Stats_Player <- data.frame(matrix(ncol = 10, nrow = 1))
  Column_names <- c("Games_Played", "Wins", "Top_5", "Top_10", "Most_Kills",
                    "Average_Kills", "Average_Damage", "Average_Assists", "Average_Distance_Travelled", "Average_Time_Survived")
  colnames(Stats_Player) <- Column_names
  Stats_Player$Games_Played <- nrow(Stats_Filtered)
  if(Stats_Player$Games_Played[1] == 0) {
    Stats_Player[is.na(Stats_Player)] <- 0
  } else {
    Stats_Player$Average_Kills <- round(mean(Stats_Filtered$player_kills), digits = 2)
    Stats_Player$Most_Kills <- max(Stats_Filtered$player_kills)
    Stats_Player$Average_Assists <- round(mean(Stats_Filtered$player_assists), digits = 2)
    Stats_Player$Average_Damage <- round(mean(Stats_Filtered$player_dmg), digits = 2)
    Stats_Filtered$Distance_Travelled <- mean(Stats_Filtered$player_dist_walk) + mean(Stats_Filtered$player_dist_ride)
    Distance <- round(mean(Stats_Filtered$Distance_Travelled), digits = 2)
    Stats_Player$Average_Distance_Travelled <- paste(Distance,'m')
    Stats_Player$Top_10 <- sum(Stats_Filtered$team_placement <= 10)
    Stats_Player$Top_5 <- sum(Stats_Filtered$team_placement <= 5)
    Stats_Player$Wins <- sum(Stats_Filtered$team_placement == 1)
    Stats_Player$Average_Time_Survived <- paste(seconds_to_period(round(mean(Stats_Filtered$player_survive_time), digits = 0)))
    colnames(Stats_Player) <- c("Games Played", "Games Won", "Placed Top 5", "Placed Top 10", "Most Kills",
                                "Average Kills", "Average Damage", "Average Assists", "Average Distance Tavelled", "Average Time Survived")
  }
   return(Stats_Player)
}

# Define UI 
ui <- fluidPage(
  includeCSS("styles.css"),
   
   # Application title
   shinyUI(navbarPage("PUBG Statistics!",
   
          tabPanel("Weapon Statistics", 
                sidebarPanel(
                  tags$style(".well {background-color:#fff; 
                             border-top: 3px solid #eda338;}"),
                  selectInput("weaponType", "Weapon Type:", 
                               choices = c("All",
                                           "Assault",
                                           "DMR",
                                           "Machine Guns",
                                           "Melee Weapons",
                                           "Other Weapons",
                                           "Pistols",
                                           "Shotguns",
                                           "Snipers",
                                           "Vehicle"))
                  ),
                
                # Show a plot of the weapons based on user input
                mainPanel(
                  plotOutput("weaponPlot")
                )),
       tabPanel("Player Statistics",
            sidebarPanel(    
                selectInput("player_name",
                            "Find Player Stats. (Select or search players name)", 
                            choices = unique(Stats$player_name))
            ),
            #Shows tables under spcified tabs
            mainPanel(
                tabsetPanel(id = "tabs",
                            tabPanel("Solo", value = "Solo", tableOutput("solo")),
                            tabPanel("Duo",value = "Duo", tableOutput("duo")),
                            tabPanel("Squad", value = "Squad", tableOutput("squad"))
                )
            )
       )
  ))
)

# Define server 
server <- function(input, output) {
   #Creates Tables depending on user input
   output$solo <- renderTable({
    getPlayerStats(input$player_name, input$tabs)
   })
  
   output$duo <- renderTable({
    getPlayerStats(input$player_name, input$tabs) 
   })
  
   output$squad <- renderTable({
     getPlayerStats(input$player_name, input$tabs)  
   })  
   
   output$weaponPlot <- renderPlot({
     
     #chooses data based on user input
     if(input$weaponType == "All") {
       weaponData <- read.csv("data/all.csv")
     } else if(input$weaponType == "Assault") {
       weaponData <- read.csv("data/assault.csv")
     } else if(input$weaponType == "DMR") {
       weaponData <- read.csv("data/DMR.csv")
     } else if(input$weaponType == "Melee Weapons") {
         weaponData <- read.csv("data/melee.csv")
     } else if(input$weaponType == "Machine Guns") {
       weaponData <- read.csv("data/machinegun.csv")
     } else if(input$weaponType == "Other Weapons") {
       weaponData <- read.csv("data/other.csv")
     } else if(input$weaponType == "Pistols") {
       weaponData <- read.csv("data/pistol.csv")
     } else if(input$weaponType == "Shotguns") {
       weaponData <- read.csv("data/shotguns.csv")
     } else if(input$weaponType == "Snipers") {
       weaponData <- read.csv("data/snipers.csv")
     } else if(input$weaponType == "Vehicle") {
       weaponData <- read.csv("data/vehicle.csv")
     }
     
     ggplot(weaponData, aes(x = killed_by, y = freq, fill = killed_by)) + 
       ggtitle(input$weaponType) + 
       geom_bar(stat = "identity") +
       theme(axis.text = element_text(size = 12),
             axis.title = element_text(size = 12, face = "bold"),
             axis.ticks.x = element_blank(),
             axis.ticks.y = element_blank())
   }, height = 800)
}

# Run the application 
shinyApp(ui = ui, server = server)

