# ============================================================
# File: mod_server_simple.R
# ------------------------------------------------------------
# Description: Simple View server module for the SEIR Dashboard.
#   Handles isolated SEIR model execution and reactive alarm
#   logic for the three KPI cards.
#
#   Design contract:
#     - State is FULLY ISOLATED from the Advanced View.
#       Both views initialise from the same dataset snapshot
#       (dataset_params), then evolve independently as the
#       user adjusts their own controls. Changes in one view
#       never affect the other.
#     - The ODE solver is re-run when a scenario control changes
#       (simple_r0, simple_compliance, simulation dates).
#     - Alarm thresholds (six numeric inputs) do NOT re-run
#       the ODE solver — they only update the indicators.
#     - mod_data_server() and model_seir_server() are called
#       internally under the "simple_data" and "simple_seir"
#       namespace ids to avoid collisions with the Advanced View.
#
#   Shared helpers (alarm_shape_svg, state_label_ui,
#   metric_value_ui, resolve_alarm_state, coalesce_num, ...) are
#   defined in mod_helpers_simple.R, which loadSupport() sources
#   before this file (alphabetical order: h < s).
#
#   Alarm states per card:
#     "controlled" | "warning" | "critical" | "unknown"
#   "unknown" (shown as "No data") means the indicator could not
#   be calculated; the card then says why. It is never reported
#   as "controlled".
#
#   AfA palette used for alarm shapes:
#     #3EA27F (sea green) | #F59342 (orange) | #752111 (dark red)
#
# Author: Cristian Paez
# Created: 2026-03-19
# Updated: 2026-10 — Testing recommendation (round 1):
#   * Calibrated parameters (CSV) are converted with
#     resolve_calibrated_params(): the IFR was previously
#     multiplied by 100 a second time here.
#   * Start / end date controls (validated, minimum 14 days
#     because the growth indicator compares two 7-day windows).
#   * Policy default is "static_mitigation" (the only mitigation
#     mode the model implements).
#   * Visible threshold feedback under every card.
#   * N/A values carry an explanation; unknown never "Controlled".
# ============================================================


# ------------------------------------------------------------
# Function: mod_server_simple()
# Description:
#   Server logic for the Simple View. Maintains isolated SEIR
#   model state initialised from global.R. Runs the ODE solver
#   when scenario controls change and updates KPI card alarm
#   states reactively when thresholds change.
# Parameters:
#   id               – Shiny module identifier.
#   dataset_selector – reactiveVal(character); active source key,
#                      passed through for logging only.
#   dataset_params   – reactiveVal(list); calibrated parameters
#                      from the loaded dataset ($parametros,
#                      $recursos, $poblacion). Used to initialise
#                      simple_params on dataset load; controls take
#                      over after that.
# Returns:
#   None (side effects only: renderUI calls for the three cards).
# ------------------------------------------------------------
mod_server_simple <- function(id, dataset_selector,
                              dataset_params = NULL) {
  moduleServer(id, function(input, output, session) {

    # --------------------------------------------------------
    # Log module start
    # --------------------------------------------------------
    log_message("INFO", "mod_server_simple started", .module = "SIMPLE")

    # --------------------------------------------------------
    # Isolated parameter store
    # Initialised from dataset_params when a calibrated dataset
    # is loaded; falls back to global.R constants for mock.
    # Controls in the Simple View write ONLY to these values.
    # The Advanced View has no access to this reactiveValues.
    # --------------------------------------------------------
    simple_params <- reactiveValues(
      r0_value         = INITIAL_R0,
      compliance_level = 50,

      # Fixed parameters — not exposed in Simple View controls
      incubation_period = INITIAL_INCUBATION_PERIOD,
      infectious_period = INITIAL_INFECTIOUS_PERIOD,
      ifr_value         = INITIAL_IFR * 100,    # percent [0, 100]

      icu_capacity            = INITIAL_ICU_CAPACITY,
      icu_admission_rate      = INITIAL_ICU_RATE * 100,    # percent
      ventilator_availability = INITIAL_VENTILATOR_AVAILABILITY,
      ventilator_usage_rate   = INITIAL_VENTILATOR_RATE * 100, # percent
      healthcare_staff        = INITIAL_HEALTHCARE_STAFF,

      # The model implements ONE mitigation mode (see mod_model.R,
      # Step 3); the compliance slider scales it.
      policy_type = "static_mitigation",

      start_date  = START_DATE,
      end_date    = END_DATE,
      population  = POPULATION_ARGENTINA,

      trigger_sim = 0L
    )

    # --------------------------------------------------------
    # Dataset parameter initialisation
    # Applies the parameters of the loaded dataset (user CSV) or
    # restores the defaults (mock) so the Simple View starts from
    # the same snapshot as the Advanced View. Conversions are done
    # ONCE, by resolve_calibrated_params().
    # --------------------------------------------------------
    observeEvent(dataset_params(), {
      dp <- dataset_params()
      req(!is.null(dp))

      vals <- tryCatch(
        resolve_calibrated_params(dp),
        error = function(e) {
          log_message("ERROR", paste("Dataset parameters rejected:", conditionMessage(e)),
                      .module = "SIMPLE")
          showNotification(conditionMessage(e), type = "error",
                           duration = 10, session = session)
          NULL
        }
      )
      req(!is.null(vals))

      isolate({
        simple_params$r0_value                <- vals$r0_value
        simple_params$incubation_period       <- vals$incubation_period
        simple_params$infectious_period       <- vals$infectious_period
        simple_params$ifr_value               <- vals$ifr_value
        simple_params$icu_capacity            <- vals$icu_capacity
        simple_params$ventilator_availability <- vals$ventilator_availability
        simple_params$healthcare_staff        <- vals$healthcare_staff
        simple_params$icu_admission_rate      <- vals$icu_admission_rate
        simple_params$ventilator_usage_rate   <- vals$ventilator_usage_rate
        simple_params$population              <- vals$population
        simple_params$trigger_sim             <- simple_params$trigger_sim + 1L
      })

      # Move the slider after the UI has been flushed
      session$onFlushed(function() {
        updateSliderInput(session, "simple_r0", value = vals$r0_value)
      }, once = TRUE)

      log_message("INFO",
                  "Simple View initialised from dataset parameters",
                  .module = "SIMPLE")
    }, ignoreNULL = TRUE)

    # --------------------------------------------------------
    # Slider observers — update isolated params and trigger sim
    # ignoreInit = FALSE so the initial slider value fires
    # immediately on load and the first simulation runs.
    # --------------------------------------------------------
    observeEvent(input$simple_r0, {
      req(!is.null(input$simple_r0))
      simple_params$r0_value    <- input$simple_r0
      simple_params$trigger_sim <- simple_params$trigger_sim + 1L
      log_message("DEBUG",
                  paste("Simple View R0 changed to:", input$simple_r0),
                  .module = "SIMPLE")
    }, ignoreInit = FALSE)

    observeEvent(input$simple_compliance, {
      req(!is.null(input$simple_compliance))
      simple_params$compliance_level <- input$simple_compliance
      simple_params$trigger_sim      <- simple_params$trigger_sim + 1L
    }, ignoreInit = FALSE)

    # --------------------------------------------------------
    # Simulation period (start / end dates)
    # Validated as a set before anything is stored. The Simple
    # View needs at least 14 days: the trajectory indicator
    # compares two 7-day windows. While a field is empty or
    # invalid a message stays on screen, the previous results are
    # kept and no simulation runs.
    # --------------------------------------------------------
    observeEvent(
      list(input$simple_start_date, input$simple_end_date),
      {
        problems <- validate_simulation_inputs(
          population = simple_params$population,
          start_date = input$simple_start_date,
          end_date   = input$simple_end_date,
          min_days   = 14L
        )

        if (length(problems) > 0) {
          log_message("WARN", paste("Simple View period rejected:",
                                    paste(problems, collapse = " | ")),
                      .module = "SIMPLE")
          showNotification(
            tagList(
              tags$strong("The simulation was not updated."),
              tags$ul(lapply(problems, tags$li))
            ),
            type     = "error",
            duration = NULL,
            id       = session$ns("period_error"),
            session  = session
          )
          return()
        }

        removeNotification(session$ns("period_error"), session = session)

        simple_params$start_date  <- input$simple_start_date
        simple_params$end_date    <- input$simple_end_date
        simple_params$trigger_sim <- simple_params$trigger_sim + 1L
      },
      ignoreInit = TRUE,
      ignoreNULL = FALSE
    )

    # --------------------------------------------------------
    # Data module — generates raw initial state for the ODE.
    # Uses "simple_data" namespace to avoid collision with the
    # Advanced View data module ("data_sim").
    # --------------------------------------------------------
    simple_raw_data <- mod_data_server(
      "simple_data",
      params = reactive({
        list(
          start_date  = simple_params$start_date,
          end_date    = simple_params$end_date,
          population  = simple_params$population,
          trigger_sim = simple_params$trigger_sim
        )
      })
    )

    # --------------------------------------------------------
    # SEIR model — runs under "simple_seir" namespace.
    # Receives only the isolated simple_params; the Advanced
    # View parameters are never referenced here.
    # --------------------------------------------------------
    simple_model_output <- model_seir_server(
      "simple_seir",
      input_params = reactive({
        list(
          r0_value          = simple_params$r0_value,
          incubation_period = simple_params$incubation_period,
          infectious_period = simple_params$infectious_period,
          ifr_value         = simple_params$ifr_value,

          icu_capacity            = simple_params$icu_capacity,
          ventilator_availability = simple_params$ventilator_availability,
          healthcare_staff        = simple_params$healthcare_staff,

          icu_admission_rate    = simple_params$icu_admission_rate,
          ventilator_usage_rate = simple_params$ventilator_usage_rate,

          policy_type      = simple_params$policy_type,
          compliance_level = simple_params$compliance_level,

          start_date  = simple_params$start_date,
          end_date    = simple_params$end_date,
          population  = simple_params$population,

          trigger_sim = simple_params$trigger_sim
        )
      }),
      raw_data_df = simple_raw_data
    )

    # --------------------------------------------------------
    # Computed KPI metrics
    # Each reactive returns list(value, reason): `value` is a
    # number or NA_real_; `reason` explains an NA in plain
    # English. Kept separate so threshold changes re-evaluate
    # alarm states without re-running the ODE solver.
    # --------------------------------------------------------
    no_results_reason <- "No simulation results yet. Check the scenario parameters and the simulation dates."

    # --- KPI 1: Weekly growth rate of I ---
    # Compares the mean of the infectious compartment (I) over
    # the final 7 simulation days to the preceding 7 days.
    # Returns a percentage change; negative values = declining.
    kpi_growth <- reactive({
      df <- simple_model_output()
      if (is.null(df)) return(list(value = NA_real_, reason = no_results_reason))

      if (nrow(df) < 14) {
        return(list(
          value  = NA_real_,
          reason = "At least 14 simulated days are needed to compare two weeks. Extend the simulation period."))
      }

      n     <- nrow(df)
      last7 <- mean(df$I[(n - 6):n],        na.rm = TRUE)
      prev7 <- mean(df$I[(n - 13):(n - 7)], na.rm = TRUE)

      if (is.na(prev7) || prev7 == 0) {
        return(list(
          value  = NA_real_,
          reason = "There were no infectious cases in the previous week, so a growth rate cannot be calculated."))
      }
      list(value = ((last7 - prev7) / prev7) * 100, reason = NULL)
    })

    # --- KPI 2: ICU occupancy on the final simulation day as % of capacity ---
    # Uses the last row of ICU_Occupancy_Sim rather than the historical
    # peak. The rolling-sum nature of ICU_Occupancy_Sim means the peak
    # can be orders of magnitude above capacity under high-transmission
    # scenarios, producing misleading percentages for a decision-maker
    # card. The final-day value reflects the current epidemic status,
    # which is the intended signal of this view.
    kpi_icu <- reactive({
      df <- simple_model_output()
      if (is.null(df)) return(list(value = NA_real_, reason = no_results_reason))

      cap <- simple_params$icu_capacity
      if (!is_valid_number(cap) || cap <= 0) {
        return(list(
          value  = NA_real_,
          reason = "ICU capacity is zero or missing, so occupancy cannot be shown as a percentage of capacity."))
      }
      last_icu <- df$ICU_Occupancy_Sim[nrow(df)]
      if (!is_valid_number(last_icu)) {
        return(list(value = NA_real_,
                    reason = "ICU occupancy could not be calculated for the final day."))
      }
      list(value = (last_icu / cap) * 100, reason = NULL)
    })

    # --- KPI 3: Cumulative deaths on the final simulation day as % of population ---
    # Uses the last row of Cumulative_Deaths (the end-of-simulation total).
    kpi_deaths <- reactive({
      df <- simple_model_output()
      if (is.null(df)) return(list(value = NA_real_, reason = no_results_reason))

      pop <- simple_params$population
      if (!is_valid_number(pop) || pop <= 0) {
        return(list(
          value  = NA_real_,
          reason = "The population is zero or missing, so deaths cannot be shown as a percentage of the population."))
      }
      last_deaths <- df$Cumulative_Deaths[nrow(df)]
      if (!is_valid_number(last_deaths)) {
        return(list(value = NA_real_,
                    reason = "Cumulative deaths could not be calculated for the final day."))
      }
      list(value = (last_deaths / pop) * 100, reason = NULL)
    })

    # --------------------------------------------------------
    # Thresholds in force (NULL/NA-safe, defaults as in the UI)
    # --------------------------------------------------------
    thr_growth <- reactive(list(
      warn = coalesce_num(input$thr_growth_warn, 1),
      crit = coalesce_num(input$thr_growth_crit, 20)))
    thr_icu <- reactive(list(
      warn = coalesce_num(input$thr_icu_warn, 70),
      crit = coalesce_num(input$thr_icu_crit, 100)))
    thr_deaths <- reactive(list(
      warn = coalesce_num(input$thr_deaths_warn, 0.05),
      crit = coalesce_num(input$thr_deaths_crit, 0.20)))

    # --------------------------------------------------------
    # Alarm state computations
    # Each reactive calls resolve_alarm_state() (defined in
    # mod_helpers_simple.R). These do NOT depend on trigger_sim —
    # they react only to kpi_* changes and threshold input
    # changes. A missing value gives "unknown", never
    # "controlled".
    # --------------------------------------------------------
    alarm_trajectory <- reactive({
      t <- thr_growth()
      resolve_alarm_state(kpi_growth()$value, t$warn, t$crit)
    })
    alarm_icu <- reactive({
      t <- thr_icu()
      resolve_alarm_state(kpi_icu()$value, t$warn, t$crit)
    })
    alarm_deaths <- reactive({
      t <- thr_deaths()
      resolve_alarm_state(kpi_deaths()$value, t$warn, t$crit)
    })

    # --------------------------------------------------------
    # Helpers shared by the three cards
    # --------------------------------------------------------

    # Value + unit, or N/A with the reason underneath
    render_value <- function(kpi, unit_label, signed = FALSE, digits = 2) {
      val <- kpi$value
      if (!is_valid_number(val)) {
        return(tagList(
          metric_value_ui("N/A", unit_label),
          unavailable_note_ui(kpi$reason)
        ))
      }
      sign <- if (signed && val >= 0) "+" else ""
      metric_value_ui(paste0(sign, round(val, digits), "%"), unit_label)
    }

    # Threshold feedback; adds a hint when warning >= critical
    render_feedback <- function(state, thr, unit = "%") {
      tagList(
        threshold_feedback_ui(state, thr$warn, thr$crit, unit),
        if (thr$warn >= thr$crit) {
          tags$p(class = "afa-unavailable-note",
                 "The warning threshold should be lower than the critical threshold.")
        }
      )
    }

    # --------------------------------------------------------
    # Rendered outputs — Card 1: Epidemic Trajectory
    # --------------------------------------------------------
    output$shape_trajectory <- renderUI(alarm_shape_svg(alarm_trajectory(), size = 64))
    output$label_trajectory <- renderUI(state_label_ui(alarm_trajectory()))
    output$value_trajectory <- renderUI(
      render_value(kpi_growth(), "weekly growth rate of I", signed = TRUE))
    output$feedback_trajectory <- renderUI(
      render_feedback(alarm_trajectory(), thr_growth()))

    # --------------------------------------------------------
    # Rendered outputs — Card 2: ICU Pressure
    # --------------------------------------------------------
    output$shape_icu <- renderUI(alarm_shape_svg(alarm_icu(), size = 64))
    output$label_icu <- renderUI(state_label_ui(alarm_icu()))
    output$value_icu <- renderUI(
      render_value(kpi_icu(), "ICU occupancy vs capacity (final day)"))
    output$feedback_icu <- renderUI(
      render_feedback(alarm_icu(), thr_icu()))

    # --------------------------------------------------------
    # Rendered outputs — Card 3: Cumulative Impact
    # --------------------------------------------------------
    output$shape_deaths <- renderUI(alarm_shape_svg(alarm_deaths(), size = 64))
    output$label_deaths <- renderUI(state_label_ui(alarm_deaths()))
    output$value_deaths <- renderUI(
      render_value(kpi_deaths(), "cumulative deaths as % of population (final day)"))
    output$feedback_deaths <- renderUI(
      render_feedback(alarm_deaths(), thr_deaths()))

    log_message("INFO", "mod_server_simple observers registered",
                .module = "SIMPLE")
  })
}
