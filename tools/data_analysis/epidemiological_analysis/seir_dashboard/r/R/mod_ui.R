# ============================================================
# File: mod_ui.R
# ------------------------------------------------------------
# Description: Defines all UI layout functions for the Advanced
#   View of the SEIR dashboard. Exposes composable helpers:
#     - ui_seir_params()     – epidemiological parameter panel
#     - ui_policy_params()   – public policy parameter panel
#     - ui_resource_params() – healthcare resource panel
#     - ui_scope_params()    – population and simulation dates
#     - ui_main()            – full page layout that wires all
#                              panels and plot outputs together
#
#   Layout aligned with Analysis for Action brand guidelines: dark green navbar,
#   light tint sidebar with white parameter panels, AfA colour
#   palette throughout.
#
# Author: Cristian Paez
# Created: 2025-11-07
# Updated: 2026-10 — Testing recommendation (round 1):
#   * Intervention options now list only what the model
#     implements: "No Intervention" and "Static Mitigation".
#     "Phased Mitigation", "Intermittent Intervention" and
#     "ICU-triggered Measures" were all treated as the same
#     static R0 reduction by the model (see mod_model.R Step 3),
#     so they were removed instead of promising behaviour that
#     did not exist.
#   * Total population minimum raised to 10,001: the simulation
#     starts with 10,000 infectious people, so a smaller
#     population gave negative susceptibles.
#   * Panel titles / small text raised to at least 0.875rem.
#   * Sidebar background #F4F6F5 with white panels (was white
#     with beige panels).
# ============================================================


# ------------------------------------------------------------
# Helper: panel_title_ui()
# Description:
#   Section title used at the top of each sidebar panel.
# ------------------------------------------------------------
panel_title_ui <- function(text) {
  tags$div(text, class = "afa-panel-title")
}


# ------------------------------------------------------------
# Function: ui_seir_params()
# Description:
#   Builds the epidemiological parameter control panel.
#   Provides slider inputs for the four core SEIR parameters:
#   R0, incubation period, infectious period, and IFR.
# Parameters:
#   ns – Shiny namespace function produced by NS(id).
# Returns:
#   A div() containing labelled sliderInput widgets.
# ------------------------------------------------------------
ui_seir_params <- function(ns) {
  div(
    panel_title_ui("Epidemiological parameters"),

    # R0: basic reproduction number
    sliderInput(ns("r0_value"),
                label = HTML("Basic reproduction number (R<sub>0</sub>)"),
                min = 0.5, max = 5.0, value = INITIAL_R0, step = 0.1),

    # Incubation period: average days from exposure to infectiousness
    sliderInput(ns("incubation_period"),
                label = "Incubation period (days)",
                min = 1, max = 14, value = INITIAL_INCUBATION_PERIOD,
                step = 1),

    # Infectious period: average days an individual remains infectious
    sliderInput(ns("infectious_period"),
                label = "Infectious period (days)",
                min = 1, max = 21, value = INITIAL_INFECTIOUS_PERIOD,
                step = 1),

    # IFR as percentage [0,100]; converted internally by percent_to_prop()
    sliderInput(ns("ifr_value"),
                label = "Infection fatality rate (IFR, %)",
                min = 0.01, max = 5.0, value = INITIAL_IFR * 100,
                step = 0.01)
  )
}


# ------------------------------------------------------------
# Function: ui_policy_params()
# Description:
#   Builds the public policy parameter control panel.
#   Provides radio buttons for intervention type and a
#   compliance slider. Dynamic policy description rendered
#   via uiOutput — corresponding renderUI in mod_server.R.
# Parameters:
#   ns – Shiny namespace function produced by NS(id).
# Returns:
#   A div() containing radioButtons, uiOutput, and sliderInput.
# ------------------------------------------------------------
ui_policy_params <- function(ns) {
  div(
    panel_title_ui("Public policy"),

    # Two intervention options — exactly what the model
    # implements (mod_model.R, Step 3).
    radioButtons(
      inputId  = ns("policy_type"),
      label    = "Type of intervention",
      choices  = c(
        "No intervention"   = "no_intervention",
        "Static mitigation" = "static_mitigation"
      ),
      selected = "no_intervention"
    ),

    # Dynamic description rendered server-side (mod_server.R)
    uiOutput(ns("policy_description")),
    br(),

    # Compliance: scales the R0 reduction applied by the policy
    sliderInput(ns("compliance_level"),
                label = "Compliance level (%)",
                min = 0, max = 100, value = 50, step = 5),

    tags$small(
      class = "afa-help-text",
      HTML("Static mitigation reduces effective R<sub>0</sub> by up to 50% at full compliance. It has no effect when \"No intervention\" is selected.")
    )
  )
}


# ------------------------------------------------------------
# Function: ui_resource_params()
# Description:
#   Builds the healthcare resource parameter control panel.
#   Capacity inputs update plot thresholds only (no ODE re-run).
#   Rate sliders re-trigger the simulation.
# Parameters:
#   ns – Shiny namespace function produced by NS(id).
# Returns:
#   A div() containing numericInput and sliderInput widgets.
# ------------------------------------------------------------
ui_resource_params <- function(ns) {
  div(
    panel_title_ui("Healthcare resources"),

    tags$small(
      class = "afa-help-text",
      "Capacity values update Resource Pressure thresholds. ",
      "Rate sliders re-run the simulation automatically."
    ),
    br(), br(),

    # Capacity inputs — affect plot threshold lines only
    numericInput(ns("icu_capacity"),
                 "ICU Bed Capacity",
                 INITIAL_ICU_CAPACITY, min = 0),
    numericInput(ns("ventilator_availability"),
                 "Ventilator availability",
                 INITIAL_VENTILATOR_AVAILABILITY, min = 0),
    numericInput(ns("healthcare_staff"),
                 "Available healthcare staff",
                 INITIAL_HEALTHCARE_STAFF, min = 0),

    # Rate sliders — stored as percentages [0,100]
    sliderInput(ns("icu_admission_rate"),
                "ICU Admission Rate (%)",
                min = 0.1, max = 30.0,
                value = INITIAL_ICU_RATE * 100, step = 0.1),
    sliderInput(ns("ventilator_usage_rate"),
                "Ventilator usage rate (%)",
                min = 0.1, max = 10.0,
                value = INITIAL_VENTILATOR_RATE * 100, step = 0.1)
  )
}


# ------------------------------------------------------------
# Function: ui_scope_params()
# Description:
#   Builds the simulation scope control panel, exposing
#   population size and simulation date range as user-editable
#   inputs. These parameters are wired to app_params in
#   mod_server.R (one combined, validated observer).
#
#   Design decision: dateInput() was chosen over separate
#   numeric fields for day, month, and year because it renders
#   a native calendar picker — the most intuitive interaction
#   for date selection by non-technical users.
#
# Parameters:
#   ns – Shiny namespace function produced by NS(id).
# Returns:
#   A div() containing numericInput and dateInput widgets.
# ------------------------------------------------------------
ui_scope_params <- function(ns) {
  div(
    panel_title_ui("Simulation scope"),

    tags$small(
      class = "afa-help-text",
      "Adjust total population and simulation period. ",
      "Changes re-run the model automatically. ",
      "The population must be at least 10,001 (the simulation starts with ",
      "10,000 infectious people) and the period must end after it starts."
    ),
    br(), br(),

    # Total population — numericInput allows precise entry of
    # any country-level or subnational population figure.
    numericInput(
      inputId = ns("population"),
      label   = "Total population",
      value   = POPULATION_ARGENTINA,
      min     = 10001,
      step    = 100000
    ),

    # Simulation start date — dateInput renders a calendar
    # picker, chosen over separate numeric fields for
    # intuitiveness (see design decision note above).
    dateInput(
      inputId  = ns("start_date"),
      label    = "Simulation start date",
      value    = START_DATE,
      format   = "d MM yyyy",
      language = "en"
    ),

    # Simulation end date — same rationale as start date.
    dateInput(
      inputId  = ns("end_date"),
      label    = "Simulation end date",
      value    = END_DATE,
      format   = "d MM yyyy",
      language = "en"
    )
  )
}


# ------------------------------------------------------------
# Function: ui_main()
# Description:
#   Assembles the full Advanced View page layout:
#     - Sticky left sidebar (parameter panels) on AfA tint
#     - Right-hand tabset with three output panels
#     - Footer bar with project attribution
#   (The navbar is rendered by mod_menu_ui().)
#
#   Both ns and ns_viz resolve to the same namespace (viz_id)
#   so input observers (mod_server.R) and plot outputs
#   (mod_viz.R) share a consistent id prefix.
# Parameters:
#   viz_id – character; module id; must match mod_server() id.
# Returns:
#   A tagList() containing the complete Advanced View layout.
# ------------------------------------------------------------
ui_main <- function(viz_id) {

  # Both aliases point to the same namespace; kept separate for
  # clarity — ns scopes server inputs, ns_viz scopes plot outputs
  ns     <- NS(viz_id)
  ns_viz <- NS(viz_id)

  tagList(
    useShinyjs(),

    # --------------------------------------------------------
    # Inline CSS — sticky sidebar scroll and panel colours
    # --------------------------------------------------------
    tags$head(
      tags$style(HTML("
        #controls-col {
          position: sticky;
          top: 0px;
          height: calc(100vh - 52px);
          overflow-y: auto;
          overflow-x: hidden;
          padding: 14px 12px;
          background-color: #F4F6F5;
          border-right: 0.5px solid #D0D4CE;
        }

        #controls-col::-webkit-scrollbar { width: 4px; }
        #controls-col::-webkit-scrollbar-thumb {
          background: #D0D4CE;
          border-radius: 4px;
        }

        #controls-col .well {
          background-color: #FFFFFF !important;
          border: 0.5px solid #D0D4CE !important;
          border-radius: 8px !important;
          padding: 12px !important;
          margin-bottom: 10px !important;
          box-shadow: none !important;
        }

        .content-area {
          background-color: #F4F6F5;
          min-height: calc(100vh - 52px);
          padding: 16px;
        }

        .tab-content {
          background-color: #F4F6F5;
        }

        .chart-card {
          background: #ffffff;
          border: 0.5px solid #D0D4CE;
          border-radius: 8px;
          padding: 14px 16px;
          margin-bottom: 14px;
        }

        .afa-footer {
          background: #F8F5F1;
          border-top: 0.5px solid #D0D4CE;
          padding: 8px 20px;
          display: flex;
          justify-content: space-between;
          align-items: center;
          font-size: 0.875rem;
        }
      "))
    ),

    # --------------------------------------------------------
    # Main layout: full-width, no fluidPage padding
    # --------------------------------------------------------
    tags$div(
      style = "display:flex; flex-direction:column; min-height:100vh;",

      # --- Left + right columns ---
      tags$div(
        style = "display:flex; flex:1;",

        # Left sidebar
        tags$div(
          id    = "controls-col",
          style = "width:300px; flex-shrink:0;",
          wellPanel(ui_seir_params(ns)),
          wellPanel(ui_policy_params(ns)),
          wellPanel(ui_resource_params(ns)),
          wellPanel(ui_scope_params(ns))
          # Run Simulation button — temporarily hidden.
          # Uncomment to restore manual-trigger behaviour and
          # re-enable the observeEvent in mod_server.R.
          # actionButton(ns("run_simulation"), "Run Simulation",
          #              class = "btn btn-primary w-100")
        ),

        # Right content area
        tags$div(
          class = "content-area",
          style = "flex:1; overflow-y:auto;",

          tabsetPanel(

            # Tab 1: SEIR compartment dynamics and cumulative metrics
            tabPanel(
              "Epidemic curves",
              br(),
              tags$div(
                class = "chart-card",
                tags$h6(
                  "Figure 1. Population in each model compartment over time",
                  style = "color:#1E2A16; font-weight:600; font-size:1rem; margin-bottom:8px;"
                ),
                plotOutput(ns_viz("seir_plot"), height = "300px")
              ),
              tags$div(
                class = "chart-card",
                tags$h6(
                  "Figure 2. Simulated cumulative cases and deaths over time",
                  style = "color:#1E2A16; font-weight:600; font-size:1rem; margin-bottom:8px;"
                ),
                plotOutput(ns_viz("cases_deaths_plot"), height = "260px")
              )
            ),

            # Tab 2: Healthcare resource demand vs. capacity
            tabPanel(
              "Resource pressure",
              br(),
              tags$div(
                class = "chart-card",
                tags$h6(
                  "Figure 3. Critical resource demand and capacity over time",
                  style = "color:#1E2A16; font-weight:600; font-size:1rem; margin-bottom:4px;"
                ),
                tags$small(
                  class = "afa-help-text",
                  "Shaded area indicates periods where simulated demand exceeds capacity."
                ),
                br(),
                plotOutput(ns_viz("resource_pressure_plot"),
                           height = "460px")
              )
            ),

            # Tab 3: Simulation output table and CSV download
            tabPanel(
              "Simulated data",
              br(),
              tags$div(
                class = "chart-card",
                tags$h6(
                  "Table 1. Simulation output, first 10 rows",
                  style = "color:#1E2A16; font-weight:600; font-size:1rem; margin-bottom:12px;"
                ),
                tableOutput(ns("simulated_data_table")),
                br(),
                # Full results exported via write.csv2()
                # (semicolon separator, European locale)
                downloadButton(
                  ns("download_csv"),
                  label = "Download results (CSV)",
                  class = "btn btn-primary"
                )
              )
            )
          )
        )
      )
    )
  )
}
