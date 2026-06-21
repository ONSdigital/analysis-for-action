# --- Framework & UI ---
library(shiny)
library(shinyjs)
library(leaflet)

# --- Data Processing & Paths ---
library(here)       # For relative paths
library(jsonlite)   # To load config.json
library(dplyr)      # For data manipulation
library(sf)         # For spatial data (Geopackage)
library(yaml)       # For app-level settings

# --- Database & Connectivity ---
library(DBI)        # Database Interface
library(pool)       # For persistent connection pooling
library(RSQLite)    # Driver for local fallback
library(RPostgres)  # Driver for Cloud DB (e.g., Supabase/PostgreSQL)
library(uuid)       # To generate unique IDs for reports


# 1. Load Settings (Non-sensitive parameters)
# Loaded from a YAML file to allow easy path configuration without altering code.
config <- yaml::yaml.load_file("config.yaml")

# Load the JSON configuration into an R list object
geo_config <- jsonlite::fromJSON(here::here("config.json"), simplifyVector = FALSE)

# Define the data directory for all spatial queries
data_dir <- here::here("raw_data")

# Load scripts
# Load Module Logic
source(here::here("R", "report_geolocation.R"))
source(here::here("R", "report_processing.R"))
source(here::here("R", "report_database.R"))
source(here::here("R", "report_mapping.R"))
source(here::here("R", "report_form.R"))
source(here::here("R", "utils.R"))


# 2. Load Secrets (Sensitive credentials)
# These remain in .Renviron to keep them safe and invisible to users.
admin_email <- Sys.getenv("ADMIN_EMAIL")
admin_password <- Sys.getenv("ADMIN_PASSWORD")

# 3. Load the database connection pool using the themed function
db_pool <- get_db_connection()

# 4. Manage the lifecycle
onStop(function() {
  if (exists("db_pool")) {
    pool::poolClose(db_pool)
    message("Database connection pool closed.")
  }
})

# Silence specific library messages
suppressMessages({
  library(sf)
  library(jsonlite)
})