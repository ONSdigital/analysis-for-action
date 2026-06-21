#' Case Report UI
#' @param id Character. The module ID.
#' @export
caseReportUI <- function(id) {
  ns <- NS(id)
  
  fluidPage(
    useShinyjs(),
    tags$head(
      tags$title("Rapid Case Report"),
      tags$link(rel = "stylesheet", type = "text/css", href = "config.css")
    ),
    
    div(class = "nav-bar",
        div(class = "nav-content",
            div(class = "header-logo-left")
        )
    ),
    

    div(class = "hero-section",
        div(class = "hero-content",
            h1(class = "app-title", "Rapid Case Report"),
            div(class = "breadcrumb-text", "Online form for rapid reporting of suspected cases.")
        )
    ),
    
    div(class = "content-wrapper",
        div(class = "well-custom",
            
            sidebarLayout(
              sidebarPanel(style = "background-color: #c2c2c2;",
                           
                           h3("General Information"),
                           dateInput(ns("consultation_date"), "Consultation Date:", max = Sys.Date()),
                           selectInput(ns("sex"), "Sex:", choices = c("", "Male", "Female", "Other", "Prefer not to say")),
                           dateInput(ns("birth_date"), "Birth Date:", max = Sys.Date()),
                           
                           h3("Location"),
                           geoLocationUI(ns("geo"))$sidebar,
                           
                           h3("Symptoms"),
                           dateInput(ns("symptom_onset_date"), "Symptom Onset Date:", max = Sys.Date()),
                           textAreaInput(ns("symptom_description"), "Symptom Description:", ""),
                           
                           h3("Suspected Diagnosis"),
                           textAreaInput(ns("suspected_diagnosis"), "Suspected Diagnosis:", ""),
                           
                           h3("Professional's Information"),
                           textInput(ns("email"), "Email:", placeholder = "Enter your email"),
                           textInput(ns("institution"), "Institution:", placeholder = "Enter your institution"),
                           
                           actionButton(ns("load"), "Upload Information")
              ),
              
              mainPanel(
                div(style = "margin-top: 50px; width: 150%; overflow: visible; margin-bottom: 20px;",
                    geoLocationUI(ns("geo"))$main
                ),
                
                verbatimTextOutput(ns("submission_status")),
                div(class = "table-container",
                    tableOutput(ns("form_preview"))
                )
              )
            ),
            div(style = "margin-top: 10px; text-align: left;",
                downloadButton(ns("download_data"), "Download Reported Cases (CSV)")
            )
        )
    ),
    actionButton(ns("download_db"), "Download from Database", style = "
      background-color: transparent; 
      color: grey; 
      font-size: 12px; 
      border: none;
      padding: 0;
      cursor: pointer;"),
    downloadButton(ns("file_download"), "Download Now", style = "display:none;")
  )
}



#' Rapid Report Server
#'
#' @param id Character. The module ID.
#' @param selected_location Reactive. The geographic state from the geoLocation module.
#' @param pool The active database connection pool (Cloud or Local).
#' @export
caseReportServer <- function(id, selected_location, pool) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # --- Local State for current session only ---
    form_records <- reactiveVal(data.frame())
    
    # --- 1. Load & Validate Observer ---
    observeEvent(input$load, {
      loc <- selected_location()
      
      # Perform validation first
      errors <- validate_form_inputs(
        consultation_date = input$consultation_date,
        birth_date = input$birth_date,
        sex = input$sex,
        loc = loc,
        symptom_description = input$symptom_description,
        suspected_diagnosis = input$suspected_diagnosis,
        email = input$email,
        institution = input$institution
      )
      
      if (length(errors) > 0) {
        showModal(modalDialog(
          title = "Missing or invalid information",
          HTML(paste0("<b>", errors, "</b>", collapse = "<br>")),
          easyClose = TRUE
        ))
        return()
      }
      
      # --- Extract Dynamic Labels from config.json ---
      # We fetch the specific names (e.g., 'Province') defined for this country
      mapping_names <- names(geo_config[[loc$country]]$mapping)
      label_l1 <- mapping_names[1] # e.g., "province"
      label_l2 <- mapping_names[2] # e.g., "department"
      label_l3 <- mapping_names[3] # e.g., "fraction"
      
      # --- Show Confirmation Modal ---
      showModal(modalDialog(
        title = "Confirm Submission",
        HTML(paste0(
          "<h3>Summary of Information</h3>",
          "<b>Consultation Date:</b> ", input$consultation_date, "<br/>",
          "<b>Birth Date:</b> ", input$birth_date, "<br/>", # Added Birth Date
          "<b>Sex:</b> ", input$sex, "<br/>",
          "<b>Symptoms:</b> ", input$symptom_description, "<br/>",
          "<b>Symptoms Onset Date:</b> ", input$symptom_onset_date, "<br/>",
          "<hr>",
          "<b>Country:</b> ", loc$country, "<br/>",
          "<b>", label_l1, ":</b> ", loc$level1, "<br/>", # Dynamic Label 1
          "<b>", label_l2, ":</b> ", loc$level2, "<br/>", # Dynamic Label 2
          "<b>", label_l3, " (ID):</b> ", loc$level3, "<br/>", # Dynamic Label 3
          "<hr>",
          "<b>Email:</b> ", input$email
        )),
        footer = tagList(
          modalButton("Cancel"),
          actionButton(ns("confirm_modal"), "Confirm") 
        )
      ))
    })
    
    # --- 2. Final Confirmation & DB Write ---
    observeEvent(input$confirm_modal, {
      loc <- selected_location()
      
      # Prepare data via generic processing logic
      new_entry <- format_new_entry(input, loc)
      
      # Insert to DB using the passed pool
      insert_to_db(new_entry, pool)
      
      # Update session-only reactive value for the UI table
      form_records(dplyr::bind_rows(form_records(), new_entry))
      
      removeModal()
      showNotification("Submission Successful", type = "message")
      
      # Render updated preview table
      # Render updated preview table with dynamic headers
      output$form_preview <- renderTable({
        req(nrow(form_records()) > 0)
        
        # 1. Extract the data for the preview
        df <- form_records() %>%
          dplyr::select(consultation_date, birth_date, sex, level1, level2, level3, symptom_description) %>%
          dplyr::mutate(
            consultation_date = format(as.Date(consultation_date), "%d/%m/%Y"),
            birth_date = format(as.Date(birth_date), "%d/%m/%Y")
          )
        
        # 2. Get the dynamic labels from the current country in config
        current_country <- selected_location()$country
        mapping_names <- names(geo_config[[current_country]]$mapping)
        
        # 3. Apply the dynamic names to the columns
        colnames(df) <- c(
          "Consultation", 
          "Birth Date", 
          "Sex", 
          mapping_names[1], # e.g., "Province"
          mapping_names[2], # e.g., "Department"
          mapping_names[3], # e.g., "Fraction"
          "Symptoms"
        )
        
        return(df)
      }, bordered = TRUE, align = 'c')
      
      # Reset UI inputs for next entry
      updateDateInput(session, "consultation_date", value = Sys.Date())
      updateTextInput(session, "sex", value = "")
      updateDateInput(session, "birth_date", value = Sys.Date())
      updateTextInput(session, "symptom_description", value = "")
      updateTextInput(session, "suspected_diagnosis", value = "")
    })
    
    # --- 3. Current Session Download (CSV) ---
    output$download_data <- downloadHandler(
      filename = function() {
        paste0("session_records_", Sys.Date(), ".csv")
      },
      content = function(file) {
        data <- form_records()
        if (nrow(data) == 0) {
          showNotification("No data in current session to download.", type = "error")
          return(NULL)
        }
        write.csv(data, file, row.names = FALSE)
      }
    )
    
    # --- 4. User-Specific History Download (SQL Query) ---
    observeEvent(input$download_db, {
      showModal(modalDialog(
        title = "Download Your History",
        textInput(ns("email_download_input"), "Enter Email:"),
        footer = tagList(
          modalButton("Cancel"),
          downloadButton(ns("confirm_user_download"), "Download CSV")
        ),
        easyClose = TRUE
      ))
    })
    
    output$confirm_user_download <- downloadHandler(
      filename = function() {
        paste0("history_", input$email_download_input, "_", Sys.Date(), ".csv")
      },
      content = function(file) {
        # Requirement: Ensure the email input isn't empty
        req(input$email_download_input)
        
        # 1. Fetch data using the refactored SQL function and the passed 'pool'
        user_data <- download_email_data(input$email_download_input, pool)
        
        # 2. Defensive check: If no data is found, notify the user
        if (is.null(user_data) || nrow(user_data) == 0) {
          shinyjs::runjs('alert("No records found for this email.");')
          return(NULL)
        }
        
        # 3. Write the queried data frame to the temporary file
        write.csv(user_data, file, row.names = FALSE)
        
        # Close the modal after a successful download trigger
        removeModal()
      }
    )
    
  })
}