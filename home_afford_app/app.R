source("helper.R")
library(shiny)
library(gridlayout)
library(tidyverse)
library(lubridate)
library(scales)

# App template from the shinyuieditor
ui <- grid_page(
  layout = c(
    "header header",
    "savings linePlot",
    "home_input home_output"
  ),
  row_sizes = c(
    "60px",
    "400px",
    "400px"
  ),
  col_sizes = c(
    "260px",
    "1fr"
  ),
  gap_size = "1rem",
  grid_card(
    area = "savings",
    item_alignment = "top",
    title = "Savings Estimator",
    item_gap = "12px",
    numericInput(
      inputId = "init_savings",
      label = "Current Savings",
      value = 1000L
    ),
    numericInput(
      inputId = "monthly_income",
      label = "Monthly Income (net)",
      value = 1000L
    ),
    numericInput(
      inputId = "expenses",
      label = "Monthly Expenses",
      value = 1000L
    ),
    dateRangeInput(
      inputId = "dates",
      label = "Date Range",
      format = "mm-dd-yyyy"
    )
  ),
  grid_card_text(
    area = "header",
    content = "Home Savings",
    alignment = "start",
    is_title = FALSE
  ),
  grid_card_plot(area = "linePlot"),
  grid_card(
    area = "home_input",
    title = "Home Affordability",
    item_gap = "12px",
    numericInput(
      inputId = "yearly_income",
      label = "Yearly Income (gross)",
      value = 60000L
    ),
    sliderInput(
      inputId = "percent",
      label = "Down Payment %",
      min = 0L,
      max = 100L,
      value = 20L,
      width = "100%"
    ),
    numericInput(
      inputId = "term",
      label = "Loan Term (years)",
      value = 30L
    ),
    numericInput(
      inputId = "rate",
      label = "Interest Rate",
      value = 4L
    )
  ),
  grid_card(
    area = "home_output",
    item_gap = "12px",
    tagAppendAttributes(textOutput(outputId = "homeAmount"),
      style = "white-space:pre-wrap;"
    )
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

  output$linePlot <- renderPlot({
    # calculate savings from income and expenses
    savings <- monthly_savings(input$monthly_income, input$expenses)
    # create df from init_savings, savings, start_date, and end_date
    df <- create_savingsdf(init_savings = input$init_savings,
                           savings,
                           start_date = input$dates[1],
                           end_date = input$dates[2])
    # plot savings over date range
    ggplot(df, aes(x = Date, y = Savings, group = 1)) +
      geom_line() + scale_x_date(date_labels = "%b-%Y") + 
      scale_y_continuous(labels=scales::dollar_format())
  })
  
  output$homeAmount <- renderText({
    # calculate how much home you can afford based on inputs
    mortgage <- mortgage_payment(input$yearly_income)
    loan <- calculate_loan(input$yearly_income, input$rate, input$term)
    home_price <- calculate_home_price(loan)
    down_payment <- down_payment(loan, input$percent)
    # display results
    homePrice <- paste("Home Price: ", dollar(home_price, largest_with_cents = 100))
    downPayment <- paste("Down Payment: ", dollar(down_payment, largest_with_cents = 100))
    mortgageAmount <- paste("Mortgage Amount: ", dollar(loan, largest_with_cents = 100))
    monthlyPayment <- paste("Monthly Payment: ", dollar(mortgage, largest_with_cents = 100))
    paste(homePrice, downPayment, mortgageAmount, monthlyPayment, sep="\n")
  })

}

shinyApp(ui, server)


