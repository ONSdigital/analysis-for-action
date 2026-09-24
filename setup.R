# Example: To add a new package, use:
# if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
#
# To add a package with a specific version, use:
# if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")
# remotes::install_version("dplyr", version = "1.1.4")
# Replace "dplyr" and "1.1.4" with your package and version.

if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes")

if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("forecast", quietly = TRUE)) install.packages("forecast")
if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
if (!requireNamespace("readr", quietly = TRUE)) install.packages("readr")
if (!requireNamespace("rio", quietly = TRUE)) install.packages("rio")
if (!requireNamespace("tidyverse", quietly = TRUE)) install.packages("tidyverse")
if (!requireNamespace("tseries", quietly = TRUE)) install.packages("tseries")
if (!requireNamespace("zoo", quietly = TRUE)) install.packages("zoo")
