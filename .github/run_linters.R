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

# Determine files to lint
args <- commandArgs(trailingOnly = TRUE)
changed_files_path <- if (length(args) > 0) args[1] else NULL

if (!is.null(changed_files_path) && file.exists(changed_files_path)) {
  files <- readLines(changed_files_path)
  files <- files[file.exists(files)]
} else {
  files <- c(list.files("R", pattern = "\\.R$", full.names = TRUE), "main.R")
}

# Run lintr on determined files
lints <- unlist(lapply(files, function(f) lintr::lint(f)), recursive = FALSE)
cat("DEBUG: lints length =", length(lints), "\n")
# Filter only valid lint objects
lints <- Filter(function(x) inherits(x, "lint"), lints)
cat("Lintr found", length(lints), "warnings.\n")
# Summarise and print warnings
summarise_lintr_warnings(lints)
flush.console()
