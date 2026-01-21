# run_linters.R: This script runs lintr on the R scripts,
# generates GitHub Actions annotations for any warnings found.
# It is included in the r-checks.yml GitHub Actions workflow to provide
# feedback on code quality issues.
library(lintr)

#' Summarise lintr warnings and print GitHub Actions annotations
#'
#' This function takes a list of lints and prints GitHub Actions warning annotations for each lint.
#'
#' @param lints A list of lint objects returned by lintr::lint_dir or lintr::lint
#' @return A character vector of markdown-formatted warning summaries
summarise_lintr_warnings <- function(lints) {
  warnings <- c()
  # Loop through each lint object
  for (lint in lints) {
    # Check if the object is a valid lint
    if (!is.null(lint) && inherits(lint, "lint")) {
      # Get relative file path for annotation
      rel_path <- sub(".*/(R/.*|main\\.R)$", "\\1", lint$filename)
      tryCatch(
        {
          # Print GitHub Actions warning annotation
          writeLines(sprintf(
            "::warning file=%s,line=%d,col=%d::%s",
            rel_path,
            as.integer(lint$line_number),
            as.integer(lint$column_number),
            as.character(lint$message)
          ))
          flush.console()
        },
        error = function(e) {
          # Print debug info if annotation fails
          cat("DEBUG: sprintf error:", conditionMessage(e), "\n")
          str(lint)
        }
      )
    }
  }
  return(warnings)
}

# Run lintr on all R scripts and main.R
lints <- c(lintr::lint_dir("R"), lintr::lint("main.R"))
cat("DEBUG: lints length =", length(lints), "\n")
# Filter only valid lint objects
lints <- Filter(function(x) inherits(x, "lint"), lints)
cat("Lintr found", length(lints), "warnings.\n")
# Summarise and print warnings
summarise_lintr_warnings(lints)
flush.console()
