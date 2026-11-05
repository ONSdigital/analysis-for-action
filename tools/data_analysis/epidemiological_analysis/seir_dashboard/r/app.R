# ============================================================
# File: app.R
# ------------------------------------------------------------
# Description: Main SEIR Shiny application. Integrates Entry,
#              Menu, Simple and Advanced views with correct
#              module wiring for data, model and visualisation.
#
# NOTE: global.R and all R/ modules are loaded automatically
# by Shiny's loadSupport() mechanism (DESCRIPTION file present).
# Manual source() calls are NOT required here.
#
# Namespace contract — Advanced View plot outputs:
#   ui_main("viz_advanced") generates plotOutput ids of the
#   form "viz_advanced-seir_plot", etc.
#   viz_plot_server() must be called with id = "viz_advanced"
#   from the TOP-LEVEL server — never from inside another
#   moduleServer() call — to prevent double-prefixed ids.
#   See Implementation Guide section 6.1 for full explanation.
#
# Namespace contract — Simple View:
#   mod_ui_simple("viz_simple") / mod_server_simple("viz_simple").
#   The Simple View does NOT use viz_plot_server() — it renders
#   KPI cards via renderUI inside mod_server_simple().
#   State is fully isolated: mod_server_simple() maintains its
#   own reactiveValues, initialised from the dataset snapshot
#   (dataset_params) or from the global.R defaults.
#   Internal sub-modules use "simple_data" and "simple_seir"
#   namespace ids to avoid collision with "data_sim"/"seir_model"
#   used by the Advanced View.
#
# Simplified View implemented: 2026-03-19
# Updated: 2026-10 — Testing recommendation (round 1):
#   * mod_entry_server() is now called with NAMED arguments.
#     Previously dataset_params was passed in the position of
#     the unused `trigger_sim` argument, so it was never set
#     inside the module: parameters of an uploaded CSV were
#     never published and the Advanced / Simple views ignored
#     them.
# ============================================================

library(shiny)
library(shinyjs)

# ============================================================
# UI
# ============================================================
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$title("SEIR Dashboard — Analysis for Action"),
    tags$script("document.documentElement.lang = 'en';"),
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  uiOutput("main_ui"),
  # Funding acknowledgement (Wellcome "Funded by" guidance: bottom
  # left, linked to wellcome.org). Approved artwork, unmodified,
  # 80 px high (the minimum) (minimum on screen is 80 px).
  tags$footer(
    class = "afa-footer",
    tags$a(
      href = "https://wellcome.org", target = "_blank", rel = "noopener",
      tags$img(src = "img/wellcome-funded-by-dark.png",
               alt = "Funded by Wellcome", class = "afa-footer-logo")
    )
  )
)

# ============================================================
# Server
# ============================================================
server <- function(input, output, session) {

  # --------------------------------------------------------
  # Reactive state
  # --------------------------------------------------------
  screen           <- reactiveVal("entry")
  dataset_selector <- reactiveVal(NULL)
  dataset_loaded   <- reactiveVal(NULL)

  # Stores calibrated parameters from the loaded dataset.
  # For mock: list with NULL $parametros (global defaults are
  # restored). For a user CSV: named list with $parametros,
  # $recursos, $poblacion. Passed to both views so both
  # initialise from the same dataset snapshot.
  dataset_params   <- reactiveVal(NULL)

  # --------------------------------------------------------
  # Dynamic UI routing
  # Menu bar shown on all views except entry.
  # --------------------------------------------------------
  output$main_ui <- renderUI({
    current <- screen()

    menu_ui <- if (current != "entry") mod_menu_ui("menu") else NULL

    main_content <- switch(
      current,
      "entry"    = mod_entry_ui("entry"),
      "simple"   = mod_ui_simple("viz_simple"),
      "advanced" = ui_main("viz_advanced"),
      div(h3("Unknown view"))
    )

    tagList(menu_ui, main_content)
  })

  # --------------------------------------------------------
  # Error notifications that stay on screen until the input is
  # fixed (invalid dates / population) belong to ONE view. Clear
  # them when the user changes view so they do not follow the
  # user to a screen where they no longer apply.
  # --------------------------------------------------------
  observeEvent(screen(), {
    for (nid in c("viz_simple-period_error", "viz_simple-simple_seir-simulation_error",
                  "viz_advanced-scope_error", "viz_advanced-ifr_error",
                  "viz_advanced-seir_model-simulation_error")) {
      removeNotification(nid)
    }
  }, ignoreInit = TRUE)

  # --------------------------------------------------------
  # Entry and menu servers — always active
  # NAMED arguments: do not rely on position (see header).
  # --------------------------------------------------------
  mod_entry_server(
    id               = "entry",
    screen           = screen,
    dataset_selector = dataset_selector,
    dataset_loaded   = dataset_loaded,
    dataset_params   = dataset_params
  )
  mod_menu_server("menu", screen, dataset_selector)

  # --------------------------------------------------------
  # Advanced view
  # --------------------------------------------------------
  # Guard flag prevents duplicate module registration when
  # the user navigates away and back to this view.
  #
  # viz_plot_server() is called at the top level so output ids
  # resolve to "viz_advanced-*", matching the plotOutput calls
  # inside ui_main("viz_advanced").
  # --------------------------------------------------------
  advanced_initialised <- reactiveVal(FALSE)

  observeEvent(screen(), {
    req(screen() == "advanced", dataset_loaded())
    if (advanced_initialised()) return()
    advanced_initialised(TRUE)

    out <- mod_server("viz_advanced",
                      reactive({ dataset_selector() }),
                      dataset_params)

    viz_plot_server(
      id                            = "viz_advanced",
      model_data                    = out$model_data,
      icu_capacity_input            = out$icu_capacity,
      ventilator_availability_input = out$ventilator_availability
    )
  })

  # --------------------------------------------------------
  # Simple view
  # --------------------------------------------------------
  # mod_server_simple() is self-contained: it calls
  # mod_data_server() and model_seir_server() internally.
  # It does NOT use viz_plot_server() — KPI cards are rendered
  # via renderUI inside the module itself.
  #
  # dataset_selector is passed through for logging only.
  # dataset_params carries calibrated parameters from the loaded
  # dataset — both views initialise from the same snapshot, then
  # evolve independently as the user adjusts their own controls.
  # --------------------------------------------------------
  simple_initialised <- reactiveVal(FALSE)

  observeEvent(screen(), {
    req(screen() == "simple", dataset_loaded())
    if (simple_initialised()) return()
    simple_initialised(TRUE)

    mod_server_simple("viz_simple",
                      reactive({ dataset_selector() }),
                      dataset_params)

    log_message("INFO", "Simple View server initialised", .module = "APP")
  })
}

# ============================================================
# Launch
# ============================================================
shinyApp(ui, server)
