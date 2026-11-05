# ============================================================
# File: R/mod_server.R
# ------------------------------------------------------------
# Description:
#   Main server module for the Shiny application. Integrates:
#     - Dataset selection (mock / user-uploaded CSV)
#     - Parameter management and validation
#     - SEIR model execution
#     - Visualisation module wiring (viz_plot_server)
#
# Notes (design decisions):
#   - Internal contract: ifr_value is ALWAYS a percentage in [0, 100].
#   - IFR from a calibrated dataset is converted EXACTLY ONCE, by
#     resolve_calibrated_params() / normalise_ifr_to_pct() in
#     utils_helpers.R. Nothing in this file multiplies it by 100.
#   - Simulation trigger: trigger_sim is incremented ONLY on:
#       * dataset change
#       * explicit user action (Run Simulation)
#       * user parameter edits (field-level events)
#     This avoids reactive feedback loops.
#   - Population and simulation dates are validated BEFORE they
#     are stored (validate_simulation_inputs()). If any of them is
#     empty or invalid the user sees an on-screen message and no
#     simulation is run; the last valid values stay in force.
#   - Resource parameters (ICU capacity, ventilators) affect the
#     Resource Pressure plot directly via reactive values passed
#     to viz_plot_server. They do not re-run the ODE solver.
#   - Calibrated parameter sets (currently: user CSV) arrive via
#     the dataset_params reactive created in app.R. Loading the
#     mock dataset restores the global defaults.
#
# Author: Cristian Paez
# Created: 2025-11-07
# Updated: 2026-10 — Testing recommendation (round 1).
# ============================================================

mod_server <- function(id, dataset_selector,
                      dataset_params = NULL) {
  moduleServer(id, function(input, output, session) {

    # --------------------------------------------------------
    # Local helpers
    # --------------------------------------------------------

    # Copy a flat list of parameter values (as returned by
    # resolve_calibrated_params()) into app_params and push the
    # same values to the Advanced View controls.
    # isolate() avoids intermediate reactive states. The control
    # updates are sent once the current flush has completed, so
    # they are never lost when the Advanced View UI has only just
    # been rendered.
    apply_param_values <- function(vals, app_params) {
      isolate({
        for (nm in names(vals)) app_params[[nm]] <- vals[[nm]]
      })

      session$onFlushed(function() {
        updateSliderInput(session, "r0_value",
                          value = vals$r0_value)
        updateSliderInput(session, "incubation_period",
                          value = vals$incubation_period)
        updateSliderInput(session, "infectious_period",
                          value = vals$infectious_period)
        updateSliderInput(session, "ifr_value",
                          value = vals$ifr_value)
        updateNumericInput(session, "icu_capacity",
                           value = vals$icu_capacity)
        updateNumericInput(session, "ventilator_availability",
                           value = vals$ventilator_availability)
        updateNumericInput(session, "healthcare_staff",
                           value = vals$healthcare_staff)
        updateSliderInput(session, "icu_admission_rate",
                          value = vals$icu_admission_rate)
        updateSliderInput(session, "ventilator_usage_rate",
                          value = vals$ventilator_usage_rate)
        if (!is.null(vals$population)) {
          updateNumericInput(session, "population",
                             value = vals$population)
        }
      }, once = TRUE)
    }

    # --------------------------------------------------------
    # Logging on module start (best-effort)
    # --------------------------------------------------------
    log_message(
      "INFO",
      paste0("mod_server started; dataset_selector() = ", dataset_selector()),
      .module = "SERVER"
    )

    # --------------------------------------------------------
    # ReactiveValues: global simulation parameters
    # --------------------------------------------------------
    app_params <- reactiveValues(
      r0_value             = INITIAL_R0,
      incubation_period    = INITIAL_INCUBATION_PERIOD,
      infectious_period    = INITIAL_INFECTIOUS_PERIOD,
      ifr_value            = INITIAL_IFR * 100,   # percent [0,100]

      icu_capacity              = INITIAL_ICU_CAPACITY,
      ventilator_availability   = INITIAL_VENTILATOR_AVAILABILITY,
      healthcare_staff          = INITIAL_HEALTHCARE_STAFF,
      icu_admission_rate        = INITIAL_ICU_RATE * 100,       # percent [0,100]
      ventilator_usage_rate     = INITIAL_VENTILATOR_RATE * 100,# percent [0,100]

      policy_type      = "no_intervention",
      compliance_level = 50,

      start_date  = START_DATE,
      end_date    = END_DATE,
      population  = POPULATION_ARGENTINA,

      trigger_sim = 0L   # integer counter used as simulation trigger
    )

    # --------------------------------------------------------
    # Dataset loading based on user selection
    # --------------------------------------------------------
    observeEvent(dataset_selector(), {
      req(dataset_selector())

      if (dataset_selector() == "csv") {
        # CSV: parameters are applied to app_params and to the
        # Advanced View controls by the dataset_params observer
        # below.
        log_message("INFO", "CSV dataset selected — parameters applied via dataset_params",
                    .module = "SERVER")

      } else {
        log_message("INFO", "Using simulated mock dataset", .module = "SERVER")
      }

      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = FALSE)

    # --------------------------------------------------------
    # Dataset params observer — applies the parameters of the
    # loaded dataset to app_params and to every Advanced View
    # control. Fires when dataset_params changes, i.e. each time
    # a dataset is loaded:
    #   - user CSV : calibrated values are applied;
    #   - mock     : the global defaults are restored.
    # --------------------------------------------------------
    observeEvent(dataset_params(), {
      dp <- dataset_params()
      req(!is.null(dp))

      vals <- tryCatch(
        resolve_calibrated_params(dp),
        error = function(e) {
          log_message("ERROR", paste("Dataset parameters rejected:", conditionMessage(e)),
                      .module = "SERVER")
          showNotification(conditionMessage(e), type = "error",
                           duration = 10, session = session)
          NULL
        }
      )
      req(!is.null(vals))

      apply_param_values(vals, app_params)
      app_params$trigger_sim <- app_params$trigger_sim + 1L

      log_message("INFO",
                  "Advanced View updated from dataset parameters",
                  .module = "SERVER")
    }, ignoreNULL = TRUE)

    # --------------------------------------------------------
    # Parameter observers — SEIR epidemiological parameters
    # Each observer updates app_params and increments trigger_sim
    # to re-run the ODE solver automatically.
    # --------------------------------------------------------

    observeEvent(input$r0_value, {
      app_params$r0_value <- input$r0_value
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    observeEvent(input$incubation_period, {
      app_params$incubation_period <- input$incubation_period
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    observeEvent(input$infectious_period, {
      app_params$infectious_period <- input$infectious_period
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    observeEvent(input$ifr_value, {
      # Invalid values are reported, never raised as an error —
      # an error inside an observer would end the session.
      if (!is_valid_number(input$ifr_value) ||
          input$ifr_value < 0 || input$ifr_value > 100) {
        showNotification(
          "Infection fatality rate must be a number between 0 and 100 (%). The simulation was not updated.",
          type = "error", duration = 8,
          id = session$ns("ifr_error"), session = session)
        return()
      }
      removeNotification(session$ns("ifr_error"), session = session)
      app_params$ifr_value <- input$ifr_value
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    # --------------------------------------------------------
    # Parameter observers — Public Policy
    # Policy and compliance affect the effective R0 inside the
    # ODE solver (see mod_model.R Step 3), so trigger_sim fires.
    # --------------------------------------------------------

    observeEvent(input$policy_type, {
      app_params$policy_type <- input$policy_type
      app_params$trigger_sim <- app_params$trigger_sim + 1L
      log_message("INFO",
                  paste("Policy changed to:", input$policy_type),
                  .module = "SERVER")
    }, ignoreInit = TRUE)

    observeEvent(input$compliance_level, {
      app_params$compliance_level <- input$compliance_level
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    # --------------------------------------------------------
    # Parameter observers — Healthcare resources
    # ICU capacity and ventilator availability do NOT re-run
    # the ODE solver — they only affect the Resource Pressure
    # plot threshold lines. ICU/ventilator RATES do re-run the
    # solver because they change the demand calculation.
    # --------------------------------------------------------

    observeEvent(input$icu_capacity, {
      req(!is.null(input$icu_capacity), input$icu_capacity >= 0)
      app_params$icu_capacity <- input$icu_capacity
      # Note: no trigger_sim increment — capacity only affects plot thresholds
    }, ignoreInit = TRUE)

    observeEvent(input$ventilator_availability, {
      req(!is.null(input$ventilator_availability), input$ventilator_availability >= 0)
      app_params$ventilator_availability <- input$ventilator_availability
      # Note: no trigger_sim increment — availability only affects plot thresholds
    }, ignoreInit = TRUE)

    observeEvent(input$healthcare_staff, {
      req(!is.null(input$healthcare_staff))
      app_params$healthcare_staff <- input$healthcare_staff
    }, ignoreInit = TRUE)

    observeEvent(input$icu_admission_rate, {
      app_params$icu_admission_rate <- input$icu_admission_rate
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    observeEvent(input$ventilator_usage_rate, {
      app_params$ventilator_usage_rate <- input$ventilator_usage_rate
      app_params$trigger_sim <- app_params$trigger_sim + 1L
    }, ignoreInit = TRUE)

    # --------------------------------------------------------
    # Parameter observers — Simulation scope
    # (total population and simulation date range)
    #
    # One observer handles the three fields together because
    # they must be valid AS A SET (e.g. end date after start
    # date). ignoreNULL = FALSE is essential: when the user
    # clears a field the input becomes NULL / NA and the change
    # must still be inspected so the user is told what is wrong.
    #
    # While any field is empty or invalid:
    #   - an error message stays on screen;
    #   - app_params is NOT modified and NO simulation runs;
    #   - the last valid results remain displayed.
    # --------------------------------------------------------
    observeEvent(
      list(input$population, input$start_date, input$end_date),
      {
        problems <- validate_simulation_inputs(
          population = input$population,
          start_date = input$start_date,
          end_date   = input$end_date
        )

        if (length(problems) > 0) {
          log_message("WARN", paste("Simulation scope rejected:",
                                    paste(problems, collapse = " | ")),
                      .module = "SERVER")
          showNotification(
            tagList(
              tags$strong("The simulation was not updated."),
              tags$ul(lapply(problems, tags$li))
            ),
            type     = "error",
            duration = NULL,   # stays until the inputs are fixed
            id       = session$ns("scope_error"),
            session  = session
          )
          return()
        }

        removeNotification(session$ns("scope_error"), session = session)

        app_params$population  <- input$population
        app_params$start_date  <- input$start_date
        app_params$end_date    <- input$end_date
        app_params$trigger_sim <- app_params$trigger_sim + 1L
      },
      ignoreInit = TRUE,
      ignoreNULL = FALSE
    )

    # --------------------------------------------------------
    # Policy description: dynamic text below the selector
    # Explains to the user what each policy does in the model.
    # --------------------------------------------------------
    output$policy_description <- renderUI({
      req(input$policy_type)
      desc <- switch(input$policy_type,
        "no_intervention"   = "No measures applied. R₀ remains at its base value.",
        "static_mitigation" = "A constant reduction of R₀ for the whole simulation, proportional to compliance (up to 50% at full compliance).",
        ""
      )
      tags$small(class = "afa-help-text", desc)
    })

    # --------------------------------------------------------
    # Manual simulation trigger (Run Simulation button)
    # Forces a full re-run regardless of what changed.
    # --------------------------------------------------------
    observeEvent(input$run_simulation, {
      app_params$trigger_sim <- app_params$trigger_sim + 1L
      log_message("INFO", "Simulation manually triggered", .module = "SERVER")
    }, ignoreInit = TRUE)

    # --------------------------------------------------------
    # Data Module: generate initial raw dataset for ODE solver
    # --------------------------------------------------------
    simulated_raw_data <- mod_data_server(
      "data_sim",
      params = reactive({
        list(
          start_date  = app_params$start_date,
          end_date    = app_params$end_date,
          population  = app_params$population,
          trigger_sim = app_params$trigger_sim
        )
      })
    )

    # --------------------------------------------------------
    # Model Module: run SEIR simulation
    # --------------------------------------------------------
    seir_model_output <- model_seir_server(
      "seir_model",
      input_params = reactive({
        list(
          r0_value          = app_params$r0_value,
          incubation_period = app_params$incubation_period,
          infectious_period = app_params$infectious_period,
          ifr_value         = app_params$ifr_value,

          icu_capacity             = app_params$icu_capacity,
          ventilator_availability  = app_params$ventilator_availability,
          healthcare_staff         = app_params$healthcare_staff,

          icu_admission_rate    = app_params$icu_admission_rate,
          ventilator_usage_rate = app_params$ventilator_usage_rate,

          policy_type      = app_params$policy_type,
          compliance_level = app_params$compliance_level,

          start_date  = app_params$start_date,
          end_date    = app_params$end_date,
          population  = app_params$population,

          trigger_sim = app_params$trigger_sim
        )
      }),
      raw_data_df = simulated_raw_data
    )

    # --------------------------------------------------------
    # Visualisation Module: NOT called here.
    # viz_plot_server() must be called from the top-level server
    # function in app.R, NOT from inside this moduleServer() block.
    # If called here, the namespace would accumulate as
    # "viz_advanced-viz_advanced-seir_plot", which does not match
    # the plotOutput ids generated by ui_main(). See app.R for
    # the correct wiring.
    # --------------------------------------------------------
    # Render data preview table (top 10 rows)
    # --------------------------------------------------------
    output$simulated_data_table <- renderTable({
      req(seir_model_output())

      data_for_table <- seir_model_output()
      data_for_table$date <- format(data_for_table$date, "%d-%m-%Y")

      data_for_table <- data_for_table %>%
        dplyr::select(
          Date                  = date,
          Susceptible           = S,
          Exposed               = E,
          Infected              = I,
          Recovered             = R,
          `Cumulative Cases`    = Cumulative_Cases,
          `Cumulative Deaths`   = Cumulative_Deaths,
          `ICU Occupancy (Sim)` = ICU_Occupancy_Sim,
          `Ventilator Use (Sim)`= Vent_Usage_Sim
        ) %>%
        dplyr::mutate(
          dplyr::across(
            where(is.numeric),
            ~format(round(., 0), big.mark = ",")
          )
        )

      head(data_for_table, 10)
    }, striped = TRUE, hover = TRUE, bordered = TRUE)

    # --------------------------------------------------------
    # Download handler: exports full simulation results as CSV
    # Uses write.csv2() (semicolon separator, comma decimal)
    # for compatibility with European locale settings.
    # Numbers are exported raw (no formatting) so each user's
    # spreadsheet application applies its own locale correctly.
    # Filename includes dataset source and date for easy
    # scenario comparison.
    # --------------------------------------------------------
    output$download_csv <- downloadHandler(
      filename = function() {
        paste0(
          "SEIR_scenario_",
          dataset_selector(),
          "_",
          format(Sys.Date(), "%Y%m%d"),
          ".csv"
        )
      },
      content = function(file) {
        req(seir_model_output())

        export_df <- seir_model_output() %>%
          dplyr::mutate(date = format(date, "%d-%m-%Y")) %>%
          dplyr::select(
            Date                 = date,
            Susceptible          = S,
            Exposed              = E,
            Infected             = I,
            Recovered            = R,
            Daily_New_Infections,
            Cumulative_Cases,
            Daily_Deaths,
            Cumulative_Deaths,
            ICU_Occupancy_Sim,
            Vent_Usage_Sim
          ) %>%
          dplyr::mutate(
            dplyr::across(where(is.numeric), ~round(., 0))
          )

        # write.csv2: semicolon separator, comma decimal point
        # Standard for European locale — avoids Excel misreading
        # numeric columns when opened with regional settings.
        write.csv2(export_df, file, row.names = FALSE)

        log_message("INFO", paste("CSV exported:", basename(file)),
                    .module = "SERVER")
      }
    )

    # --------------------------------------------------------
    # Return outputs for downstream integration
    # --------------------------------------------------------
    return(list(
      model_data              = seir_model_output,
      icu_capacity            = reactive(app_params$icu_capacity),
      ventilator_availability = reactive(app_params$ventilator_availability)
    ))
  })
}
