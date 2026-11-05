# Example: To add a new package, use:
# if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
#
# To add a package with a specific version, use:
# if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
# remotes::install_version("dplyr", version = "1.1.4")
# Replace "dplyr" and "1.1.4" with your package and version.

if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")

# --- Infectious Disease Modelling: SEIR dashboard ---
if (!requireNamespace("shiny", quietly = TRUE)) install.packages("shiny")
if (!requireNamespace("shinyjs", quietly = TRUE)) install.packages("shinyjs")
if (!requireNamespace("bslib", quietly = TRUE)) install.packages("bslib")
if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("plotly", quietly = TRUE)) install.packages("plotly")
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("tidyr", quietly = TRUE)) install.packages("tidyr")
if (!requireNamespace("purrr", quietly = TRUE)) install.packages("purrr")
if (!requireNamespace("scales", quietly = TRUE)) install.packages("scales")
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
if (!requireNamespace("deSolve", quietly = TRUE)) install.packages("deSolve")
if (!requireNamespace("RcppRoll", quietly = TRUE)) install.packages("RcppRoll")
if (!requireNamespace("stringr", quietly = TRUE)) install.packages("stringr")
