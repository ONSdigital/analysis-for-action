# ============================================================
# File: utils_helpers.R
# ------------------------------------------------------------
# Description: Numeric utility functions and safe ODE wrapper
# for SEIR model integration. Provides general-purpose helpers
# for mathematical operations and error-safe model execution.
# Also hosts the single IFR conversion (normalise_ifr_to_pct()) used
# by both views.
# Author: Cristian Paez
# Created: 2025-11-07
# Updated: 2026-10 — Testing recommendation (round 1):
#   * normalise_ifr_to_pct() moved here from mod_server.R so
#     both views share ONE IFR conversion.
#   * resolve_calibrated_params() added in R/data_interface.R
#     (fixes IFR being scaled twice and keeps both views consistent).
#   * afa_logo_ui() added for the Analysis for Action branding.
# ============================================================

# ------------------------------------------------------------
# Function: clamp()
# Description:
#   Restricts a numeric value to a given interval.
# Parameters:
#   x – numeric vector.
#   minv – minimum allowed value.
#   maxv – maximum allowed value.
# Returns:
#   Clamped numeric vector.
# ------------------------------------------------------------
clamp <- function(x, minv, maxv) pmax(minv, pmin(x, maxv))

# ------------------------------------------------------------
# Function: percent_to_prop()
# Description:
#   Converts percentage values to proportions (0–1 scale).
# Parameters:
#   x_pct – numeric percentage value.
# Returns:
#   Numeric proportion.
# ------------------------------------------------------------
percent_to_prop <- function(x_pct) x_pct / 100

# ------------------------------------------------------------
# Function: not_null()
# Description:
#   Returns TRUE if object is not NULL.
# Parameters:
#   x – any R object.
# Returns:
#   Logical TRUE/FALSE.
# ------------------------------------------------------------
not_null <- function(x) !is.null(x)

# ------------------------------------------------------------
# Function: normalise_ifr_to_pct()
# Description:
#   Converts an IFR value to a percentage in [0, 100] with
#   strict rules. This is the ONLY place where an IFR coming
#   from a calibrated dataset is rescaled. Callers must use the
#   value it returns and must not multiply by 100 again.
#     - IFR <= 1   : treated as a proportion  -> multiplied by 100.
#     - IFR <= 100 : treated as a percentage already.
#     - otherwise  : fails explicitly (wrong scale).
#   Note: a value of exactly 1 is read as a proportion (100 %).
#   The user CSV format documents IFR as a proportion.
# Parameters:
#   ifr_raw – numeric scalar.
# Returns:
#   Numeric scalar in [0, 100] (percent).
# ------------------------------------------------------------
normalise_ifr_to_pct <- function(ifr_raw) {
  if (!is.numeric(ifr_raw) || length(ifr_raw) != 1 || is.na(ifr_raw)) {
    stop("Calibrated dataset invalid: IFR must be a non-NA scalar numeric value.")
  }
  if (ifr_raw < 0) {
    stop("Calibrated dataset invalid: IFR cannot be negative.")
  }
  if (ifr_raw <= 1)   return(ifr_raw * 100)
  if (ifr_raw <= 100) return(ifr_raw)
  stop(sprintf(
    "Calibrated dataset invalid: IFR out of scale (value=%s). Expected proportion (<=1) or percent (<=100).",
    as.character(ifr_raw)
  ))
}

# NOTE: resolve_calibrated_params() lives in R/data_interface.R, not
# here. It reads the default constants of R/global.R (INITIAL_R0, ...)
# and Shiny loads R/global.R into a different environment from the
# one where R/utils/*.R are sourced, so a function in this folder
# cannot see those constants.

# ------------------------------------------------------------
# Function: afa_logo_ui()
# Description:
#   Returns the Analysis for Action logo for the navbar, or
#   NULL when the image file has not been placed in the app yet,
#   so the dashboard never shows a broken image.
#   Expected file: www/img/afa-logo-white.png (white logo for
#   the dark navbar).
# Parameters:
#   height – numeric; logo height in pixels.
# Returns:
#   A tags$img() or NULL.
# ------------------------------------------------------------
afa_logo_ui <- function(height = 32) {
  if (!file.exists(file.path("www", "img", "afa-logo-white.png"))) {
    return(NULL)
  }
  tags$img(
    src   = "img/afa-logo-white.png",
    alt   = "Analysis for Action",
    class = "afa-navbar-logo",
    style = paste0("height:", height, "px;")
  )
}

# ------------------------------------------------------------
# Function: safe_ode()
# Description:
#   Executes ODE integration safely, catching errors and logging
#   runtime messages. Wraps deSolve::ode() and integrates
#   SEIR differential equations under monitored conditions.
# Parameters:
#   y – initial state vector.
#   times – numeric vector of time points.
#   func – differential equation function.
#   parms – model parameters.
#   method – integration method (default "lsoda").
#   .module – string label for logging context.
# Returns:
#   Data frame of ODE integration results.
# ------------------------------------------------------------
safe_ode <- function(y, times, func, parms, method = "lsoda", .module = "MODEL") {
  tryCatch({
    with_timing({
      deSolve::ode(y = y, times = times, func = func, parms = parms, method = method)
    }, .module = .module, .label = "ode_integration")
  }, error = function(e) {
    log_message("ERROR", "ODE integration failed", .module,
                error = conditionMessage(e))
    stop("Error solving SEIR system. Check parameters and initial states.",
         call. = FALSE)
  })
}
