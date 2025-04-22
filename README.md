# ShinyAppProj
This is a collection of files for Data613. This project aims to develop an interactive Shiny app that visualizes the Monthly Cost of Goods in the U.S. over the past 10 years, with a focus on food Consumer Price Index (CPI) inflation from the FRED. The application will provide insights into price trends and allow users to explore different food categories through interactive features.

## Introduction
This project aims to develop an interactive Shiny App that automates CPI data collection, applies econometric modeling, and provides interactive forecasting for food inflation in the U.S. The app will use FRED’s CPI data for "Food at Home" and "Alcoholic Beverages" and apply time series forecasting models, including ARIMA, SARIMA (Seasonal ARIMA), Holt-Winters, Prophet, and SES (Simple Exponential Smoothing). It will also use volatility models using GARCH (Generalized Autoregressive Conditional Heteroskedasticity) and EWMA (Exponentially Weighted Moving Average).

## Business Understanding

1. Objective: Analyze historical and future trends of food-based inflation.
2. Key Focus Areas:
- Food at Home CPI
- Alcoholic Beverages CPI
3. Key Questions:
- What are the historical trends in food inflation?
- How do food inflation trends compare to alcoholic beverage prices?
- What are the seasonal patterns and long-term trends?
- Can we accurately forecast CPI using econometric models?
- How can users interactively explore and compare different forecasting models?

## Shiny App: Interactive Features
- Time-Based Slider: Enables users to analyze food price trends over time.
- Category Dropdown: Allows selection of food categories such as meats and dairy.
- Predictive Analysis: Forecasts food CPI for 2025, analyzing potential inflation trends.

## Shiny App: Interactive Features

User Inputs:
- Dropdown: Select CPI category (Food at Home / Alcoholic Beverages)
- Slider: Choose date range (e.g., 2015–Present)
- RadioButtons: Compare different forecast models
- RadioButtons: Compare different volatility models

Outputs:
1. Time Series Visualization:
  - Historical CPI trends
  - CPI Growth Rate (Returns)
2. Forecasting Models:
  - Compare ARIMA vs Prophet vs SES vs EWMA vs Holt-Winters
  - Show MAE (MAE), RMSE, and MAPE (Performance Metrics) results
  - Allow users to download forecasts
3. Volatility Analysis:
  - GARCH & EWMA models
  - Autocorrelation plots

Datasets will be combined based on observed dates. Total expenditures for "Food at Home" and "Alcoholic Beverages" will be summed and compared with yearly CPI percentage changes, and predictive modeling techniques such as machine learning approaches may be explored for forecasting. This Shiny app will provide an interactive and data-driven way to explore food inflation trends and potential future price shifts.

## Libraries Used

- *library(shiny)*
- *library(ggplot2)*
- *library(dplyr)*
- *library(forecast)*
- *library(prophet)*
- *library(tseries)*
- *library(rugarch)*
- *library(TTR)*
- *library(stats)*
- *library(FactoMineR)*
- *library(factoextra)*
- *library(shinyWidgets)*
- *library(DT)*

# Preview of Shiny App

![](images/updated_shiny_dashboard.png)

## References
 - FRED Economic Data, CPI for U.S. City Average: Monthly, Seasonally Adjusted:[ https://fred.stlouisfed.org/](https://fred.stlouisfed.org/release/tables?rid=10&eid=34483#snid=34486)
