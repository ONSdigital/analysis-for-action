# ==============================================================================
# 0. SYSTEM SETTINGS
# ==============================================================================
# Force the R session to use UTF-8 regardless of the OS (Windows vs Linux)
try(Sys.setlocale("LC_ALL", "C.UTF-8"), silent = TRUE)

# ==============================================================================
# 1. LOAD LIBRARIES
# ==============================================================================
library(shiny)
library(shinyjs)
library(jsonlite)
library(sf)
library(DT)
library(RSQLite)
library(DBI)
library(pool)      # ADDED: For database connection pooling
library(config)    # ADDED: For yaml configuration management
library(stringi)
library(readxl)
library(dplyr)
library(here)
library(xml2)

# Load helper functions and modules
source(here::here("R", "utils.R"))
source(here::here("R", "module_filters.R"))
source(here::here("R", "module_results.R"))
source(here::here("R", "module_upload.R"))
source(here::here("R", "main_analysis.R")) 

# ------------------------------------------------------------------------------
# 2. LOAD CONFIGURATION
# ------------------------------------------------------------------------------
# config::get() automatically reads the active environment from .Renviron
# Force config to look in the exact project root
app_config <- config::get(file = here::here("config.yaml"))

# Load the country-specific JSON config
config_path <- here::here(app_config$json_config_path)
if (file.exists(config_path)) {
  ALL_CONFIGS <- jsonlite::fromJSON(config_path)
} else {
  stop("config.json not found in the specified path!")
}

# --- GEOMETRY PATH DEFINITION ---
gpkg_path <- here::here("data", app_config$gpkg_name)

# ------------------------------------------------------------------------------
# 3. DATABASE POOL CONNECTION
# ------------------------------------------------------------------------------
# Initialize the pool instead of a single connection
pool <- pool::dbPool(
  drv = RSQLite::SQLite(),
  dbname = here::here("data", app_config$db_name)
)

table_name <- "reports"
# dbListFields works exactly the same with a pool object
reports_cols <- DBI::dbListFields(pool, table_name)

# ------------------------------------------------------------------------------
# 4. APP CONSTANTS
# ------------------------------------------------------------------------------
columns <- list(
  symptom_description = "text_logic",
  symptom_onset_date  = "date_or_range",
  suspected_diagnosis = "text",
  birth_date          = "age",
  location            = "geography"
)

display_names <- c(
  suspected_diagnosis = "Diagnosis",
  symptom_description = "Symptoms",
  symptom_onset_date  = "Symptoms Onset Date",
  location            = "Location",
  country             = "Country",
  level1              = "Province",
  level2              = "Department",
  level3              = "Censal Fraction",
  birth_date          = "Age",
  sex                 = "Sex",
  Age                 = "Age",
  consultation_date   = "Consultation Date"
)

cols_for_table <- c(
  "suspected_diagnosis",
  "symptom_description",
  "symptom_onset_date",
  "country",
  "level1",
  "level2",
  "level3",
  "sex",
  "Age",
  "consultation_date"
)

fix_map <- c(
  "Ã¡" = "á", "Ã©" = "é", "Ã­" = "í", "Ã³" = "ó", "Ãº" = "ú",
  "Ã " = "Á", "Ã‰" = "É", "Ã " = "Í", "Ã“" = "Ó", "Ãš" = "Ú",
  "Ã±" = "ñ", "Ã‘" = "Ñ", "Ã¼" = "ü", "Ãœ" = "Ü"
)

population_layers <- list(
  Argentina = c("INDEC_2020")
)

# ------------------------------------------------------------------------------
# 5. POOL CLOSURE (APP LEVEL)
# ------------------------------------------------------------------------------
# This ensures the pool is only closed when the entire Shiny application stops,
# not when an individual user disconnects.
onStop(function() {
  if (exists("pool") && DBI::dbIsValid(pool)) {
    pool::poolClose(pool)
  }
})