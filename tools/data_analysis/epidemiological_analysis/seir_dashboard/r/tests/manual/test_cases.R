# Test cases (evaluated by run_tests.R inside the shared environment).
csv_file <- function(overrides = list()) {
  d <- c(r0 = 3, incubation_period = 4, infectious_period = 6, ifr = 0.02,
         icu_capacity = 1234, ventilator_availability = 321,
         healthcare_staff = 555, icu_admission_rate = 0.1,
         ventilator_usage_rate = 0.03, population = 2000000)
  for (n in names(overrides)) d[[n]] <- overrides[[n]]
  f <- tempfile(fileext = ".csv")
  write.csv(data.frame(parameter = names(d), value = unname(d)), f, row.names = FALSE)
  f
}

test_that("IFR is normalised exactly once", {
  expect_equal(normalise_ifr_to_pct(0.01), 1)
  expect_equal(normalise_ifr_to_pct(2.5), 2.5)
  expect_error(normalise_ifr_to_pct(150))
  expect_error(normalise_ifr_to_pct(NA_real_))
  dp <- get_data("csv", list(path = csv_file()))
  v <- resolve_calibrated_params(list(parametros = dp$parametros,
                                      recursos = dp$recursos, poblacion = dp$poblacion))
  expect_equal(v$ifr_value, 2)             # 0.02 -> 2 %, not 200 %
  expect_equal(v$icu_admission_rate, 10)
  expect_equal(v$ventilator_usage_rate, 3)
  expect_equal(v$population, 2000000)
  d0 <- resolve_calibrated_params(list(parametros = NULL, recursos = NULL, poblacion = POPULATION_ARGENTINA))
  expect_equal(d0$ifr_value, 1); expect_equal(d0$r0_value, 2.5)
})

test_that("CSV ranges are enforced", {
  expect_error(get_data("csv", list(path = csv_file(list(ifr = 1)))), "accepted range")
  expect_error(get_data("csv", list(path = csv_file(list(population = 5000)))), "population")
  expect_error(get_data("csv", list(path = csv_file(list(r0 = 9)))), "r0")
  expect_silent(invisible(get_data("csv", list(path = csv_file()))))
  expect_equal(format_csv_range("r0"), "0.5 – 5")
})

test_that("validate_simulation_inputs handles empty / invalid input", {
  ok <- validate_simulation_inputs(1e6, as.Date("2026-01-01"), as.Date("2026-06-01"))
  expect_length(ok, 0)
  expect_gt(length(validate_simulation_inputs(NA, as.Date("2026-01-01"), as.Date("2026-06-01"))), 0)
  expect_gt(length(validate_simulation_inputs(NULL, NULL, NULL)), 0)
  expect_gt(length(validate_simulation_inputs(1e6, as.Date("2026-06-01"), as.Date("2026-01-01"))), 0)
  expect_gt(length(validate_simulation_inputs(5000, as.Date("2026-01-01"), as.Date("2026-06-01"))), 0)
  expect_gt(length(validate_simulation_inputs(1e6, as.Date("2026-01-01"), as.Date("2026-01-05"), min_days = 14L)), 0)
  expect_error(validate_initial_state(NA, 0, 1, 0, 1), "Initial states")
})

test_that("alarm state is 'unknown' for missing values, never 'controlled'", {
  expect_equal(resolve_alarm_state(NA_real_, 1, 2), "unknown")
  expect_equal(resolve_alarm_state(NULL, 1, 2), "unknown")
  expect_equal(resolve_alarm_state(Inf, 1, 2), "unknown")
  expect_equal(resolve_alarm_state(0.5, 1, 2), "controlled")
  expect_equal(resolve_alarm_state(1.5, 1, 2), "warning")
  expect_equal(resolve_alarm_state(3, 1, 2), "critical")
  html <- as.character(threshold_feedback_ui("warning", 70, 100))
  expect_match(html, "Warning threshold exceeded")
})

test_that("Advanced server: CSV parameters are applied and IFR is not rescaled twice", {
  dp <- reactiveVal(NULL)
  shiny::testServer(mod_server, args = list(dataset_selector = reactive("csv"),
                                            dataset_params = dp), {
    g <- get_data("csv", list(path = csv_file()))
    dp(list(parametros = g$parametros, recursos = g$recursos, poblacion = g$poblacion))
    session$flushReact()
    out <- seir_model_output()
    expect_false(is.null(out))
    expect_equal(app_params$ifr_value, 2)
    expect_equal(app_params$population, 2000000)
    expect_equal(app_params$icu_capacity, 1234)
    ratio <- tail(out$Cumulative_Deaths, 1) / tail(out$Cumulative_Cases, 1)
    expect_equal(ratio, 0.02, tolerance = 1e-6)

    # empty population / bad dates must not crash and must keep results
    before <- seir_model_output()
    session$setInputs(population = NA)
    session$flushReact()
    expect_equal(app_params$population, 2000000)
    session$setInputs(population = 1000000, start_date = as.Date("2026-06-01"),
                      end_date = as.Date("2026-01-01"))
    session$flushReact()
    expect_equal(app_params$population, 2000000)       # rejected as a set
    expect_equal(nrow(seir_model_output()), nrow(before))
    session$setInputs(start_date = as.Date("2026-01-01"), end_date = as.Date("2026-03-01"))
    session$flushReact()
    expect_equal(app_params$population, 1000000)       # accepted
    expect_equal(as.Date(app_params$end_date), as.Date("2026-03-01"))
    session$setInputs(ifr_value = 250); session$flushReact()
    expect_equal(app_params$ifr_value, 2)              # rejected, no crash

    # mock dataset restores the defaults
    dp(list(parametros = NULL, recursos = NULL, poblacion = POPULATION_ARGENTINA))
    session$flushReact()
    expect_equal(app_params$ifr_value, 1)
    expect_equal(app_params$r0_value, 2.5)
  })
})

test_that("Policy modes: only no_intervention vs static mitigation", {
  dp <- reactiveVal(list(parametros = NULL, recursos = NULL, poblacion = 1e6))
  shiny::testServer(mod_server, args = list(dataset_selector = reactive("mock"),
                                            dataset_params = dp), {
    session$flushReact()
    a <- seir_model_output()
    session$setInputs(policy_type = "static_mitigation", compliance_level = 100)
    session$flushReact()
    b <- seir_model_output()
    expect_lt(max(b$I), max(a$I))
    expect_match(as.character(output$policy_description$html), "constant reduction")
  })
})

test_that("Simple server: CSV applied, dates validated, unknown handled", {
  dp <- reactiveVal(NULL)
  shiny::testServer(mod_server_simple, args = list(dataset_selector = reactive("csv"),
                                                   dataset_params = dp), {
    g <- get_data("csv", list(path = csv_file()))
    dp(list(parametros = g$parametros, recursos = g$recursos, poblacion = g$poblacion))
    session$setInputs(simple_r0 = 3, simple_compliance = 50)
    session$flushReact()
    expect_equal(simple_params$ifr_value, 2)
    expect_equal(simple_params$policy_type, "static_mitigation")
    out <- simple_model_output()
    expect_false(is.null(out))
    expect_true(is.finite(kpi_deaths()$value))

    # bad period: <14 days -> rejected, results kept
    n0 <- nrow(simple_model_output())
    session$setInputs(simple_start_date = as.Date("2026-01-01"),
                      simple_end_date = as.Date("2026-01-05"))
    session$flushReact()
    expect_equal(nrow(simple_model_output()), n0)
    # empty date -> no crash
    session$setInputs(simple_start_date = NA, simple_end_date = as.Date("2026-03-01"))
    session$flushReact()
    expect_equal(nrow(simple_model_output()), n0)
    # valid
    session$setInputs(simple_start_date = as.Date("2026-01-01"),
                      simple_end_date = as.Date("2026-03-01"))
    session$flushReact()
    expect_equal(simple_params$end_date, as.Date("2026-03-01"))

    # zero capacity -> N/A with reason, state unknown
    simple_params$icu_capacity <- 0
    session$flushReact()
    expect_true(is.na(kpi_icu()$value))
    expect_match(kpi_icu()$reason, "capacity")
    expect_equal(alarm_icu(), "unknown")
    expect_match(as.character(output$value_icu$html), "N/A")
    expect_match(as.character(output$feedback_icu$html), "cannot be applied")
  })
})

test_that("Model server survives invalid parameters without raising", {
  p <- reactiveVal(list(r0_value = 2.5, incubation_period = 5, infectious_period = 7,
                        ifr_value = 1, icu_admission_rate = 13.6, ventilator_usage_rate = 2,
                        policy_type = "no_intervention", compliance_level = 50,
                        start_date = as.Date("2026-01-01"), end_date = as.Date("2026-03-01"),
                        population = NA_real_, trigger_sim = 1L))
  raw <- reactive(data.frame(time = 0:60, S = c(NA, rep(0, 60)), E = 0, I = 10000, R = 0))
  shiny::testServer(model_seir_server, args = list(input_params = p, raw_data_df = raw), {
    session$flushReact()
    expect_null(session$returned())
  })
})

test_that("UI builders render", {
  expect_s3_class(mod_ui_simple("x"), "shiny.tag.list")
  html <- as.character(mod_entry_ui("e"))
  expect_match(html, "shinyjs-disabled")   # view buttons start disabled
  expect_match(as.character(csv_param_table_ui()), "0.5 – 5")
  expect_false(grepl("phased_mitigation|intermittent|icu_triggered",
                     as.character(ui_policy_params(NS("a")))))
})

test_that("ICU and ventilator demand are driven by new infections, each person counted once", {
  p <- reactiveVal(list(r0_value = 2.5, incubation_period = 5, infectious_period = 7,
                        ifr_value = 1, icu_admission_rate = 13.6, ventilator_usage_rate = 2,
                        policy_type = "no_intervention", compliance_level = 50,
                        start_date = as.Date("2026-01-01"), end_date = as.Date("2026-12-31"),
                        population = 1e6, trigger_sim = 1L))
  raw <- reactive(build_dataset(population = 1e6, start_date = as.Date("2026-01-01"),
                                end_date = as.Date("2026-12-31")))
  shiny::testServer(model_seir_server, args = list(input_params = p, raw_data_df = raw), {
    session$flushReact()
    df <- session$returned()
    expect_false(is.null(df))
    expect_equal(df$ICU_Daily_Demand, df$Daily_New_Infections * 0.136)
    expect_equal(df$Vent_Daily_Demand, df$Daily_New_Infections * 0.02)
    # a person occupies a bed once: occupancy can never exceed rate x cumulative cases
    expect_true(all(df$ICU_Occupancy_Sim <= 0.136 * df$Cumulative_Cases + 1e-6))
    expect_true(all(df$Vent_Usage_Sim <= 0.02 * df$Cumulative_Cases + 1e-6))
  })
})
