# Regression tests for the Testing recommendation fixes.
# Run from the project root:  Rscript tests/manual/run_tests.R
#
# The loading layout mimics the REAL app (Shiny autoload):
#   * R/utils/*.R are sourced by global.R into the GLOBAL environment;
#   * R/global.R (constants) and the other R/*.R files are loaded by
#     Shiny into a separate "shared" environment.
# A function in R/utils/ therefore CANNOT see the constants of global.R
# (e.g. INITIAL_R0). Loading everything into one environment hides
# that class of bug.
suppressPackageStartupMessages({
  library(testthat); library(shiny); library(shinyjs); library(dplyr)
  library(tidyr); library(ggplot2); library(deSolve); library(RcppRoll)
})
options(scipen = 999)
Sys.setenv(LOG_LEVEL = "ERROR")

shared <- new.env(parent = globalenv())

# R/utils -> global environment (as global.R does), except the
# dependency installer
for (f in list.files("R/utils", pattern = "\\.R$", full.names = TRUE)) {
  if (basename(f) != "utils_dependencies.R") source(f, encoding = "UTF-8")
}

# Constants (R/global.R content) -> shared environment
local({
  POPULATION_ARGENTINA <- 45000000
  INITIAL_R0 <- 2.5; INITIAL_INCUBATION_PERIOD <- 5; INITIAL_INFECTIOUS_PERIOD <- 7
  INITIAL_IFR <- 0.01; INITIAL_ICU_RATE <- 0.136; INITIAL_VENTILATOR_RATE <- 0.02
  INITIAL_HOSPITAL_STAY_DAYS <- 10; INITIAL_ICU_CAPACITY <- 6000
  INITIAL_VENTILATOR_AVAILABILITY <- 2000; INITIAL_HEALTHCARE_STAFF <- 10000
  START_DATE <- as.Date("2026-01-01"); END_DATE <- as.Date("2026-12-31")
  for (n in setdiff(ls(), c("n"))) assign(n, get(n), envir = shared)
})

# Remaining R/*.R (except global.R) -> shared environment
for (f in setdiff(list.files("R", pattern = "\\.R$", full.names = TRUE), "R/global.R")) {
  source(f, local = shared, encoding = "UTF-8")
}

# The test cases run inside the shared environment
test_env <- shared

sys.source("tests/manual/test_cases.R", envir = test_env)
