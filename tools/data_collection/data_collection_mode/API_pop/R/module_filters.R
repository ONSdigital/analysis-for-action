#' Filters Module UI
#'
#' Generates the user interface for the dynamic filters module. This includes
#' a container for the dynamically generated filter inputs, action buttons to run 
#' or reset queries, and a dropdown for selecting the population source layer.
#'
#' @param id Character string. The namespace ID for the Shiny module.
#'
#' @return A Shiny UI `tagList` object containing the filter controls.
#' @export
filtersUI <- function(id) {
  ns <- NS(id)
  tagList(
    uiOutput(ns("filter_ui")),
    div(class = "btn-container",
        actionButton(ns("run"), "Run Query", class = "btn-block"),
        actionButton(ns("reset"), "Reset Selections") 
    ),
    selectInput(ns("pop_layer"), "Population Source:", choices = c("Select Location first" = ""), selected = "")
  )
}

#' Filters Module Server
#' Standardized for Generic Level Keys (level1, level2, level3)
#' @export
filtersServer <- function(id, columns, display_names, population_layers) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # --- 1. Render Dynamic Filters ---
    output$filter_ui <- renderUI({
      # 1. Validation: Don't render if columns haven't loaded
      if (is.null(columns) || length(columns) == 0) return(tags$p("Initializing filters..."))
      
      tryCatch({
        tagList(
          lapply(names(columns), function(col) {
            # --- A. Safe Data Extraction ---
            col_str <- as.character(col)
            col_type <- as.character(columns[[col_str]])
            
            # Ensure display name is never NULL or empty
            display <- if(col_str %in% names(display_names)) as.character(display_names[[col_str]]) else col_str
            if(length(display) == 0 || is.na(display) || display == "") display <- col_str
            
            # --- B. The Filter Container ---
            # We use a simple div here. Our CSS handles the white box and stacking.
            div(class = "filter-box",
                # Top Level: The Toggle Checkbox
                div(
                  checkboxInput(ns(paste0("chk_", col_str)), display, value = FALSE)
                ),
                
                # Sub Level: The Actual Inputs (Visible only when checked)
                conditionalPanel(
                  condition = sprintf("input.chk_%s == true", col_str),
                  ns = ns,
                  tags$hr(),
                  
                  # --- C. Logic by Type ---
                  # Each input is placed directly in the tagList to follow the CSS block rules
                  if(col_type == "text") {
                    textInput(ns(paste0("val_", col_str)), NULL, placeholder = paste("Enter", display))
                  } 
                  
                  else if (col_type == "text_logic") {
                    tagList(
                      textInput(ns(paste0("val_", col_str)), display, placeholder = paste("Enter", display)),
                      div(class = "btn-container",
                          actionButton(ns(paste0("btn_and_", col_str)), "AND"), 
                          actionButton(ns(paste0("btn_or_", col_str)), "OR")
                      )
                    )
                  } 
                  
                  else if(col_type == "date_or_range") {
                    tagList(
                      radioButtons(ns(paste0("mode_", col_str)), "Filter type", 
                                   choices = c("Exact" = "exact", "Range" = "range"), inline = TRUE),
                      conditionalPanel(
                        condition = sprintf("input.mode_%s == 'exact'", col_str),
                        ns = ns,
                        dateInput(ns(paste0("val_", col_str)), paste("Select", display))
                      ),
                      conditionalPanel(
                        condition = sprintf("input.mode_%s == 'range'", col_str),
                        ns = ns,
                        dateRangeInput(ns(paste0("valrange_", col_str)), paste("Select", display, "range"))
                      )
                    )
                  } 
                  
                  else if(col_type == "age") {
                    sliderInput(ns("age_range"), "Select Age range", min=0, max=120, value=c(0,120))
                  } 
                  
                  else if(col_type == "geography") {
                    # Standardized geography dropdowns
                    tagList(
                      selectInput(ns("country"), "Country", choices = c("", names(ALL_CONFIGS))),
                      selectInput(ns("level1"), "Province", choices = ""),
                      selectInput(ns("level2"), "Department", choices = ""),
                      selectInput(ns("level3"), "Fraction", choices = "")
                    )
                  }
                )
            )
          })
        )
      }, error = function(e) {
        message("UI Rendering Error: ", e$message)
        tags$p(style="color:red; font-weight:bold;", paste("UI Error:", e$message))
      })
    })
    
    # --- 2. Standardized Location Cascading Logic ---
    
    # --- Cascading Geography Logic (module_filters.R) ---
    
    # 1. Country Selection -> Load Provinces (Level 1)
    observeEvent(input$country, {
      req(input$country)
      
      # Reset lower levels immediately to prevent "ghost" data from previous selections
      updateSelectInput(session, "level1", choices = "")
      updateSelectInput(session, "level2", choices = "")
      updateSelectInput(session, "level3", choices = "")
      
      if (input$country == "" || input$country == "(Select Country)") return()
      
      # Get country-specific file path from the Global Config
      country_cfg <- ALL_CONFIGS[[input$country]]
      specific_gpkg <- here::here("data", country_cfg$file_name)
      
      # Fetch Level 1 options
      opts <- fetch_options(
        gpkg_path = specific_gpkg, 
        country = input$country, 
        level_key = "level1"
      )

      session$userData$level1_choices <- opts
      
      updateSelectInput(session, "level1", choices = c("", sort(opts)))
    })
    
    # 2. Level 1 Selection -> Load Departments (Level 2)
    observeEvent(input$level1, {
      req(input$level1, input$country)
      
      # Reset lower levels
      updateSelectInput(session, "level2", choices = "")
      updateSelectInput(session, "level3", choices = "")
      
      if (input$level1 == "") return()
      
      country_cfg <- ALL_CONFIGS[[input$country]]
      specific_gpkg <- here::here("data", country_cfg$file_name)
      
      # Fetch Level 2 using Level 1 as the parent
      opts <- fetch_options(
        gpkg_path = specific_gpkg, 
        country = input$country, 
        level_key = "level2", 
        parent_key = "level1", 
        parent_val = input$level1
      )
      session$userData$level2_choices <- opts
      
      updateSelectInput(session, "level2", choices = c("", sort(opts)))
    })
    
    # 3. Level 2 Selection -> Load Fractions (Level 3)
    observeEvent(input$level2, {
      req(input$level2, input$level1, input$country)
      
      # Reset the lowest level
      updateSelectInput(session, "level3", choices = "")
      
      if (input$level2 == "") return()
      
      country_cfg <- ALL_CONFIGS[[input$country]]
      specific_gpkg <- here::here("data", country_cfg$file_name)
      
      # Fetch Level 3 using Level 2 as the parent
      opts <- fetch_options(
        gpkg_path = specific_gpkg, 
        country = input$country, 
        level_key = "level3", 
        parent_key = "level2", 
        parent_val = input$level2
      )
      session$userData$level3_choices <- opts
      
      updateSelectInput(session, "level3", choices = c("", sort(opts)))
    })
    
    # --- 3. Text Logic Helpers ---
    observe({
      lapply(names(columns)[columns == "text_logic"], function(col) {
        observeEvent(input[[paste0("btn_and_", col)]], {
          current <- input[[paste0("val_", col)]]
          updateTextInput(session, paste0("val_", col), 
                          value = paste0(trimws(current), ifelse(is.null(current) || current == "", "", " "), "and "))
        })
        observeEvent(input[[paste0("btn_or_", col)]], {
          current <- input[[paste0("val_", col)]]
          updateTextInput(session, paste0("val_", col), 
                          value = paste0(trimws(current), ifelse(is.null(current) || current == "", "", " "), "or "))
        })
        output[[paste0("preview_", col)]] <- renderUI({
          txt <- input[[paste0("val_", col)]]
          if (is.null(txt) || txt == "") return(NULL)
          txt <- gsub("\\band\\b", "<span style='color:red;font-weight:bold'>and</span>", txt, ignore.case = TRUE)
          txt <- gsub("\\bor\\b", "<span style='color:red;font-weight:bold'>or</span>", txt, ignore.case = TRUE)
          HTML(txt)
        })
      })
    })
    
    # --- 4. Reset Button Logic ---
    observeEvent(input$reset, {
      for (col in names(columns)) {
        updateCheckboxInput(session, paste0("chk_", col), value = FALSE)
      }
      updateSelectInput(session, "country", selected = "")
      updateSelectInput(session, "level1", choices = "")
      updateSelectInput(session, "level2", choices = "")
      updateSelectInput(session, "level3", choices = "")
    })
    
    # --- 5. Return Filter Values ---
    active_filters <- eventReactive(input$run, {
      eq_filters <- list(); range_filters <- list()
      
      # Renamed local wrapper to avoid colliding with utils.R
      clean_input <- function(x) { 
        if (is.null(x) || length(x) == 0) return(NULL)
        
        val <- x[1] 
        if (is.na(val) || val == "") return(NULL)
        
        # Calls your newly renamed global function from utils.R
        return(normalize(val)) 
      }
      
      # 1. Standard Filters (Symptoms, Diagnosis, etc.)
      for (col in names(columns)) {
        if (!isTRUE(input[[paste0("chk_", col)]])) next
        col_type <- columns[[col]]
        
        if (col_type %in% c("text", "text_logic")) {
          val <- clean_input(input[[paste0("val_", col)]])
          if (!is.null(val)) eq_filters[[col]] <- val
        } else if (col_type == "date_or_range") {
          mode <- input[[paste0("mode_", col)]]
          if (mode == "exact") {
            val <- clean_input(input[[paste0("val_", col)]])
            if (!is.null(val)) eq_filters[[col]] <- as.Date(val)
          } else {
            rng <- input[[paste0("valrange_", col)]]
            if (!is.null(rng)) range_filters[[col]] <- as.Date(rng)
          }
        }
      }
      
      # 2. Geography Logic 
      if (isTRUE(input$chk_location)) {
        
        get_name <- function(id_val, choices) {
          if (!isTruthy(id_val)) return(NULL)
          lbl <- names(choices)[which(choices == id_val)]
          if (length(lbl) == 0) return(id_val)
          return(lbl[1])
        }
        
        geo_values <- list(
          country = input$country,
          level1  = get_name(input$level1, session$userData$level1_choices),
          level2  = get_name(input$level2, session$userData$level2_choices),
          level3  = input$level3 
        )
        
        for (col in names(geo_values)) {
          val <- clean_input(geo_values[[col]])
          if (!is.null(val)) eq_filters[[col]] <- val
        }
      }
      
      list(
        eq_filters = eq_filters,
        range_filters = range_filters,
        age_range = input$age_range,
        country = input$country,
        level1 = input$level1,
        level2 = input$level2
      )
    })
    
    return(active_filters)
  })
}