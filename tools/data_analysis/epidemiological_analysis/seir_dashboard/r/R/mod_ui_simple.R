# ============================================================
# File: mod_ui_simple.R
# ------------------------------------------------------------
# Description: Simple View UI module for the SEIR Dashboard.
#   Renders a decision-maker interface consisting of three
#   independent KPI cards, each with a geometric alarm
#   indicator (circle / triangle / square) drawn in SVG using
#   the Analysis for Action (AfA) brand colour palette.
#
#   Layout (top to bottom):
#     1. Three KPI cards in a responsive row:
#          Card 1 – Epidemic Trajectory (weekly growth rate of I)
#          Card 2 – ICU Pressure       (ICU occupancy vs capacity)
#          Card 3 – Cumulative Impact  (deaths as % of population)
#        Each card shows the indicator, a plain-English
#        "What does this show?" explanation and visible feedback
#        on whether the alarm thresholds are reached.
#     2. Scenario Parameters: R₀, Compliance Level and the
#        simulation start / end dates.
#        State is fully isolated from the Advanced View.
#     3. Collapsible "Settings" panel with six numeric inputs
#        for overriding the default alarm thresholds. Changes
#        are reactive — they update indicators immediately
#        without re-running the ODE solver.
#
#   Shared helper functions (alarm_shape_svg, state_label_ui,
#   metric_value_ui) are defined in mod_helpers_simple.R, which
#   is sourced first by loadSupport() due to alphabetical order.
#
# AfA alarm palette:
#   Controlled  – circle   – #3EA27F (AfA sea green)
#   Warning     – triangle – #F59342 (AfA orange)
#   Critical    – square   – #752111 (AfA dark red)
#   No data     – dashed circle – #5F6B58
#
# Author: Cristian Paez
# Created: 2026-03-19
# Updated: 2026-10 — Testing recommendation (round 1):
#   * Start / end date inputs added to Scenario Parameters.
#   * Help text ("What does this show?") on every card.
#   * Visible threshold feedback under every card.
#   * Guidance text on how the thresholds work.
#   * Minimum text size 0.875rem (14 px).
# ============================================================


# ------------------------------------------------------------
# Helper: kpi_card_ui()
# Description:
#   Renders a single KPI card with a dynamic alarm indicator,
#   a metric label, a formatted metric value, threshold feedback
#   and an expandable explanation. Alarm shape, state label,
#   metric value and feedback are all server-rendered via
#   uiOutput so they react to slider and threshold changes.
# Parameters:
#   card_id     – character; unique HTML id for the card container.
#   title       – character; card heading.
#   subtitle    – character; brief description of what is measured.
#   shape_id    – character; id of the uiOutput for the alarm SVG.
#   value_id    – character; id of the uiOutput for the metric value.
#   label_id    – character; id of the uiOutput for the state label.
#   feedback_id – character; id of the uiOutput for the threshold
#                 feedback.
#   help        – character vector; paragraphs of the expandable
#                 "What does this show?" explanation.
# Returns:
#   A tags$div() styled as an AfA-branded card.
# ------------------------------------------------------------
kpi_card_ui <- function(card_id, title, subtitle, shape_id,
                        value_id, label_id, feedback_id, help) {

  tags$div(
    id    = card_id,
    class = "afa-kpi-card",

    # Alarm indicator — rendered server-side so it reacts to
    # threshold and slider changes without page reload
    uiOutput(shape_id),

    # State label (e.g. "Controlled", "Warning", "Critical")
    uiOutput(label_id),

    # Card title
    tags$h3(title, class = "afa-kpi-title"),

    # Card subtitle — what is being measured
    tags$p(subtitle, class = "afa-kpi-subtitle"),

    # Divider
    tags$hr(style = "width:100%; border-color:#D0D4CE; margin:0 0 14px;"),

    # Metric value — rendered server-side (reactive)
    uiOutput(value_id),

    # Threshold feedback — rendered server-side (reactive)
    uiOutput(feedback_id),

    # Expandable explanation (native <details>: keyboard and
    # screen-reader friendly, no JavaScript needed)
    tags$details(
      class = "afa-help",
      tags$summary("What does this show?"),
      lapply(help, function(p) tags$p(p))
    )
  )
}


# ------------------------------------------------------------
# Function: mod_ui_simple()
# Description:
#   Renders the full Simple View layout. Includes the three KPI
#   cards, the scenario parameters (R₀, Compliance Level and the
#   simulation dates), and the collapsible Settings panel with
#   six threshold inputs.
#   No server logic here — all reactivity is in mod_server_simple.R.
# Parameters:
#   id – Shiny module identifier.
# Returns:
#   A tagList() with the complete Simple View body.
# ------------------------------------------------------------
mod_ui_simple <- function(id) {
  ns <- NS(id)

  section_title_style <- paste(
    "font-size:0.875rem;",
    "font-weight:600;",
    "color:#48553F;",
    "margin-bottom:18px;"
  )

  group_title_style <- "color:#324027; font-size:0.9375rem;"

  tagList(

    # --------------------------------------------------------
    # Main body container — AfA light tint background
    # --------------------------------------------------------
    tags$div(
      style = paste(
        "min-height:calc(100vh - 52px);",   # 52 px = navbar height
        "background-color:#F4F6F5;",
        "padding:32px 24px 48px;"
      ),

      # Page heading
      tags$div(
        style = "text-align:center; margin-bottom:32px;",
        tags$h2(
          "Epidemic status: simplified view",
          style = paste(
            "font-size:1.6rem;",
            "font-weight:600;",
            "color:#1E2A16;",
            "margin-bottom:6px;"
          )
        ),
        tags$p(
          paste(
            "Key indicators are computed from the current simulation.",
            "Adjust R₀, compliance and the simulation period below",
            "to explore scenarios."
          ),
          style = "font-size:0.9375rem; color:#48553F; max-width:560px; margin:0 auto;"
        )
      ),

      # ----------------------------------------------------
      # Section 1: KPI Cards row
      # ----------------------------------------------------
      tags$div(
        style = paste(
          "display:flex;",
          "flex-wrap:wrap;",
          "gap:18px;",
          "justify-content:center;",
          "align-items:stretch;",
          "margin-bottom:32px;"
        ),

        # Card 1 — Epidemic Trajectory
        kpi_card_ui(
          card_id     = "card_trajectory",
          title       = "Epidemic trajectory",
          subtitle    = "Weekly growth rate of infectious cases (I compartment) — computed over the most recent 7 simulated days",
          shape_id    = ns("shape_trajectory"),
          value_id    = ns("value_trajectory"),
          label_id    = ns("label_trajectory"),
          feedback_id = ns("feedback_trajectory"),
          help        = c(
            "Compares the average number of infectious people in the last 7 days of the simulation with the 7 days before.",
            "A positive value means the epidemic is still growing; a negative value means it is declining.",
            "It needs a simulation period of at least 14 days."
          )
        ),

        # Card 2 — ICU Pressure
        kpi_card_ui(
          card_id     = "card_icu",
          title       = "ICU pressure",
          subtitle    = "ICU occupancy on the final simulation day as % of capacity",
          shape_id    = ns("shape_icu"),
          value_id    = ns("value_icu"),
          label_id    = ns("label_icu"),
          feedback_id = ns("feedback_icu"),
          help        = c(
            "Estimated number of ICU beds in use on the last day of the simulation, divided by the ICU bed capacity of the loaded dataset.",
            "Above 100% the simulated demand exceeds the beds available.",
            "The demand estimate is driven by the ICU admission rate of the dataset; see the User Guide for the method."
          )
        ),

        # Card 3 — Cumulative Impact
        kpi_card_ui(
          card_id     = "card_deaths",
          title       = "Cumulative impact",
          subtitle    = "Cumulative deaths as % of total population (final simulation day)",
          shape_id    = ns("shape_deaths"),
          value_id    = ns("value_deaths"),
          label_id    = ns("label_deaths"),
          feedback_id = ns("feedback_deaths"),
          help        = c(
            "Total simulated deaths from the start of the simulation to its last day, as a percentage of the total population.",
            "It depends on the infection fatality rate (IFR) of the dataset and on how many people are infected."
          )
        )
      ),

      # ----------------------------------------------------
      # Section 2: Scenario parameters
      # Fully isolated from the Advanced View.
      # ----------------------------------------------------
      tags$div(
        class = "afa-panel",
        style = "max-width:600px; margin:0 auto 28px;",

        tags$div("Scenario parameters", style = section_title_style),

        # R₀ slider — range and default from global.R
        sliderInput(
          inputId = ns("simple_r0"),
          label   = HTML("R₀: basic reproduction number"),
          min     = 0.5,
          max     = 6.0,
          value   = INITIAL_R0,
          step    = 0.1,
          width   = "100%"
        ),

        # Compliance Level slider — fixed default of 50
        sliderInput(
          inputId = ns("simple_compliance"),
          label   = "Compliance level (%)",
          min     = 0,
          max     = 100,
          value   = 50,
          step    = 1,
          width   = "100%"
        ),
        tags$p(
          class = "afa-help-text",
          HTML("Compliance sets how much the mitigation measures reduce R<sub>0</sub>: up to 50% at 100% compliance.")
        ),

        # Simulation period
        tags$div(
          style = "display:flex; gap:16px; flex-wrap:wrap; margin-top:8px;",
          tags$div(
            style = "flex:1; min-width:180px;",
            dateInput(
              inputId  = ns("simple_start_date"),
              label    = "Simulation start date",
              value    = START_DATE,
              format   = "d MM yyyy",
              language = "en",
              width    = "100%"
            )
          ),
          tags$div(
            style = "flex:1; min-width:180px;",
            dateInput(
              inputId  = ns("simple_end_date"),
              label    = "Simulation end date",
              value    = END_DATE,
              format   = "d MM yyyy",
              language = "en",
              width    = "100%"
            )
          )
        ),
        tags$p(
          class = "afa-help-text",
          "The simulation period must be at least 14 days long."
        )
      ),

      # ----------------------------------------------------
      # Section 3: Collapsible Settings panel
      # Six numeric inputs for alarm threshold overrides.
      # Toggle handled via inline JavaScript — no extra
      # Shiny dependency required.
      # ----------------------------------------------------
      tags$div(
        style = "max-width:600px; margin:0 auto;",

        # Toggle button — AfA earthy outline style
        tags$button(
          id      = "simple_settings_toggle",
          type    = "button",
          class   = "afa-settings-toggle",
          onclick = paste0(
            "var p = document.getElementById('simple_settings_panel');",
            "p.style.display = (p.style.display === 'none') ? 'block' : 'none';",
            "this.setAttribute('aria-expanded', p.style.display === 'block');"
          ),
          `aria-controls` = "simple_settings_panel",
          `aria-expanded` = "false",
          "▼  Settings: alarm thresholds"
        ),

        # Settings panel — hidden by default
        tags$div(
          id    = "simple_settings_panel",
          class = "afa-panel",
          style = "display:none;",

          tags$div("Alarm threshold configuration", style = section_title_style),

          # How the thresholds work
          tags$p(
            class = "afa-help-text",
            style = "margin-bottom:16px;",
            "Each indicator has two thresholds. When the value is at or below the ",
            "warning threshold the card shows “Controlled”; above the warning ",
            "threshold it shows “Warning”; above the critical threshold it ",
            "shows “Critical”. The warning threshold must be lower than the ",
            "critical threshold. Changing a threshold updates the cards immediately; ",
            "the simulation is not re-run."
          ),

          # --- ICU thresholds ---
          tags$p(
            tags$strong("ICU pressure", style = group_title_style),
            style = "margin-bottom:4px;"
          ),
          tags$div(
            style = "display:flex; gap:16px; flex-wrap:wrap; margin-bottom:20px;",
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_icu_warn"),
                label   = "Warning threshold (% of capacity)",
                value   = 70, min = 0, max = 200, step = 5,
                width   = "100%"
              )
            ),
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_icu_crit"),
                label   = "Critical threshold (% of capacity)",
                value   = 100, min = 0, max = 200, step = 5,
                width   = "100%"
              )
            )
          ),

          # --- Epidemic Trajectory thresholds ---
          tags$p(
            tags$strong("Epidemic trajectory", style = group_title_style),
            style = "margin-bottom:4px;"
          ),
          tags$div(
            style = "display:flex; gap:16px; flex-wrap:wrap; margin-bottom:20px;",
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_growth_warn"),
                label   = "Warning threshold (weekly growth %)",
                value   = 1, min = 0, max = 100, step = 0.5,
                width   = "100%"
              )
            ),
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_growth_crit"),
                label   = "Critical threshold (weekly growth %)",
                value   = 20, min = 0, max = 100, step = 1,
                width   = "100%"
              )
            )
          ),

          # --- Cumulative Impact thresholds ---
          tags$p(
            tags$strong("Cumulative impact", style = group_title_style),
            style = "margin-bottom:4px;"
          ),
          tags$div(
            style = "display:flex; gap:16px; flex-wrap:wrap;",
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_deaths_warn"),
                label   = "Warning threshold (% of population)",
                value   = 0.05, min = 0, max = 10, step = 0.01,
                width   = "100%"
              )
            ),
            tags$div(
              style = "flex:1; min-width:180px;",
              numericInput(
                inputId = ns("thr_deaths_crit"),
                label   = "Critical threshold (% of population)",
                value   = 0.20, min = 0, max = 10, step = 0.01,
                width   = "100%"
              )
            )
          )
        )
      )
    )
  )
}
