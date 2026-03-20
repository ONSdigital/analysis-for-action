#' Geographic Selection UI
#' @export
geoLocationUI <- function(id) {
  ns <- NS(id)
  sidebar <- tagList(
    selectInput(ns("country"), "Select Country:", choices = c("Select a Country" = "")),
    selectInput(ns("level1"), "Select Level 1:", choices = c("No information available" = "")),
    selectInput(ns("level2"), "Select Level 2:", choices = c("No information available" = "")),
    # Read-only text box for the final ID
    shinyjs::disabled(
      textInput(ns("level3"), "Selected Area (ID):", value = "Select on the map", width = "100%")
    ),
    actionButton(ns("reset_geo"), "Reset locations", 
                 icon = icon("sync"), # Standard circular arrow
                 class = "btn-link-custom")
  )
  main <- mainPanel(leafletOutput(ns("map"), height = "600px", width = "100%"))
  list(sidebar = sidebar, main = main)
}

#' Geographic Selection Server
#' 
#' @param id Character. The module ID.
#' @param geo_config List. The configuration object loaded from config.json.
#' @param data_dir Character. The path to the directory containing Geopackages.
#' @export
geoLocationServer <- function(id, geo_config, data_dir) {
  moduleServer(id, function(input, output, session) {
    
    # --- Internal Reactive State ---
    level1_data <- reactiveVal(NULL)
    level2_data <- reactiveVal(NULL)
    level3_data <- reactiveVal(NULL)
    
    selected_location <- reactiveVal(list(
      country = NULL, level1 = NULL, level2 = NULL, level3 = NULL
    ))
    
    # Now valid_countries uses the 'geo_config' passed as an argument
    valid_countries <- names(geo_config)[names(geo_config) != "(Select Country)"]
    updateSelectInput(session, "country", choices = c("Select a Country" = "", valid_countries))
    
    # Initialize the map 
    output$map <- renderLeaflet({
      leaflet() %>% 
        addTiles() %>% 
        setView(lng = -63.6, lat = -38.4, zoom = 5)
    })
    
    # Helper function to clear lower levels
    reset_to_level_1 <- function() {
      updateTextInput(session, "level3", value = "Select on the map")
      updateSelectInput(session, "level2", choices = c("No information available" = ""))
      new_loc <- selected_location()
      new_loc$level2 <- NULL; new_loc$level3 <- NULL
      selected_location(new_loc)
    }
    
    observeEvent(input$reset_geo, {
      # 1. Reset Reactive State
      level1_data(NULL)
      level2_data(NULL)
      level3_data(NULL)
      selected_location(list(country = NULL, level1 = NULL, level2 = NULL, level3 = NULL))
      
      # 2. Reset UI Inputs
      updateSelectInput(session, "country", selected = "")
      updateSelectInput(session, "level1", choices = c("No information available" = ""), selected = "")
      updateSelectInput(session, "level2", choices = c("No information available" = ""), selected = "")
      updateTextInput(session, "level3", value = "Select on the map")
      
      # 3. Reset Map View
      leafletProxy("map") %>%
        clearShapes() %>%
        setView(lng = -63.6, lat = -38.4, zoom = 5)
      
      showNotification("Geographic selections cleared.", type = "message")
    })
    
    # --- Observer: Country Selection ---
    observeEvent(input$country, {
      req(input$country != "")
      reset_to_level_1()
      
      # Use the generic levels from config
      df <- get_info_about("*", input$country, "Level1", geo_config, data_dir)
      level1_data(df)
      
      # Dynamically update labels based on country config
      l1_label <- names(geo_config[[input$country]]$mapping)[1]
      updateSelectInput(session, "level1", label = paste("Select", l1_label, ":"), 
                        choices = c("Select:" = "", unique(df$nam)))
      
      new_loc <- selected_location()
      new_loc$country <- input$country
      selected_location(new_loc)
    })
    
    # --- Observer: Level 1 Selection ---
    observeEvent(input$level1, {
      req(input$level1 != "")
      updateTextInput(session, "level3", value = "Select on the map")
      
      # Find parent ID from selection
      l1_selected <- level1_data()[level1_data()$nam == input$level1, ]
      l1_cfg <- geo_config[[input$country]]$mapping[[1]]
      parent_id <- as.character(unique(l1_selected[[l1_cfg$spatial_id]]))
      
      # Fetch Level 2
      l2_cfg <- geo_config[[input$country]]$mapping[[2]]
      df <- get_info_about("*", input$country, "Level2", geo_config, data_dir, 
                           type = l2_cfg$parent_col, name = parent_id)
      level2_data(df)
      
      updateSelectInput(session, "level2", label = paste("Select", names(geo_config[[input$country]]$mapping)[2], ":"),
                        choices = c("Select:" = "", unique(df$nam)))
      plot_on_map("map", l1_selected, session, draw = TRUE)
      
      selected_location(update_location_state(selected_location(), "level1", input$level1))
    })
    
    # --- Observer: Level 2 Selection ---
    observeEvent(input$level2, {
      req(input$level2 != "")
      l2_selected <- level2_data()[level2_data()$nam == input$level2, ]
      l2_cfg <- geo_config[[input$country]]$mapping[[2]]
      parent_id <- as.character(unique(l2_selected[[l2_cfg$spatial_id]]))
      
      # Fetch Level 3 (Fractions) for Map
      l3_cfg <- geo_config[[input$country]]$mapping[[3]]
      df <- get_info_about("*", input$country, "Level3", geo_config, data_dir, 
                           type = l3_cfg$parent_col, name = parent_id)
      level3_data(df)
      
      plot_on_map("map", l2_selected, session)
      plot_fractions("map", df, input$country, geo_config, NULL, session) 
      selected_location(update_location_state(selected_location(), "level2", input$level2))
    })
    
    # --- Observer: Map Click (Level 3) ---
    observeEvent(input$map_shape_click, {
      clicked_id <- input$map_shape_click$id
      req(clicked_id)
      plot_fractions("map", level3_data(), input$country, geo_config, clicked_id, session)
      selected_location(update_location_state(selected_location(), "level3", clicked_id))
    })
    
    output$map <- renderLeaflet({
      leaflet() %>% addTiles() %>% setView(lng = -63.6, lat = -38.4, zoom = 5)
    })
    
    return(selected_location)
  })
}