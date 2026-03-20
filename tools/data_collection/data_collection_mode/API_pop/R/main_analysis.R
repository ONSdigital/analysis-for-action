#' @title Main Analysis Module - UI
#' @export
analysisUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Load CSS and Title for this module
    tags$head(
      tags$title("API Population"),
      tags$link(rel = "stylesheet", type = "text/css", href = "config.css")
    ),
    
    # 1. Top Navigation Bar
    div(class = "nav-bar",
        div(class = "nav-content",
            div(class = "header-logo-left") 
        )
    ),
    
    # 2. Hero Title Section
    div(class = "hero-section",
        div(class = "hero-content",
          #  div(class = "breadcrumb-text", "Analysis / Population"), 
            h1(class = "app-title", "API Population")                
        )
    ),
    
    # 3. Main Application Content
    div(class = "content-wrapper",
        # REMOVED max-width constraint to allow full-screen expansion
        div(style = "width: 100%; padding: 0 20px;", 
            sidebarLayout(
              sidebarPanel(
                style = "background-color: #c2c2c2; width: 100%;",
                h3("API - POP"),
                
                # Call Upload Module UI
                uploadUI(ns("upload_mod")),
                
                h3("Filter by"),
                
                # Call Filters Module UI
                filtersUI(ns("filters_mod")),
                
                # Output bindings for Results Module Downloads
                div(class = "btn-container",
                    downloadButton(ns("results_mod-download_csv"), "Cases List"),
                    downloadButton(ns("results_mod-download_summary_csv"), "Weekly Summary")
                )
              ),
              mainPanel(
                # Output binding for Results Module Table
                tableOutput(ns("results_mod-results"))
              )
            )
        )
    )
  )
}

#' @title Main Analysis Module - Server Logic
#'
#' @description
#' Handles the backend orchestration for the main analysis module. Rather than
#' executing logic directly, it delegates tasks to specialized sub-modules 
#' (\code{uploadServer}, \code{filtersServer}, \code{resultsServer}) and 
#' handles the primary database query based on the active filters.
#'
#' @param id Character string. The namespace identifier.
#' @param con DBI Connection object.
#' @param gpkg_path Character string. Path to the geometry .gpkg file.
#'
#' @import shiny
#' @import DBI
#' @export
analysisServer <- function(id, con, gpkg_path) {
  moduleServer(id, function(input, output, session) {
    
    # 1. Initialize Upload Sub-Module
    uploadServer(
      id = "upload_mod", 
      con = con, 
      target_table = "reports", 
      target_cols = reports_cols
    )
    
    # 2. Initialize Filters Sub-Module
    active_filters <- filtersServer(
      id = "filters_mod", 
      columns = columns, 
      display_names = display_names, 
      population_layers = population_layers
    )
    
    # --- 3. Main Data Query Logic ---
    data_reactive <- reactive({
      req(active_filters())
      filters <- active_filters()
      
      # A. Determine geographic columns (This handles the UI layout)
      if (isTruthy(filters$country) && !is.null(ALL_CONFIGS[[filters$country]])) {
        base_geo_cols <- ALL_CONFIGS[[filters$country]]$levels
      } else {
        base_geo_cols <- c("country")
      }
      
      # B. Build the SELECT statement
      select_cols <- c("suspected_diagnosis", "symptom_description", "symptom_onset_date",
                       base_geo_cols, 
                       "consultation_date", "sex", 
                       "CAST((julianday(consultation_date) - julianday(birth_date)) / 365.25 AS INT) AS Age")
      
      sql <- paste("SELECT", paste(select_cols, collapse = ", "), 
                   "FROM", DBI::dbQuoteIdentifier(con, "reports"))
      

      # Combine standard filters with these geography selections
      # This ensures the SQL builder sees them as equality constraints
      all_filters <- filters$eq_filters
      
      # D. Build the final SQL with the merged list
      sql <- add_filters_to_sql(
        sql = sql, 
        con = con, 
        eq_filters = all_filters, 
        range_filters = filters$range_filters, 
        age_range = filters$age_range
      )
      
      result <- DBI::dbGetQuery(con, sql)
      
      # Just return the result directly! No double-encoding.
      return(result) 
    })
    
    # 4. Initialize Results Sub-Module
    resultsServer(
      id = "results_mod", 
      data_reactive = data_reactive, 
      cols_for_table = cols_for_table, 
      display_names = display_names,
      filter_metadata = reactive({
        list(
          country = active_filters()$country,
          level1 = active_filters()$level1,
          level2 = active_filters()$level2
        )
      }),
      ALL_CONFIGS = ALL_CONFIGS,
      gpkg_path = gpkg_path
    )
    
  })
}