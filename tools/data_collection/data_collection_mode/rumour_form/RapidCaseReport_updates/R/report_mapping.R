#' Update Geographic Hierarchy State
#'
#' @description Updates a generic geographic level (level1, level2, level3) within the location state list.
#' Automatically clears lower-level geographies when a higher-level one changes.
#'
#' @param current_location A list representing the current state of selected generic locations.
#' @param target_level Character. The geographic hierarchy level to update ("level1", "level2", "level3").
#' @param value Character or Numeric. The new value to assign to the specified level.
#'
#' @return A modified list containing the updated location state.
#' @export
update_location <- function(current_location, target_level, value) {
  
  if (target_level == "level1") {
    current_location$level1 <- value
    current_location$level2 <- ""
    current_location$level3 <- ""
    
  } else if (target_level == "level2") {
    current_location$level2 <- value
    current_location$level3 <- ""
    
  } else if (target_level == "level3") {
    # If specific formatting like zero-padding is needed, it is better 
    # to handle that in the data processing step, but it can be done here.
    current_location$level3 <- as.character(value)
  }
  
  return(current_location)
}

#' Plot Spatial Object on Map
#'
#' @description Updates a Leaflet map to focus on a spatial object and optionally draw it.
#'
#' @param map_id Character. The ID of the Leaflet map.
#' @param sf_object sf object. The spatial features to plot.
#' @param session The Shiny session object.
#' @param color Character. Border color.
#' @param weight Numeric. Stroke weight.
#' @param draw Logical. If TRUE, clears previous shapes and draws the new ones.
#'
#' @export
plot_on_map <- function(map_id, sf_object, session, color = "blue", weight = 2, draw = FALSE) {
  # Validate and calculate geometry
  sf_object <- sf::st_make_valid(sf_object)
  bbox <- sf::st_bbox(sf_object)
  zoom_level <- get_zoom(bbox) # Defined in utils.R
  
  centroid <- sf::st_centroid(sf_object)
  coords <- sf::st_coordinates(centroid)
  
  proxy <- leaflet::leafletProxy(map_id, session = session)
  
  if (draw) {
    proxy <- proxy %>%
      leaflet::clearShapes() %>%
      leaflet::addPolygons(data = sf_object, color = color, weight = weight)
  }
  
  proxy %>%
    leaflet::setView(lng = coords[1], lat = coords[2], zoom = zoom_level) %>%
    leaflet::fitBounds(bbox$xmin, bbox$ymin, bbox$xmax, bbox$ymax)
}

#' Plot Generic Level 3 Areas on Map
#'
#' @description Renders the finest geographic level (e.g., census fractions) on a Leaflet map. 
#' Highlights a specifically selected area and updates the corresponding UI text input.
#'
#' @param map_id Character. The ID of the Leaflet map output.
#' @param sf_level3 An sf object containing all shapes for the current Level 3 context.
#' @param country Character. The selected country name.
#' @param geo_config List. The global geographic configuration.
#' @param selected_id Character or NULL. The specific ID of the area to highlight.
#' @param session The Shiny session object.
#'
#' @export
plot_fractions <- function(map_id, sf_level3, country, geo_config, selected_id, session) {
  
  # 1. Retrieve the specific ID column name for Level 3 from the config
  l3_cfg <- geo_config[[country]]$mapping$fraction
  id_col <- l3_cfg$spatial_id
  
  # 2. Draw all available areas in the current context (e.g., all fractions in a department)
  # We use the dynamic ID column for the layerId to ensure click events return the correct value
  leaflet::leafletProxy(map_id, session = session) %>%
    leaflet::clearShapes() %>%
    leaflet::addPolygons(
      data = sf_level3, 
      color = "red", 
      weight = 2,
      layerId = as.character(sf_level3[[id_col]])
    )
  
  # 3. Handle specific selection highlighting
  if (!is.null(selected_id) && selected_id != "") {
    # Filter the sf object using the dynamic ID column
    selected_row <- sf_level3[as.character(sf_level3[[id_col]]) == as.character(selected_id), ]
    selected_row <- sf::st_make_valid(selected_row)
    
    # Update the UI text box (now generic Level 3 ID)
    shiny::updateTextInput(session, "level3", value = paste("Selected Area ID:", selected_id))
    
    # Highlight the selection in green and focus the map
    leaflet::leafletProxy(map_id, session = session) %>%
      leaflet::addPolygons(
        data = selected_row, 
        color = "green", 
        weight = 3,
        layerId = selected_id
      )
    
    # Reuse your existing zoom logic
    plot_on_map(map_id, selected_row, session)  
    
  } else {
    # Reset text if no specific area is selected
    shiny::updateTextInput(session, "level3", value = "Select on the map")
  }
}