#' Results Server Module
#'
#' Handles the rendering of the dynamic results table and provides download handlers
#' for both the raw dataset and a weekly spatial summary aggregated by level3.
#'
#' @param id Character string. The Shiny module ID.
#' @param data_reactive Reactive expression. Returns the filtered dataset from the database.
#' @param cols_for_table Character vector. The baseline default columns to display in the table.
#' @param display_names List. A mapping of internal column names to human-readable UI labels.
#' @param filter_metadata Reactive expression. Returns the active filter selections (e.g., country, level1).
#' @param ALL_CONFIGS List. The complete configuration object for all countries, injected to avoid global dependency.
#' @param gpkg_path Character string. Path to the geometry .gpkg file used for spatial population joins.
#' 
#' @return NULL
#' @export
resultsServer <- function(id, data_reactive, cols_for_table, display_names, filter_metadata, ALL_CONFIGS, gpkg_path) {
  moduleServer(id, function(input, output, session) {
    
    # 1. Render Table
    output$results <- renderTable({
      req(data_reactive())
      df <- data_reactive()
      meta <- filter_metadata() # Extract metadata to get current country
      
      # --- ROBUST COLUMN SELECTION ---
      # 1. Start with the columns you WANT to show
      target_cols <- cols_for_table
      
      # 2. Include any dynamic levels from the current country config
      if (isTruthy(meta$country) && !is.null(ALL_CONFIGS)) {
        config <- tryCatch(ALL_CONFIGS[[meta$country]], error = function(e) NULL)
        if (!is.null(config)) {
          target_cols <- unique(c(target_cols, config$levels))
        }
      }
      
      # 3. INTERSECT: Only select columns that actually exist in the dataframe
      valid_cols <- intersect(target_cols, names(df))
      df <- df[, valid_cols, drop = FALSE]
      
      # --- APPLY DISPLAY NAMES ---
      # Only rename columns that we actually have
      current_names <- colnames(df)
      new_names <- sapply(current_names, function(col) {
        if (col %in% names(display_names)) return(display_names[[col]])
        return(tools::toTitleCase(col)) # Fallback: Capitalize
      })
      colnames(df) <- new_names
      
      df
    }, sanitize.text.function = function(x) x)
    
    # 2. Download Cases
    output$download_csv <- downloadHandler(
      filename = function() { paste0("query_results_", Sys.Date(), ".csv") },
      content = function(file) {
        req(data_reactive())
        write.csv(data_reactive(), file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # 3. Download Summary (Standardized RAP Version)
    output$download_summary_csv <- downloadHandler(
      filename = function() { paste0("weekly_summary_", Sys.Date(), ".csv") },
      content = function(file) {
        df <- data_reactive()
        req(df)
        
        # A. Metadata and Config Retrieval
        meta <- filter_metadata() 
        req(meta$country)
        
        config <- ALL_CONFIGS[[meta$country]]
        level3_map <- config$mapping[["level3"]]
        
        # Ensure the GeoPackage exists
        specific_gpkg <- here::here("data", config$file_name)
        req(file.exists(specific_gpkg))
        
        # B. Prep Year/Week from consultation_date
        df <- df %>% 
          dplyr::mutate(
            year = lubridate::isoyear(consultation_date),
            week = lubridate::isoweek(consultation_date)
          )
        
        # C. Summarize Counts
        # FIX: Group by all available geographic columns to retain the hierarchy!
        db_col <- level3_map$db_column
        geo_cols <- intersect(config$levels, names(df))
        
        summary_df <- df %>% 
          dplyr::group_by(year, week, dplyr::across(dplyr::all_of(geo_cols))) %>% 
          dplyr::summarise(n_cases = dplyr::n(), .groups = "drop")
        
        # D. Load Population and Spatial ID
        pop_df <- sf::st_read(specific_gpkg, layer = level3_map$layer_name, quiet = TRUE) %>%
          sf::st_drop_geometry() 
        
        # E. Join Logic using spatial_id
        # We ensure both keys are character to prevent ID matching errors
        spatial_id_key <- level3_map$spatial_id
        
        summary_df[[db_col]] <- as.character(summary_df[[db_col]])
        pop_df[[spatial_id_key]] <- as.character(pop_df[[spatial_id_key]])
        
        final_df <- summary_df %>% 
          dplyr::left_join(
            pop_df %>% dplyr::select(all_of(spatial_id_key), Population), 
            by = setNames(spatial_id_key, db_col)
          )
        
        # F. Assemble Final Column Structure
        # FIX: Select the dynamic geographic columns straight from the dataset
        final_df <- final_df %>% 
          dplyr::select(
            dplyr::all_of(geo_cols),
            week,
            year, 
            cases = n_cases, 
            population = Population
          )
        
        write.csv(final_df, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
  })
}