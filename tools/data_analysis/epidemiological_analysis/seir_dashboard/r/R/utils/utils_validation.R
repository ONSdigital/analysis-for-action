# ============================================================
# File: utils_validation.R
# ------------------------------------------------------------
# Description: Validation utilities for epidemiological and
# healthcare resource parameters used in SEIR model execution.
# Includes checks for numeric ranges, logical consistency, and
# valid initial states.
# Author: Cristian Paez
# Created: 2025-11-07
# Updated: 2026-10 — Testing recommendation (round 1):
#   Every check is now safe against NULL / NA / zero-length
#   input. Previously an empty population or date field reached
#   an `if (NA)` or `if (logical(0))` and crashed the session
#   ("Initial states must be numeric and >= 0" / "argument is of
#   length zero"). Invalid input now produces a clear message.
#   validate_simulation_inputs() added so the views can stop an
#   invalid run BEFORE it reaches the model.
# ============================================================

# ------------------------------------------------------------
# Function: is_valid_number()
# Description:
#   TRUE only for a single, finite, non-NA numeric value.
#   Used by every validator so NULL, NA, NaN, Inf, character
#   strings and zero-length vectors are all rejected safely.
# ------------------------------------------------------------
is_valid_number <- function(x) {
  is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x)
}

# ------------------------------------------------------------
# Function: as_date_or_na()
# Description:
#   Converts a single value to Date, returning NA (never an
#   error and never a zero-length Date) when the value is NULL,
#   NA, zero-length or cannot be parsed.
# ------------------------------------------------------------
as_date_or_na <- function(x) {
  if (inherits(x, "Date") && length(x) == 1L) return(x)
  if (is.null(x) || length(x) != 1L || is.na(x)) return(as.Date(NA))
  tryCatch(as.Date(x), error = function(e) as.Date(NA))
}

# ------------------------------------------------------------
# Function: is_valid_date()
# Description:
#   TRUE only for a single, non-NA date.
# ------------------------------------------------------------
is_valid_date <- function(x) !is.na(as_date_or_na(x))

# ------------------------------------------------------------
# Function: validate_simulation_inputs()
# Description:
#   User-facing check of the three inputs that define the size
#   of a simulation: total population and the start / end dates.
#   Returns the list of problems as plain-English sentences
#   instead of stopping, so the caller can show them in the UI
#   and simply NOT run the simulation.
# Parameters:
#   population     – numeric; total population.
#   start_date     – Date; simulation start.
#   end_date       – Date; simulation end.
#   min_days       – integer; minimum period length in days
#                    (inclusive count). Default 1.
#   max_days       – integer; maximum difference between end and
#                    start in days. Default 3660 (about 10 years)
#                    — guards against runaway ODE sizes caused by
#                    a mistyped year.
#   min_population – numeric; the simulation always starts with
#                    10,000 infectious people (see mod_data.R and
#                    build_dataset()), so the population must be
#                    larger than that.
# Returns:
#   character vector of problems; character(0) when all inputs
#   are valid.
# ------------------------------------------------------------
validate_simulation_inputs <- function(population, start_date, end_date,
                                       min_days = 1L,
                                       max_days = 3660L,
                                       min_population = 10001) {
  problems <- character(0)

  # --- Population ---
  if (!is_valid_number(population)) {
    problems <- c(problems,
      "Total population is empty or not a valid number. Enter a number to run the simulation.")
  } else if (population < min_population) {
    problems <- c(problems, sprintf(
      "Total population must be at least %s (the simulation starts with 10,000 infectious people).",
      format(min_population, big.mark = ",", scientific = FALSE)))
  }

  # --- Dates ---
  sd <- as_date_or_na(start_date)
  ed <- as_date_or_na(end_date)

  if (is.na(sd)) {
    problems <- c(problems,
      "Simulation start date is empty or not a valid date.")
  }
  if (is.na(ed)) {
    problems <- c(problems,
      "Simulation end date is empty or not a valid date.")
  }

  if (!is.na(sd) && !is.na(ed)) {
    diff_days <- as.numeric(ed - sd)
    if (diff_days < 0) {
      problems <- c(problems,
        "Simulation end date cannot be earlier than the start date.")
    } else if (diff_days + 1 < min_days) {
      problems <- c(problems, sprintf(
        "The simulation period must be at least %d days long.",
        as.integer(min_days)))
    } else if (diff_days > max_days) {
      problems <- c(problems, sprintf(
        "The simulation period cannot be longer than %s days (about 10 years).",
        format(max_days, big.mark = ",", scientific = FALSE)))
    }
  }

  problems
}

# ------------------------------------------------------------
# Function: validate_params()
# Description:
#   Validates epidemiological and resource parameters provided
#   to the SEIR model. Ensures numeric ranges, existence of
#   required keys, and chronological consistency. Safe against
#   NULL / NA / zero-length values: it stops with a clear
#   message instead of failing inside an `if`.
# Parameters:
#   params – named list containing SEIR model parameters.
# Returns:
#   Invisibly returns params if valid; stops execution otherwise.
# ------------------------------------------------------------
validate_params <- function(params) {

  # --- Helper: ensure parameter existence ---
  stop_if_missing <- function(nm) {
    if (is.null(params[[nm]]))
      stop(sprintf("Missing parameter: %s", nm), call. = FALSE)
  }

  # Required parameter names
  req_names <- c(
    "r0_value", "incubation_period", "infectious_period", "ifr_value",
    "icu_admission_rate", "ventilator_usage_rate",
    "start_date", "end_date", "population"
  )
  invisible(lapply(req_names, stop_if_missing))

  # Validate positive numeric parameters
  num_pos <- c("r0_value", "incubation_period", "infectious_period", "population")
  for (nm in num_pos) {
    if (!is_valid_number(params[[nm]]) || params[[nm]] <= 0)
      stop(sprintf("'%s' must be a number greater than 0", nm), call. = FALSE)
  }

  # Validate percentage parameters within [0, 100]
  pct_01 <- c("ifr_value", "icu_admission_rate", "ventilator_usage_rate")
  for (nm in pct_01) {
    if (!is_valid_number(params[[nm]]) || params[[nm]] < 0 || params[[nm]] > 100)
      stop(sprintf("'%s' must be within range [0, 100]", nm), call. = FALSE)
  }

  # Validate dates and check their chronological order
  start_date <- as_date_or_na(params$start_date)
  end_date   <- as_date_or_na(params$end_date)

  if (is.na(start_date) || is.na(end_date))
    stop("'start_date' and 'end_date' must be valid dates", call. = FALSE)

  if (end_date < start_date)
    stop("'end_date' cannot be earlier than 'start_date'", call. = FALSE)

  invisible(params)
}

# ------------------------------------------------------------
# Function: validate_initial_state()
# Description:
#   Ensures initial SEIR compartment values are valid and
#   consistent with the total population. Safe against NA /
#   NULL compartments (e.g. an empty population field): those
#   are reported as invalid instead of crashing the check.
# Parameters:
#   S, E, I, R – numeric initial state values.
#   population – total population for consistency check.
#   tol – numeric tolerance for floating-point comparison.
# Returns:
#   TRUE if validation passes; stops otherwise.
# ------------------------------------------------------------
validate_initial_state <- function(S, E, I, R, population, tol = 1e-6) {

  # Validate non-negative numeric values (NA / NULL / negative -> invalid)
  for (v in list(S, E, I, R)) {
    if (!is_valid_number(v) || v < 0)
      stop("Initial states must be numeric and ≥ 0", call. = FALSE)
  }

  if (!is_valid_number(population))
    stop("'population' must be a valid number", call. = FALSE)

  # Validate population balance
  tot <- S + E + I + R
  if (abs(tot - population) > max(population * 1e-6, tol))
    stop("S + E + I + R must equal 'population' within tolerance", call. = FALSE)

  TRUE
}
