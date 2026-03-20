#' Upload Module UI
#'
#' Generates the user interface for the data upload module, consisting 
#' of a single action button to trigger the upload modal.
#'
#' @param id Character string. The namespace ID for the Shiny module.
#' @return A Shiny UI `actionButton`.
#' @export
uploadUI <- function(id) {
  ns <- NS(id)
  actionButton(ns("upload_btn"), "Upload File")
}

#' Upload Module Server
#'
#' Handles the server-side logic for uploading files (CSV, XLSX, XML, SQLite/DBA),
#' mapping columns to the database schema, appending the data, and triggering 
#' geographic normalization.
#'
#' @param id Character string. The Shiny module ID.
#' @param con A DBIConnection object (or pool).
#' @param target_table Character string. The name of the database table to append data to.
#' @param target_cols Character vector. The expected columns in the target database table.
#' @return NULL
#' @export
uploadServer <- function(id, con, target_table = "reports", target_cols) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    raw_data <- reactiveVal(NULL)
    
    # 1. Open Upload Modal
    observeEvent(input$upload_btn, {
      showModal(modalDialog(
        title = "Upload File",
        fileInput(ns("file"), "Choose file", accept = c(".csv", ".xml", ".xlsx", ".dba")),
        footer = tagList(modalButton("Cancel"), actionButton(ns("confirm_upload"), "Upload"))
      ))
    })
    
    # 2. Process File
    observeEvent(input$confirm_upload, {
      req(input$file)
      filepath <- input$file$datapath
      ext <- tools::file_ext(filepath)
      
      # This now returns a CLEAN UTF-8 dataframe thanks to read_csv_safely
      df <- read_uploaded_file(filepath, ext, target_table)
      
      raw_data(df)
      
      # Show Mapping Modal
      showModal(modalDialog(
        title = "Map Columns",
        uiOutput(ns("mapping_ui")),
        footer = tagList(modalButton("Cancel"), actionButton(ns("final_upload"), "Append Data"))
      ))
    })
    
    # 3. Dynamic Mapping UI (SMART MAPPING)
    output$mapping_ui <- renderUI({
      req(raw_data())
      df_cols <- names(raw_data())
      
      # Find columns that do NOT exactly match the database columns
      unmatched_cols <- setdiff(df_cols, target_cols)
      
      # If everything matches perfectly, just show a success message!
      if (length(unmatched_cols) == 0) {
        return(tags$div(
          class = "alert alert-success",
          style = "background-color: #d4edda; color: #155724; padding: 15px; border-radius: 5px; border: 1px solid #c3e6cb;",
          strong("Success!"), " All columns in your file match the database perfectly. Click 'Append Data' to proceed."
        ))
      }
      
      # Otherwise, only ask about the unmatched columns
      tagList(
        p("The following columns from your file did not match automatically. Please map them to the database, or leave blank to ignore them:"),
        tags$hr(),
        fluidRow(column(6, h5(strong("Your File"))), column(6, h5(strong("Database")))),
        lapply(unmatched_cols, function(fc) {
          fluidRow(
            column(6, p(fc, style = "margin-top: 8px;")),
            column(6, selectInput(ns(paste0("map_", fc)), label = NULL, choices = c("(Ignore)" = "", target_cols), selected = ""))
          )
        })
      )
    })
    
    # 4. Final Append
    observeEvent(input$final_upload, {
      df <- raw_data()
      req(nrow(df) > 0)
      
      # 1. Map columns based on UI
      unmatched_cols <- setdiff(names(df), target_cols)
      for (fc in unmatched_cols) {
        mapped_val <- input[[paste0("map_", fc)]]
        if (!is.null(mapped_val) && mapped_val != "") {
          names(df)[names(df) == fc] <- mapped_val
        }
      }
      
      # 2. Keep only DB columns
      df <- df[, names(df) %in% target_cols, drop = FALSE]
      
      # 3. Normalize cleanly using utils.R before the database append
      if ("country" %in% names(df)) df$country_norm <- normalize(df$country)
      if ("level1" %in% names(df)) df$level1_norm <- normalize(df$level1)
      if ("level2" %in% names(df)) df$level2_norm <- normalize(df$level2)

      # Apply config-driven padding rules
      df <- apply_code_length_rules(df, ALL_CONFIGS)
      
      # 4. Fill remaining columns with NA and reorder
      for (col in setdiff(target_cols, names(df))) {
        df[[col]] <- NA
      }
      df <- df[, target_cols, drop = FALSE]
      
      # 5. Push to Database
      pool::dbAppendTable(con, target_table, df)
      
      removeModal()
      showNotification(paste("Data merged into", target_table, "successfully."), type = "message")
    })
  })
}