# ============================================================
# File: mod_helpers_simple.R
# ------------------------------------------------------------
# Description: Shared helper functions for the Simple View
#   Simplified View. Contains all pure functions used by both
#   mod_ui_simple.R and mod_server_simple.R.
#
#   Placing these helpers in a dedicated file guarantees they
#   are available when the other two modules load, because
#   Shiny's loadSupport() sources R/ files in alphabetical
#   order:
#     mod_helpers_simple.R  ← loaded first
#     mod_server_simple.R   ← loaded second
#     mod_ui_simple.R       ← loaded third
#
#   Functions defined here:
#     alarm_shape_svg()        – SVG geometric alarm indicator
#     state_label_ui()         – coloured alarm state text label
#     metric_value_ui()        – formatted KPI value display
#     unavailable_note_ui()    – explains why a value is N/A
#     threshold_feedback_ui()  – shows whether thresholds are
#                                reached / exceeded
#     resolve_alarm_state()    – classifies a metric into alarm state
#     coalesce_num()           – NULL/NA-safe numeric fallback
#                                (sole definition in the project;
#                                a duplicate in utils_helpers.R was
#                                removed — it was never called)
#
# AfA alarm palette:
#   Controlled  – circle          – #3EA27F (AfA sea green)
#   Warning     – triangle        – #F59342 (AfA orange)
#   Critical    – square          – #752111 (AfA dark red)
#   No data     – dashed circle   – #5F6B58 (muted green-grey)
#
# Author: Cristian Paez
# Created: 2026-03-19
# Updated: 2026-10 — Testing recommendation (round 1):
#   * A missing / non-finite value is no longer reported as
#     "Controlled": it now resolves to a distinct "unknown"
#     state ("No data") with an explanatory message.
#   * Visible threshold feedback added.
#   * Minimum text size raised to 0.875rem (14 px).
# ============================================================


# ------------------------------------------------------------
# Function: alarm_shape_svg()
# Description:
#   Returns an inline SVG element representing the geometric
#   alarm indicator. Shape and colour depend on the alarm state.
# Parameters:
#   state – character; one of "controlled", "warning",
#           "critical", "unknown".
#   size  – numeric; pixel dimensions for the bounding square.
# Returns:
#   A tags$span() containing an <svg> element.
# Notes:
#   All shapes are centred within the same viewBox so they
#   align consistently across cards regardless of state. The
#   "unknown" state uses an outlined, dashed circle so it is
#   distinguishable from the other states by shape as well as
#   by colour.
# ------------------------------------------------------------
alarm_shape_svg <- function(state = "controlled", size = 64) {

  # AfA alarm palette — never Bootstrap defaults
  colour <- switch(
    state,
    "controlled" = "#3EA27F",   # AfA sea green
    "warning"    = "#F59342",   # AfA orange
    "critical"   = "#752111",   # AfA dark red
    "unknown"    = "#5F6B58",   # muted green-grey: no value available
    "#CCCCCC"                   # fallback — should never occur
  )

  shape_svg <- switch(
    state,

    # Controlled: filled circle, centred at (32, 32), radius 22
    "controlled" = tags$svg(
      xmlns        = "http://www.w3.org/2000/svg",
      width        = size, height = size,
      viewBox      = "0 0 64 64",
      `aria-label` = "Status: Controlled",
      tags$circle(cx = "32", cy = "32", r = "22", fill = colour)
    ),

    # Warning: upward-pointing equilateral triangle
    # Vertices calculated for a centred, balanced appearance
    "warning" = tags$svg(
      xmlns        = "http://www.w3.org/2000/svg",
      width        = size, height = size,
      viewBox      = "0 0 64 64",
      `aria-label` = "Status: Warning",
      tags$polygon(points = "32,10 56,54 8,54", fill = colour)
    ),

    # Critical: filled square, inset 10 px on each side
    "critical" = tags$svg(
      xmlns        = "http://www.w3.org/2000/svg",
      width        = size, height = size,
      viewBox      = "0 0 64 64",
      `aria-label` = "Status: Critical",
      tags$rect(x = "10", y = "10", width = "44", height = "44",
                fill = colour)
    ),

    # Unknown (no data): dashed outline circle, not filled — it
    # must never look like one of the three evaluated states.
    "unknown" = tags$svg(
      xmlns        = "http://www.w3.org/2000/svg",
      width        = size, height = size,
      viewBox      = "0 0 64 64",
      `aria-label` = "Status: No data",
      tags$circle(cx = "32", cy = "32", r = "20", fill = "none",
                  stroke = colour, `stroke-width` = "4",
                  `stroke-dasharray` = "6 5")
    ),

    # Fallback — grey circle
    tags$svg(
      xmlns   = "http://www.w3.org/2000/svg",
      width   = size, height = size,
      viewBox = "0 0 64 64",
      tags$circle(cx = "32", cy = "32", r = "22", fill = "#CCCCCC")
    )
  )

  tags$span(
    style = "display:flex; justify-content:center; margin-bottom:12px;",
    shape_svg
  )
}


# ------------------------------------------------------------
# Function: state_label_ui()
# Description:
#   Returns a styled tags$p() with the human-readable alarm
#   state label, coloured with the matching AfA palette colour.
# Parameters:
#   state – character; "controlled", "warning", "critical" or
#           "unknown".
# Returns:
#   A tags$p() element.
# ------------------------------------------------------------
state_label_ui <- function(state) {
  conf <- list(
    controlled = list(text = "Controlled", colour = "#1E6B4F"),
    warning    = list(text = "Warning",    colour = "#8A4B12"),
    critical   = list(text = "Critical",   colour = "#752111"),
    unknown    = list(text = "No data",    colour = "#5F6B58")
  )
  cfg <- conf[[state]]
  if (is.null(cfg)) cfg <- conf[["unknown"]]

  tags$p(
    cfg$text,
    style = paste0(
      "font-size:0.875rem;",
      "font-weight:700;",
      "color:", cfg$colour, ";",
      "margin:0 0 4px;"
    )
  )
}


# ------------------------------------------------------------
# Function: metric_value_ui()
# Description:
#   Returns a styled tags$div() displaying the formatted metric
#   value and its unit label.
# Parameters:
#   formatted_value – character; pre-formatted numeric string.
#   unit_label      – character; short unit descriptor.
# Returns:
#   A tags$div() element.
# ------------------------------------------------------------
metric_value_ui <- function(formatted_value, unit_label) {
  tags$div(
    tags$span(
      formatted_value,
      style = paste(
        "font-size:2rem;",
        "font-weight:700;",
        "color:#1E2A16;",
        "line-height:1;"
      )
    ),
    tags$br(),
    tags$span(
      unit_label,
      style = "font-size:0.875rem; color:#5F6B58;"
    )
  )
}


# ------------------------------------------------------------
# Function: unavailable_note_ui()
# Description:
#   Short explanatory message shown under an "N/A" value, so a
#   missing indicator is never mistaken for a good outcome.
# Parameters:
#   reason – character; plain-English reason the value could
#            not be calculated.
# Returns:
#   A tags$p() element.
# ------------------------------------------------------------
unavailable_note_ui <- function(reason) {
  tags$p(
    class = "afa-unavailable-note",
    role  = "note",
    reason
  )
}


# ------------------------------------------------------------
# Function: format_threshold()
# Description:
#   Formats a threshold for display (no scientific notation,
#   no trailing zeros).
# ------------------------------------------------------------
format_threshold <- function(x) {
  format(x, trim = TRUE, scientific = FALSE, digits = 4)
}


# ------------------------------------------------------------
# Function: threshold_feedback_ui()
# Description:
#   Visible feedback on whether the alarm thresholds have been
#   reached or exceeded. Two short lines:
#     1. what the current state means for this indicator;
#     2. the thresholds currently in force.
# Parameters:
#   state – character; "controlled", "warning", "critical",
#           "unknown".
#   warn  – numeric; warning threshold in use.
#   crit  – numeric; critical threshold in use.
#   unit  – character; unit appended to threshold values.
# Returns:
#   A tags$div() element.
# ------------------------------------------------------------
threshold_feedback_ui <- function(state, warn, crit, unit = "%") {

  warn_txt <- paste0(format_threshold(warn), unit)
  crit_txt <- paste0(format_threshold(crit), unit)

  headline <- switch(
    state,
    "controlled" = paste0("Within the warning threshold (up to ", warn_txt, ")."),
    "warning"    = paste0("Warning threshold exceeded (above ", warn_txt, ")."),
    "critical"   = paste0("Critical threshold exceeded (above ", crit_txt, ")."),
    "unknown"    = "Thresholds cannot be applied without a value.",
    ""
  )

  tags$div(
    class = paste0("afa-threshold-note afa-threshold-", state),
    tags$p(class = "afa-threshold-headline", headline),
    tags$p(
      class = "afa-threshold-values",
      paste0("Warning above ", warn_txt, " · Critical above ", crit_txt)
    )
  )
}


# ------------------------------------------------------------
# Function: resolve_alarm_state()
# Description:
#   Classifies a numeric value into one of the alarm states
#   using two monotone thresholds (warn < crit).
# Parameters:
#   value     – numeric; metric value to classify.
#   warn      – numeric; lower threshold (warning boundary).
#   crit      – numeric; upper threshold (critical boundary).
#   direction – character; "above" (default) or "below".
#                "above"  → high values trigger warning/critical.
#                "below"  → low values trigger warning/critical
#                           (not currently used; included for
#                           extensibility).
# Returns:
#   character; "controlled", "warning", "critical" or
#   "unknown".
# Notes:
#   A missing value (NULL, NA, NaN, Inf) returns "unknown".
#   It must NOT return "controlled": a value that could not be
#   calculated says nothing about whether the situation is under
#   control.
#   When direction == "above":
#     value <= warn           → "controlled"
#     warn  < value <= crit  → "warning"
#     value > crit           → "critical"
# ------------------------------------------------------------
resolve_alarm_state <- function(value, warn, crit,
                                direction = "above") {
  if (is.null(value) || length(value) != 1L ||
      is.na(value) || !is.finite(value)) {
    return("unknown")
  }

  if (direction == "above") {
    if (value <= warn) return("controlled")
    if (value <= crit) return("warning")
    return("critical")
  }

  # direction == "below"
  if (value >= warn) return("controlled")
  if (value >= crit) return("warning")
  return("critical")
}


# ------------------------------------------------------------
# Function: coalesce_num()
# Description:
#   Returns `value` if it is a non-NA numeric scalar, otherwise
#   returns `default`. Guards against NULL/NA while the user
#   is editing a numericInput field mid-keystroke.
# Parameters:
#   value   – any; value to test.
#   default – numeric; fallback value.
# Returns:
#   numeric scalar.
# ------------------------------------------------------------
coalesce_num <- function(value, default) {
  if (is.null(value) || length(value) != 1 ||
      !is.numeric(value) || is.na(value)) {
    return(default)
  }
  value
}
