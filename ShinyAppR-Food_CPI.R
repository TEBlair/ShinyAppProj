library(shiny)
library(ggplot2)
library(dplyr)
library(shinyWidgets)

# Load the dataset
df <- read.csv("/Users/ogheneatoma/Downloads/combined.csv")

# Convert Date column to Date type
df$Date <- as.Date(df$Date)

# UI
ui <- fluidPage(
  titlePanel("Shiny App 2025: US Consumer Price Index (Food at Home) Inflation"),
  setBackgroundColor(
    color = c("#FFFFFF", "#90EE91"),
    gradient = "linear",
    direction = "left"
  ),
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
      plotOutput("price_plot"),
      br(),
      DTOutput("price_table")
    )
  )
)

# Server
server <- function(input, output) {
  filtered_data <- reactive({
    df %>%
      filter(Date >= input$time_range[1] & Date <= input$time_range[2])
  })
  
  output$price_plot <- renderPlot({
    ggplot(filtered_data(), aes(x = Date, y = .data[[input$food_category]])) +
      geom_line(color = "darkgreen", size = 1) +
      annotate(geom = "label", x = as.Date("2020-01-01"), y = 310,
               label = "COVID-19 (2020)", size = 4, family = "Roboto Condensed", hjust = 1, color = "red") +
      annotate(geom = "label", x = as.Date("2021-01-20"), y = 325,
               label = "BIDEN ERA (2021)", size = 4, family = "Roboto Condensed", hjust = 1, color = "darkred") +
      annotate(geom = "label", x = as.Date("2023-05-11"), y = 360,
               label = "End of COVID-19 (2023)", size = 4, family = "Roboto Condensed", hjust = 1, color = "darkgreen") +
      annotate(geom = "label", x = as.Date("2025-05-20"), y = 370,
               label = "TRUMP ERA 2.0 (2025)", size = 4, family = "Roboto Condensed", hjust = 1, color = "darkred") +
      labs(title = paste("US Consumer Price Index Trend (Food at Home) of", input$food_category),
           subtitle = "	Seasonally Adjusted",
           caption = "Source: FRED",
           x = "Date",
           y = "Price Index") +
      theme_bw(base_family = "Roboto Condensed") +
      theme(plot.title = element_text(face = "bold"))
  })
  
  output$price_table <- renderDT({
    dat <- filtered_data()
    dat <- data.frame(
      Date = dat$Date,
      Price = dat[[input$food_category]]
    )
    
    datatable(dat, 
              options = list(pageLength = 10),
              rownames = FALSE) %>%
      formatStyle(
        "Price",
        background = styleColorBar(range(dat$Price, na.rm = TRUE), 'lightgreen'),
        backgroundSize = '98% 88%',
        backgroundRepeat = 'no-repeat',
        backgroundPosition = 'center'
      )
  })
  
}

# Run the application
shinyApp(ui = ui, server = server)

