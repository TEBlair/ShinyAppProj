library(shiny)
library(ggplot2)
library(dplyr)
library(forecast)
library(prophet)
library(vars)
library(tseries)
library(rugarch)
library(TTR)
library(stats)
library(FactoMineR)
library(factoextra)
library(shinyWidgets)
library(DT)

##Extra ideas: put the important eeconomic incidents: Trump era, Covid 19, Biden era
# Load and preprocess data
df <- read.csv("/Users/ogheneatoma/Documents/DATA-613/Shiny_group_project/cleaned_data/combined.csv")
df$Date <- as.Date(df$Date)
df <- df %>% arrange(Date)

# Compute CPI returns
df <- df %>%
  mutate(across(-Date, ~ c(NA, diff(.) / lag(.)[-1] * 100), .names = "{.col}_return"))

ui <- fluidPage(
  titlePanel(div("Shiny App 2025: Food Consumer Price Index Inflation", style = "font-size: 40px; font-weight: bold;")),
  setBackgroundColor(
    color = c("#FFFFFF", "#90EE91"),
    gradient = "linear",
    direction = "left"
  ),
  div(style = "display: flex; gap: 10px;",
      h3("Erika,", style = "color: teal;"),
      h3("Melissa,", style = "color: red;"),
      h3("Thomas", style = "color: silver;")
  ),
  sidebarLayout(
    sidebarPanel(
      sliderInput("time_range", "Select Time Range:",
                  min = min(df$Date), max = max(df$Date),
                  value = range(df$Date), timeFormat = "%Y-%m"),
      selectInput("food_category", "Select Food Category:",
                  choices = colnames(df)[2:(ncol(df)/2+1)],
                  selected = "Baked_Goods"),
      # checkboxInput("show_returns", "Display CPI Returns (%)", FALSE),
      radioButtons("models", "Select Forecasting Models:",
                        choices = c("ARIMA", "SARIMA", "Holt-Winters", "SES", "Prophet")),
      radioButtons("vol_model", "Volatility Model:",
                   choices = c("GARCH", "EWMA")),
      downloadButton("download_data", "Download Forecasts")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Trends", plotOutput("price_plot"), br(), DTOutput("price_table")),
        tabPanel("Returns", plotOutput("returns_plot")),
        tabPanel("Forecasting", plotOutput("forecast_plot"), verbatimTextOutput("metrics")),
        tabPanel("Volatility", plotOutput("vol_plot")),
        tabPanel("Autocorrelation", plotOutput("acf_plot"), plotOutput("pacf_plot"))
      )
    )
  )
)

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
  
  output$returns_plot <- renderPlot({
    ggplot(filtered_data(), aes(x = Date, y = .data[[paste0(input$food_category, "_return")]])) +
      geom_line(color = "darkgreen") +
      labs(title = paste("Returns for", input$food_category), y = "Return (%)", x = "Date") +
      theme_minimal()
  })
  
  output$acf_plot <- renderPlot({
    acf(na.omit(filtered_data()[[paste0(input$food_category, "_return")]]), main = "ACF of CPI Returns")
  })
  
  output$pacf_plot <- renderPlot({
    pacf(na.omit(filtered_data()[[paste0(input$food_category, "_return")]]), main = "PACF of CPI Returns")
  })
  
  output$forecast_plot <- renderPlot({
    # Decompose the time series using STL for flexible seasonal-trend separation
    data_full <- na.omit(df[, c("Date", input$food_category)])
    ts_full <- ts(data_full[[input$food_category]], frequency = 12)
    decomp <- stl(ts_full, s.window = "periodic")
    plot(decomp, main = paste("STL Decomposition of", input$food_category))
    
    # Continue with forecasting models
    data <- na.omit(df[, c("Date", input$food_category)])
    colnames(data) <- c("ds", "y")
    train <- data[data$ds < as.Date("2021-01-01"), ]
    test <- data[data$ds >= as.Date("2021-01-01"), ]

    if ("ARIMA" %in% input$models) {
      # STL decomposition and deseasonalization
      deseasonalized <- ts_full - decomp$time.series[, "seasonal"]
      train_deseason <- window(deseasonalized, end = c(2020, 12))
      model_arima <- auto.arima(train_deseason)
      fc_deseason <- forecast(model_arima, h = nrow(test))

      # Recompose by adding back seasonal component
      seasonal_cycle <- rep(decomp$time.series[1:12, "seasonal"], length.out = nrow(test))
      final_forecast <- fc_deseason$mean + seasonal_cycle

      ts.plot(ts_full, final_forecast, col = c("black", "red"), lty = 1:2,
              main = paste("ARIMA Forecast with STL for", input$food_category),
              ylab = "CPI Index")
      legend("topleft", legend = c("Actual", "Forecast"), col = c("black", "red"), lty = 1:2)
    }
    
    if ("SARIMA" %in% input$models) {
      model_sarima <- Arima(ts_full, order = c(1,1,1), seasonal = c(1,1,1))
      forecast_sarima <- forecast(model_sarima, h = nrow(test))
      plot(forecast_sarima, main = paste("SARIMA Forecast for", input$food_category))
    }
    
    if ("Holt-Winters" %in% input$models) {
      model_hw <- HoltWinters(ts_full)
      forecast_hw <- forecast(model_hw, h = nrow(test))
      plot(forecast_hw, main = paste("Holt-Winters Forecast for", input$food_category))
    }
    
    if ("SES" %in% input$models) {
      model_ses <- ses(ts_full, h = nrow(test))
      plot(model_ses, main = paste("SES Forecast for", input$food_category))
    }
    
    if ("Prophet" %in% input$models) {
      m <- prophet(train)
      future <- make_future_dataframe(m, periods = nrow(test), freq = "month")
      forecast_prophet <- predict(m, future)
      plot(m, forecast_prophet) + ggtitle(paste("Prophet Forecast for", input$food_category))
    }
  })
  
  output$metrics <- renderPrint({
    data <- na.omit(df[, c("Date", input$food_category)])
    colnames(data) <- c("ds", "y")
    train <- data[data$ds < as.Date("2021-01-01"), ]
    test <- data[data$ds >= as.Date("2021-01-01"), ]
    
    ts_data <- ts(train$y, frequency = 12)
    actual <- test$y
    metrics_list <- list()
    
    if ("ARIMA" %in% input$models) {
      model <- auto.arima(ts_data)
      forecast_vals <- forecast(model, h = length(actual))$mean
      metrics_list$ARIMA <- c(
        MAE = mean(abs(forecast_vals - actual)),
        RMSE = sqrt(mean((forecast_vals - actual)^2)),
        MAPE = mean(abs((forecast_vals - actual) / actual)) * 100
      )
    }
    
    if ("SARIMA" %in% input$models) {
      model <- Arima(ts_data, order = c(1,1,1), seasonal = c(1,1,1))
      forecast_vals <- forecast(model, h = length(actual))$mean
      metrics_list$SARIMA <- c(
        MAE = mean(abs(forecast_vals - actual)),
        RMSE = sqrt(mean((forecast_vals - actual)^2)),
        MAPE = mean(abs((forecast_vals - actual) / actual)) * 100
      )
    }
    
    if ("Holt-Winters" %in% input$models) {
      model <- HoltWinters(ts_data)
      forecast_vals <- forecast(model, h = length(actual))$mean
      metrics_list$Holt_Winters <- c(
        MAE = mean(abs(forecast_vals - actual)),
        RMSE = sqrt(mean((forecast_vals - actual)^2)),
        MAPE = mean(abs((forecast_vals - actual) / actual)) * 100
      )
    }
    
    if ("SES" %in% input$models) {
      model <- ses(ts_data, h = length(actual))
      forecast_vals <- model$mean
      metrics_list$SES <- c(
        MAE = mean(abs(forecast_vals - actual)),
        RMSE = sqrt(mean((forecast_vals - actual)^2)),
        MAPE = mean(abs((forecast_vals - actual) / actual)) * 100
      )
    }
    
    if ("Prophet" %in% input$models) {
      m <- prophet(train)
      future <- make_future_dataframe(m, periods = length(actual), freq = "month")
      forecast_vals <- predict(m, future)
      predicted <- tail(forecast_vals$yhat, length(actual))
      metrics_list$Prophet <- c(
        MAE = mean(abs(predicted - actual)),
        RMSE = sqrt(mean((predicted - actual)^2)),
        MAPE = mean(abs((predicted - actual) / actual)) * 100
      )
    }
  metrics_df <- do.call(rbind, metrics_list)
  print(round(metrics_df, 3))
  
  })
  
  output$vol_plot <- renderPlot({
    returns <- na.omit(df[[paste0(input$food_category, "_return")]])
    if (input$vol_model == "GARCH") {
      spec <- ugarchspec(variance.model = list(model = "sGARCH", garchOrder = c(1,1)),
                         mean.model = list(armaOrder = c(1,1), include.mean = TRUE))
      fit <- ugarchfit(spec, returns)
      plot(fit, which = 2)
    } else {
      ewma <- EMA(returns, ratio = 0.94)
      plot(ewma, type = "l", col = "purple", main = "EWMA Volatility", ylab = "EWMA")
    }
  })
  
  output$download_data <- downloadHandler(
    filename = function() {
      paste("CPI_forecast_", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      # Placeholder for forecast output
      data <- data.frame(Date = df$Date, CPI = df[[input$food_category]])
      write.csv(data, file, row.names = FALSE)
    }
  )
}

shinyApp(ui = ui, server = server)
