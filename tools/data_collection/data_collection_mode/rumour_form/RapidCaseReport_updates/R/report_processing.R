#' Validate Form Inputs
#'
#' @description Checks for required fields and logical date constraints.
#' @return A character vector of error messages (empty if valid).
#' @export
validate_form_inputs <- function(consultation_date, birth_date, sex, loc, symptom_description, suspected_diagnosis, email, institution) {
  errors <- character()
  
  # 1. Check for empty required text/select fields
  if (sex == "") errors <- c(errors, "Please select a Sex.")
  if (email == "") errors <- c(errors, "Email is required.")
  if (institution == "") errors <- c(errors, "Institution is required.")
  if (symptom_description == "") errors <- c(errors, "Symptom description is required.")
  
  # 2. Check Geographic Hierarchy
  if (is.null(loc$country) || loc$country == "") errors <- c(errors, "Please select a Country.")
  if (is.null(loc$level3) || loc$level3 == "" || loc$level3 == "Select on the map") {
    errors <- c(errors, "Please select a specific area on the map (Level 3).")
  }
  
  # 3. Logical Date Checks
  if (birth_date > consultation_date) {
    errors <- c(errors, "Birth date cannot be after the consultation date.")
  }
  
  return(errors)
}


#' Convert Character Columns to UTF-8
#'
#' @description Iterates through all character columns in a data frame and converts their encoding from latin1 to UTF-8.
#'
#' @param df A data frame containing the data to be converted.
#'
#' @return A data frame with character columns converted to UTF-8 encoding.
#' @export
to_utf8 <- function(df) {
  char_cols <- names(df)[sapply(df, is.character)]
  
  for (colname in char_cols) {
    df[[colname]] <- iconv(df[[colname]], from = "latin1", to = "UTF-8", sub = "")
  }
  
  return(df)
}


#' Query Spatial Data by Generic Level
#'
#' @description Retrieves spatial data from a specific hierarchical level (level1, level2, or level3)
#' as defined in the global configuration for the selected country.
#'
#' @param information Character. The columns to select (e.g., "*" for all).
#' @param country Character. The country name (e.g., "Argentina").
#' @param level Character. The abstract hierarchy level ("level1", "level2", or "level3").
#' @param geo_config List. The geographic configuration object loaded from config.json.
#' @param data_dir Character. The directory path where the Geopackage files are stored.
#' @param type Character, optional. The column name for a conditional WHERE clause. Defaults to NULL.
#' @param name Character, optional. The value to match in the conditional WHERE clause. Defaults to NULL.
#'
#' @return A spatial data frame (sf object) with character columns converted to UTF-8.
#' @export
get_info_about <- function(information, country, level, geo_config, data_dir, type = NULL, name = NULL) {
  country_cfg <- geo_config[[country]]
  
  # Search the mapping list for the entry where db_column matches our level (e.g. Level1)
  layer_info <- NULL
  for (m in country_cfg$mapping) {
    if (m$db_column == level) { layer_info <- m; break }
  }
  
  file_path <- file.path(data_dir, country_cfg$file_name)
  sql <- if (!is.null(type)) {
    sprintf("SELECT %s FROM %s WHERE %s = '%s'", information, layer_info$layer_name, type, name)
  } else {
    sprintf("SELECT %s FROM %s", information, layer_info$layer_name)
  }
  
  result <- sf::st_read(file_path, query = sql, quiet = TRUE)
  return(to_utf8(result)) # Clean text encoding
}

#' Format New Database Entry
#'
#' @description Transforms raw Shiny inputs and the geographic state list into a 
#' flattened data frame row, structured for database insertion.
#'
#' @param input The Shiny input object containing form values (e.g., consultation_date, sex).
#' @param loc List. The currently selected geographic hierarchy (country, level1, level2, level3).
#'
#' @return A single-row data frame containing the formatted entry with a generated unique ID 
#' and a timestamp for confirmation.
#' @export
format_new_entry <- function(input, loc) {
  # This function centralizes the data transformation logic, making it
  # easy to update the database schema in one place.
  
  data.frame(
    id_code = generate_id(), # Calls generic utility from utils.R
    consultation_date = as.character(input$consultation_date),
    sex = input$sex,
    birth_date = as.character(input$birth_date),
    country = loc$country,
    level1 = loc$level1,
    level2 = loc$level2,
    level3 = loc$level3,
    symptom_onset_date = as.character(input$symptom_onset_date),
    symptom_description = input$symptom_description,
    suspected_diagnosis = input$suspected_diagnosis,
    confirmation_time = as.character(Sys.time()),
    email = input$email,
    institution = input$institution,
    stringsAsFactors = FALSE
  )
}