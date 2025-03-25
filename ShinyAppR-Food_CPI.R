library(shiny)
library(ggplot2)
library(dplyr)


# Load the dataset
df <- read.csv("/Users/ogheneatoma/Downloads/combined.csv")

# Convert Date column to Date type
df$Date <- as.Date(df$Date)

# UI
ui <- fluidPage(
  titlePanel("Shiny App 2025: Food Consumer Price Index Inflation"),
  h3("Erika, Melissa, Thomas"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("time_range", 
                  "Select Time Range:", 
                  min = min(df$Date), 
                  max = max(df$Date), 
                  value = range(df$Date),
                  timeFormat = "%Y-%m"),
      
      selectInput("food_category", 
                  "Select Food Category:", 
                  choices = colnames(df)[2:length(colnames(df))], 
                  selected = "Baked_Goods")
    ),
    
    mainPanel(
      plotOutput("price_plot")
    )
  )
)

# Server
server <- function(input, output) {
  filtered_data <- reactive({
    df %>%
      filter(Date >= input$time_range[1] & Date <= input$time_range[2]) %>%
      select(Date, all_of(input$food_category))
  })
  
  output$price_plot <- renderPlot({
    ggplot(filtered_data(), aes(x = Date, y = .data[[input$food_category]])) +
      geom_line(color = "blue", size = 1) +
      labs(title = paste("Price Trend of", input$food_category),
           x = "Date",
           y = "Price Index") +
      theme_minimal()
  })
}

# Run the application
shinyApp(ui = ui, server = server)
