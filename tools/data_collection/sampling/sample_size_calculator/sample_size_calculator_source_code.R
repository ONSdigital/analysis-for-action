################################################################################
#########               Pandemic Preparedness Toolkit             ##############
########  Sample Size Calculator for Household Survey Sampling    ##############
################################################################################

install.packages("tidyverse")

library (tidyverse)

install.packages("shiny")

library(shiny)

# ---------------- UI ----------------
ui <- fluidPage(
  titlePanel("Sample Size Calculator for Household Survey"),
  
  sidebarLayout(
    sidebarPanel(
      numericInput("conf", "Confidence Level (%)", value = 95, min = 80, max = 99),
      numericInput("p", "Expected Proportion (p)", value = 0.5, min = 0, max = 1, step = 0.01),
      numericInput("e", "Margin of Error (d)", value = 0.05, min = 0.01, max = 0.2, step = 0.01),
      numericInput("deff", "Design Effect (DEFF)", value = 1, min = 1, step = 0.1),
      numericInput("nr", "Non-response Rate (%)", value = 10, min = 0, max = 100),
      
      # Loss to Follow-up with Hover Tooltip info icon
      numericInput("lfu", 
                   label = tags$span(
                     "Loss to Follow-up (%)", 
                     shiny::icon("info-circle", style = "color: #007bff; cursor: help;"), 
                     title = "Only applicable for followup study"
                   ), 
                   value = 0, min = 0, max = 100),
      
      numericInput("N", "Population Size (N, if available)", value = NA, min = 1),
      
      # Buttons grouped together
      actionButton("calc", "See Sample Size", class = "btn-primary"),
      actionButton("reset", "Reset", class = "btn-danger"),
      
      br(), br(),
      downloadButton("download", "Download Result")
    ),
    
    mainPanel(
      h3("Result"),
      verbatimTextOutput("result"),
      br(),
      p("Cochran Sampling Formula (n): [Z^2 * p * (1 - p)] / d^2"),
      p("Adjustments: apply DEFF, finite population correction (if N provided), 
        then inflate for non-response and loss to follow-up separately.")
    )
  )
)

# ---------------- SERVER ----------------
# Added 'session' to the function arguments to allow updating inputs
server <- function(input, output, session) {
  result_data <- reactiveVal(NULL)
  
  # --- Calculation Logic ---
  observeEvent(input$calc, {
    # Convert confidence level to Z value
    alpha <- 1 - (input$conf / 100)
    z <- qnorm(1 - alpha / 2)
    
    # Initial sample size
    n0 <- (z^2 * input$p * (1 - input$p)) / (input$e^2)
    
    # Apply design effect
    n1 <- n0 * input$deff
    
    # Finite population correction (if population size provided)
    if (!is.na(input$N) && input$N > 0) {
      n_fpc <- (n1 * input$N) / (n1 + (input$N - 1))
    } else {
      n_fpc <- n1
    }
    
    # Non response adjustment
    nr_factor <- 1 / (1 - input$nr/100)
    n_nr <- n_fpc * nr_factor
    
    # Loss to followup adjustment
    lfu_factor <- 1 / (1 - input$lfu/100)
    n_final <- n_nr * lfu_factor
    
    # Create result data frame
    res <- data.frame(
      Step = c("Initial sample size", 
               "After Design Effect", 
               "After FPC", 
               "After Non-response", 
               "After Loss to Follow-up"),
      Sample_Size = c(ceiling(n0), ceiling(n1), ceiling(n_fpc), 
                      ceiling(n_nr), ceiling(n_final))
    )
    result_data(res)
    
    output$result <- renderPrint({
      res
    })
  })
  
  # --- Reset Logic ---
  observeEvent(input$reset, {
    # Reset all inputs to their original default values
    updateNumericInput(session, "conf", value = 95)
    updateNumericInput(session, "p", value = 0.5)
    updateNumericInput(session, "e", value = 0.05)
    updateNumericInput(session, "deff", value = 1)
    updateNumericInput(session, "nr", value = 10)
    updateNumericInput(session, "lfu", value = 0)
    updateNumericInput(session, "N", value = NA)
    
    # Clear the calculated result display
    result_data(NULL)
    output$result <- renderPrint({
      cat("Fields reset. Click 'See Sample Size' to calculate.")
    })
  })
  
  # --- Download Handler ---
  output$download <- downloadHandler(
    filename = function() {
      paste0("sample_size_result_", Sys.Date(), ".csv")
    },
    content = function(file) {
      # Handle case where download is clicked before calculation
      if(is.null(result_data())){
        write.csv(data.frame(Message = "No calculation performed"), file, row.names = FALSE)
      } else {
        write.csv(result_data(), file, row.names = FALSE)
      }
    }
  )
}

# RUN APP
shinyApp(ui = ui, server = server)
