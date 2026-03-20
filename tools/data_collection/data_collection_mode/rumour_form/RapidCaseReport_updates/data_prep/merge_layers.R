library(sf)
library(here)

#' Merge Single-Layer Geopackages into a Multi-Layer Geopackage (Interactive)
#'
#' @description Interactively prompts the user for a country name and the 
#' corresponding geographic files for each administrative level, then combines 
#' them into a single Geopackage file.
#'
#' @return NULL. Called for its side effect of creating a file.
build_country_geopackage <- function() {
  cat("========================================\n")
  cat("   Geographic Data Merging Tool\n")
  cat("========================================\n\n")
  
  # 1. Get the Country Name
  country_name <- readline(prompt = "Enter the country name (e.g., Argentina, Brazil): ")
  
  if (trimws(country_name) == "") {
    stop("Country name cannot be empty. Process aborted.")
  }
  
  # Define the output directory and file
  data_dir <- here::here("raw_data")
  if (!dir.exists(data_dir)) {
    dir.create(data_dir)
  }
  output_file <- file.path(data_dir, paste0(country_name, ".gpkg"))
  
  # Initialize an empty list to store the file paths
  input_files <- list()
  
  # 2. Loop to get Geographic Levels and their Files
  cat("\nNow, enter the geographic levels from highest to lowest (e.g., province, department, fraction).\n")
  cat("Press [Enter] without typing anything when you are done adding levels.\n\n")
  
  level_count <- 1
  repeat {
    layer_name <- readline(prompt = sprintf("Enter name for Level %d (or press Enter to finish): ", level_count))
    
    # Break the loop if the user just presses Enter
    if (trimws(layer_name) == "") {
      break
    }
    
    file_path <- readline(prompt = sprintf("Enter the file path for the '%s' layer (e.g., raw_data/my_file.gpkg): ", layer_name))
    
    # Validate that the file actually exists before proceeding
    if (!file.exists(file_path)) {
      cat(sprintf("\n[!] ERROR: The file '%s' was not found.\n", file_path))
      cat("Please check the path and try adding this level again.\n\n")
      next
    }
    
    # Add the valid file to our list
    input_files[[layer_name]] <- file_path
    level_count <- level_count + 1
    cat("  -> Level added successfully.\n\n")
  }
  
  # 3. Merge the files
  if (length(input_files) == 0) {
    cat("\nNo levels were added. Exiting without creating a file.\n")
    return(invisible(NULL))
  }
  
  cat(sprintf("\nMerging %d layers into %s...\n", length(input_files), output_file))
  
  for (layer_name in names(input_files)) {
    file_path <- input_files[[layer_name]]
    
    cat(sprintf("  Processing layer: %s...\n", layer_name))
    
    # Read the individual layer
    spatial_data <- sf::st_read(file_path, quiet = TRUE)
    
    # Append it to the new consolidated country Geopackage
    sf::st_write(spatial_data, dsn = output_file, layer = layer_name, 
                 append = TRUE, quiet = TRUE)
  }
  
  cat("\n========================================\n")
  cat("                SUCCESS!\n")
  cat("========================================\n")
  cat(sprintf("Merged Geopackage created at: %s\n", output_file))
  cat("Remember to update your config.json with these new layer names!\n")
}

# Execute the function to start the interactive prompt
build_country_geopackage()