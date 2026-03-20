#' Initialize Database Connection Pool
#' 
#' @description Checks environment variables for cloud credentials. If found, 
#' connects to the cloud; otherwise, creates a local 'data/' directory and SQLite DB.
#' 
#' @return A pool object.
#' @export
get_db_connection <- function() {
  db_url <- Sys.getenv("CLOUD_DB_URL")
  
  if (db_url != "") {
    # --- Cloud Connection Path ---
    pool <- pool::dbPool(
      drv = RPostgres::Postgres(), 
      dbname = Sys.getenv("DB_NAME"),
      host = db_url,
      user = Sys.getenv("DB_USER"),
      password = Sys.getenv("DB_PASSWORD"),
      port = as.numeric(Sys.getenv("DB_PORT", 5432))
    )
    message("Connected to Cloud Database.")
    
  } else {
    # --- Local Fallback Path ---
    local_db_dir <- here::here("data")
    if (!dir.exists(local_db_dir)) dir.create(local_db_dir)
    
    local_db_path <- file.path(local_db_dir, "report_database.db")
    
    pool <- pool::dbPool(
      drv = RSQLite::SQLite(),
      dbname = local_db_path
    )
    
    # Initialize generic tables if brand new
    init_db_tables(pool) 
    message("Connected to Local SQLite Database at: ", local_db_path)
  }
  
  return(pool)
}

#' Initialize Database Tables
#' @description Creates the standardized reports table using generic geographic levels.
#' @param pool The active database pool.
#' @export
init_db_tables <- function(pool) {
  # We use generic 'level' names to stay country-agnostic
  if (!DBI::dbExistsTable(pool, "reports")) {
    DBI::dbExecute(pool, "
      CREATE TABLE reports (
        id_code TEXT PRIMARY KEY,
        consultation_date TEXT,
        sex TEXT,
        birth_date TEXT,
        country TEXT,
        level1 TEXT,
        level2 TEXT,
        level3 TEXT,
        symptom_onset_date TEXT,
        symptom_description TEXT,
        suspected_diagnosis TEXT,
        confirmation_time TEXT,
        email TEXT,
        institution TEXT
      )
    ")
    message('Database initialized with generic geographic levels.')
  }
}

#' Insert New Entry
#' @param new_entry Data frame (1 row).
#' @param pool The active database pool.
#' @export
insert_to_db <- function(new_entry, pool) {
  tryCatch({
    DBI::dbWriteTable(pool, "reports", new_entry, append = TRUE)
    message("Data successfully inserted.")
  }, error = function(e) {
    message("Error inserting data: ", e$message)
  })
}

#' Download User History by Email
#'
#' @description Queries the database for all records associated with a specific email.
#' @param email Character. The user's email address.
#' @param pool The active database connection pool.
#' @return A data frame of the user's report history.
#' @export
download_email_data <- function(email, pool) {
  # Use parameterized queries for security
  query <- "SELECT * FROM reports WHERE email = ?"
  
  tryCatch({
    # dbGetQuery works seamlessly across SQLite and Postgres via the pool
    data <- DBI::dbGetQuery(pool, query, params = list(email))
    return(data)
  }, error = function(e) {
    message("Error retrieving user data: ", e$message)
    return(data.frame())
  })
}