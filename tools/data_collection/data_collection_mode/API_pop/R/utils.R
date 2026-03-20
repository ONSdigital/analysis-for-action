#' Force Data into UTF-8
#' 
#' Safely converts character vectors and dataframe character columns to UTF-8
#' to prevent segfaults and ensure special characters render correctly in the UI.
#' 
#' @param x A character vector or data.frame
#' @return The same object with UTF-8 encoded text
#' @export
to_utf8 <- function(x) {
  if (is.data.frame(x)) {
    x[] <- lapply(x, function(col) {
      if (is.character(col)) {
        return(iconv(col, from = "", to = "UTF-8"))
      }
      return(col)
    })
    return(x)
  } else if (is.character(x)) {
    return(iconv(x, from = "", to = "UTF-8"))
  }
  return(x)
}

#' @title Safely Read CSV Files with Encoding Detection
#'
#' @description 
#' Reads the raw bytes of a CSV file to mathematically determine its encoding 
#' before passing it to R's standard parser. This prevents the silent destruction 
#' of special characters (like "ó" becoming "ï¿½") that happens when R incorrectly 
#' guesses a file's encoding. Defaults to UTF-8 or Latin-1 based on the byte signature.
#'
#' @param filepath Character string. The file path to the CSV to be read.
#'
#' @return A data frame containing the parsed CSV data.
#' @keywords internal
read_csv_safely <- function(filepath) {
  raw_bytes <- readBin(filepath, what = "raw", n = 10000)
  detected <- stringi::stri_enc_detect(raw_bytes)
  best_guess <- detected[[1]]$Encoding[1]
  
  if (is.na(best_guess) || best_guess == "ASCII") {
    best_guess <- "UTF-8"
  }
  
  # Normalize common Latin encodings
  if (grepl("windows|iso-8859|latin", tolower(best_guess))) {
    best_guess <- "latin1"
  }
  
  df <- utils::read.csv(
    filepath,
    stringsAsFactors = FALSE,
    fileEncoding = best_guess,
    colClasses = "character"
  )
  
  return(df)
}

#' @title Master Wrapper for Reading Uploaded Data Files
#'
#' @description 
#' Acts as a router to process various file types (CSV, XLSX, XML, SQLite/DBA) 
#' using the appropriate reading functions. After reading, it iterates through 
#' all character columns and explicitly flags them as UTF-8 in R's memory to 
#' guarantee cross-platform stability.
#'
#' @param filepath Character string. The file path to the uploaded file.
#' @param ext Character string. The file extension (e.g., "csv", "xlsx", "xml", "dba").
#' @param target_table Character string. The name of the table to extract if the 
#'   uploaded file is a SQLite database (.dba).
#'
#' @return A data frame with all character columns safely forced into UTF-8 encoding.
#' @keywords internal
read_uploaded_file <- function(filepath, ext, target_table) {
  df <- switch(ext,
               "csv"  = read_csv_safely(filepath),
               "xlsx" = readxl::read_excel(filepath),
               "xml"  = {
                 doc <- xml2::read_xml(filepath)
                 nodes <- xml2::as_list(doc)
                 as.data.frame(do.call(rbind, lapply(nodes, unlist)), stringsAsFactors = FALSE)
               },
               "dba"  = {
                 tmp <- tempfile(fileext = ".sqlite")
                 file.copy(filepath, tmp, overwrite = TRUE)
                 con2 <- DBI::dbConnect(RSQLite::SQLite(), tmp)
                 d <- DBI::dbReadTable(con2, target_table)
                 DBI::dbDisconnect(con2)
                 d
               },
               stop("Unsupported file type")
  )
  
  # ✅ ONLY encoding fix
  df[] <- lapply(df, fix_encoding)
  
  return(df)
}

#' @title String Normalization
#'
#' @description 
#' Standardizes text strings for database filtering and searching. It safely 
#' strips accents using the `stringi` ICU transliteration engine,
#' converts text to lowercase, and trims whitespace. 
#' Crucially, it does not delete unrecognized bytes, preventing strings from 
#' being truncated if corrupted data is accidentally passed to it.
#'
#' @param x A character vector (or a vector that can be coerced to character) 
#'   to be normalized.
#'
#' @return A character vector of the same length as `x` containing the normalized strings.
#' @keywords internal
normalize <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA)
  v <- as.character(x)
  valid <- !is.na(v) & v != ""
  
  v[valid] <- iconv(v[valid], from = "", to = "UTF-8")
  v[valid] <- stringi::stri_trans_general(v[valid], "Latin-ASCII")
  
  return(tolower(trimws(v)))
}

#' Add Filters to SQL Query
#' 
#' Dynamically appends WHERE clauses to a base SQL statement based on 
#' user-selected filters, handling normalization for geographic tiers.
#'
#' @param sql Character. The base SQL query (e.g., "SELECT * FROM reports").
#' @param con A DBIConnection object.
#' @param eq_filters List. Named list of equality/logic filters.
#' @param range_filters List. Named list of date/numerical range filters.
#' @param age_range Numeric vector. A length-2 vector for min/max age.
#' @return Character. The modified SQL query with WHERE clauses.
#' @export
add_filters_to_sql <- function(sql, con, eq_filters = list(), range_filters = list(), age_range = NULL) {
  
  conditions <- character()
  
  # 1. Handle Age Range (from slider)
  if (!is.null(age_range)) {
    range_filters$Age <- age_range
  }
  
  # 2. Process Equality and Logic Filters
  for (colname in names(eq_filters)) {
    val <- eq_filters[[colname]]
    
    # Check if the column is a geographic tier that needs normalization mapping
    if (colname %in% c("country", "level1", "level2", "level3")) {
      colname_norm <- paste0(colname, "_norm")
      # Strip accents and normalize value for the SQL search
      val_norm <- normalize(val)
      conditions <- c(conditions, build_eq(con, colname_norm, val_norm))
      
    } else if (colname == "symptom_description") {
      # Use specialized helper for 'and/or' logic strings
      conditions <- c(conditions, build_logic(con, colname, val))
      
    } else {
      # Standard equality filter
      conditions <- c(conditions, build_eq(con, colname, val))
    }
  }
  
  # 3. Process Range Filters (Dates and Age)
  for (colname in names(range_filters)) {
    val <- range_filters[[colname]]
    conditions <- c(conditions, build_range(con, colname, val))
  }
  
  # 4. Final SQL Assembly
  if (length(conditions) > 0) {
    sql <- paste(sql, "WHERE", paste(conditions, collapse = " AND "))
  }
  
  return(sql)
}


#' Build Equality SQL Clause (NA-Safe Version)
#' @param con DBIConnection.
#' @param colname Column name.
#' @param val Value to match.
#' @return SQL string.
build_eq <- function(con, colname, val) {
  # isTruthy safely handles NULL, NA, and ""
  if (!shiny::isTruthy(val)) return(NULL)
  
  sprintf("%s = %s", 
          DBI::dbQuoteIdentifier(con, colname),
          DBI::dbQuoteString(con, as.character(val)))
}

#' Build Range SQL Clause
#' @param con DBIConnection.
#' @param colname Column name.
#' @param rng Vector of length 2 (min, max).
#' @return SQL string.
#' @keywords internal
build_range <- function(con, colname, rng) {
  sprintf("%s BETWEEN %s AND %s", DBI::dbQuoteIdentifier(con, colname),
          DBI::dbQuoteString(con, as.character(rng[1])), DBI::dbQuoteString(con, as.character(rng[2])))
}

#' Build Text Logic SQL Clause (AND/OR)
#' @param con DBIConnection.
#' @param colname Column name.
#' @param val String containing logical operators (e.g., "fever and cough").
#' @return SQL string.
#' @keywords internal
build_logic <- function(con, colname, val) {
  or_groups <- strsplit(val, "\\s+or\\s")[[1]]
  or_clauses <- lapply(or_groups, function(group) {
    and_terms <- trimws(strsplit(group, "\\s+and\\s+")[[1]])
    and_clauses <- sapply(and_terms, function(term) {
      sprintf("%s LIKE %s", DBI::dbQuoteIdentifier(con, colname),
              DBI::dbQuoteString(con, paste0("%", stringi::stri_trans_general(term, "Latin-ASCII"), "%")))
    })
    paste0("(", paste(and_clauses, collapse = " AND "), ")")
  })
  paste(or_clauses, collapse = " OR ")
}



#' Fetch Geographic Options Based on ID Matching
#' 
#' @param gpkg_path Path to the .gpkg file.
#' @param country The country key (e.g., "Argentina").
#' @param level_key The level we want to FILL (e.g., "level1", "level2").
#' @param parent_key The level the user JUST CLICKED (e.g., "level1").
#' @param parent_val The ID CODE of the selected parent (e.g., "06" for a province).
fetch_options <- function(gpkg_path, country, level_key, parent_key = NULL, parent_val = NULL) {
  # 1. Validation
  if (!exists("ALL_CONFIGS") || is.null(country) || country == "") return(character(0))
  
  config <- ALL_CONFIGS[[country]]
  target_map <- config$mapping[[level_key]]
  if (is.null(target_map)) return(character(0))
  
  name_col <- if (!is.null(target_map$name_col)) target_map$name_col else "nam"
  id_col   <- if (!is.null(target_map$spatial_id)) target_map$spatial_id else "rowid"
  
  # 2. SQL Build (ID-BASED)
  if (is.null(parent_key) || is.null(parent_val) || parent_val == "") {
    
    sql <- sprintf(
      "SELECT DISTINCT %s, %s FROM %s ORDER BY %s",
      name_col, id_col, target_map$layer_name, name_col
    )
    
  } else {
    
    parent_map <- config$mapping[[parent_key]]
    
    sql <- sprintf(
      "SELECT DISTINCT c.%s, c.%s
       FROM %s c
       JOIN %s p ON CAST(c.%s AS TEXT) = CAST(p.%s AS TEXT)
       WHERE p.%s = '%s'
       ORDER BY c.%s",
      name_col, id_col,
      target_map$layer_name, parent_map$layer_name,
      target_map$parent_col, parent_map$spatial_id,
      parent_map$spatial_id, parent_val,
      name_col
    )
  }
  
  # 3. Execute (NO encoding fix anymore)
  res <- tryCatch({
    
    data <- sf::st_read(gpkg_path, query = sql, quiet = TRUE)
    
    # Named vector: names = labels (UI), values = IDs (server logic)
    choices <- setNames(
      as.character(data[[id_col]]),
      as.character(data[[name_col]])
    )
    
    choices
    
  }, error = function(e) {
    message("Fetch Error: ", e$message)
    return(character(0))
  })
  
  return(res)
}


#' Fix character encoding to UTF-8
#'
#' Attempts to ensure that a character vector is properly encoded in UTF-8.
#' Valid UTF-8 strings are left unchanged, while invalid entries are assumed
#' to be encoded in Latin-1 and are converted to UTF-8. Non-character inputs
#' are returned unchanged.
#' Note that this approach cannot recover text that has already been irreversibly
#' corrupted
#' @param x A vector. If character, encoding will be validated and corrected.
#'
#' @return A vector of the same length as x, with character elements safely
#' converted to UTF-8 when needed.
#' @keywords internal
fix_encoding <- function(x) {
  if (!is.character(x)) return(x)
  
  # keep valid UTF-8 as is
  valid_utf8 <- !is.na(iconv(x, from = "UTF-8", to = "UTF-8"))
  
  # fix only invalid ones (likely Latin-1)
  x[!valid_utf8] <- iconv(x[!valid_utf8], from = "latin1", to = "UTF-8", sub = "")
  
  return(x)
}


#' Apply Country-Specific Code Length Rules
#'
#' @description
#' Applies padding rules to geographic code columns based on country-specific
#' configuration. For each country defined in the configuration list, the function
#' checks whether any geographic level (e.g., level1, level2, level3) includes a
#' `code_length` rule. If present, values in the corresponding column are padded
#' with leading zeros to match the required length.
#'
#' Only values shorter than the specified length are modified. Values that already
#' meet or exceed the required length remain unchanged. The operation is applied
#' selectively to rows matching each country.
#'
#' @param df A data.frame containing at least a `country` column and any geographic
#'   columns referenced in the configuration (e.g., "level1", "level2", "level3").
#'
#' @param config_list A named list of country configurations (typically parsed from
#'   `config.json`). Each country may contain a `mapping` list where individual
#'   levels define a `db_column` and optional `code_length`.
#'
#' @return A data.frame with updated columns where padding rules have been applied.
#'
#' @details
#' The function:
#' \itemize{
#'   \item Iterates over each country defined in the configuration.
#'   \item Identifies rows in `df` matching that country.
#'   \item Applies padding only to columns with a defined `code_length`.
#'   \item Leaves all other values unchanged.
#' }
#'
#' The function assumes that `df$country` values match the names of
#' `config_list`.
#'
#' @keywords internal
apply_code_length_rules <- function(df, config_list) {
  
  if (!"country" %in% names(df)) return(df)
  
  for (country_name in names(config_list)) {
    
    country_cfg <- config_list[[country_name]]
    mapping <- country_cfg$mapping
    
    if (is.null(mapping)) next
    
    # rows for this country
    idx <- which(df$country == country_name)
    if (length(idx) == 0) next
    
    for (level_name in names(mapping)) {
      
      level_cfg <- mapping[[level_name]]
      
      # skip if no rule
      if (is.null(level_cfg$code_length)) next
      
      col <- level_cfg$db_column
      width <- level_cfg$code_length
      
      if (!col %in% names(df)) next
      
      # apply ONLY to matching country rows
      df[[col]][idx] <- ifelse(
        nchar(df[[col]][idx]) < width,
        stringr::str_pad(df[[col]][idx], width, side = "left", pad = "0"),
        df[[col]][idx]
      )
    }
  }
  
  return(df)
}