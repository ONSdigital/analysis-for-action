# ============================================================
# File: mod_entry.R
# ------------------------------------------------------------
# Description: Entry screen module for dataset selection and
#              navigation to the Advanced or Simple views.
#              Layout aligned with Analysis for Action brand guidelines:
#              dark green navbar, card-centred layout, Analysis for Action
#              colour palette throughout.
# Author: Cristian Paez
# Created: 2025-11-07
# Updated: 2026-03-19 — Simple View button enabled.
# Updated: 2026-10 — Testing recommendation (round 1):
#   * mod_entry_server() no longer has the unused `trigger_sim`
#     argument. It used to sit in front of `dataset_params`, so
#     the positional call in app.R silently dropped dataset_params.
#   * "Advanced view" / "Simple view" buttons are disabled until
#     a dataset has been loaded (they used to be clickable and
#     did nothing).
#   * Upload pop-up: text says the reference values are shown
#     ABOVE the file selector (they are), and the table has a
#     "Range" column generated from CSV_PARAM_RANGES, the same
#     table used to validate the file.
#   * Navbar: darker AfA green, logo hook, larger title; no text
#     smaller than 0.875rem (14 px).
# ============================================================


# ------------------------------------------------------------
# Function: csv_param_table_ui()
# Description:
#   Builds the table of required CSV parameters shown in the
#   upload pop-up. Columns: parameter, example value, accepted
#   range (from CSV_PARAM_RANGES) and description.
# Returns:
#   A tags$table() element.
# ------------------------------------------------------------
csv_param_table_ui <- function() {

  spec <- list(
    list("r0",                     "2.5",      "Basic reproduction number"),
    list("incubation_period",      "5",        "Days from exposure to infectious"),
    list("infectious_period",      "7",        "Days an individual remains infectious"),
    list("ifr",                    "0.01",     "Infection fatality rate (proportion, 0.01 = 1%)"),
    list("icu_capacity",           "6000",     "Total ICU beds available"),
    list("ventilator_availability","2000",     "Total ventilators available"),
    list("healthcare_staff",       "10000",    "Staff in critical care"),
    list("icu_admission_rate",     "0.136",    "Proportion of cases requiring ICU"),
    list("ventilator_usage_rate",  "0.02",     "Proportion requiring ventilation"),
    list("population",             "45000000", "Total population")
  )

  th <- function(txt) {
    tags$th(txt, style = "text-align:left; padding:4px 8px; background:#324027; color:#F4F6F5;")
  }

  rows <- lapply(seq_along(spec), function(i) {
    s <- spec[[i]]
    tags$tr(
      style = if (i %% 2 == 0) "background:#F4F6F5;" else NULL,
      tags$td(s[[1]], style = "padding:3px 8px;"),
      tags$td(s[[2]], style = "padding:3px 8px;"),
      tags$td(format_csv_range(s[[1]]), style = "padding:3px 8px; white-space:nowrap;"),
      tags$td(s[[3]], style = "padding:3px 8px; color:#48553F;")
    )
  })

  tags$table(
    style = "width:100%; font-size:0.875rem; border-collapse:collapse;",
    tags$thead(tags$tr(
      th("parameter"), th("example"), th("range"), th("description")
    )),
    tags$tbody(rows)
  )
}


# ------------------------------------------------------------
# Function: status_badge_ui()
# Description:
#   Success / error badge shown inside the entry card.
# Parameters:
#   id      – character; fully namespaced element id.
#   message – character; text to display.
#   ok      – logical; TRUE for success, FALSE for error.
# ------------------------------------------------------------
status_badge_ui <- function(id, message, ok = TRUE) {
  bg     <- if (ok) "#C0DD97" else "#F9EDEA"
  border <- if (ok) "#3B6D11" else "#E8B8AD"
  dot    <- if (ok) "#27500A" else "#752111"
  text   <- if (ok) "#27500A" else "#752111"

  tags$div(
    id    = id,
    role  = if (ok) "status" else "alert",
    style = paste0(
      "display:flex; align-items:center; gap:8px;",
      "padding:10px 14px;",
      "background:", bg, ";",
      "border:0.5px solid ", border, ";",
      "border-radius:6px;",
      "margin-bottom:12px;"
    ),
    tags$span(style = paste0(
      "width:8px; height:8px; border-radius:50%;",
      "background:", dot, "; flex-shrink:0; display:inline-block;"
    )),
    tags$span(
      message,
      style = paste0("font-size:0.875rem; color:", text, "; font-weight:500;")
    )
  )
}


# ------------------------------------------------------------
# Function: mod_entry_ui()
# Description:
#   Renders the full entry screen. Includes an Analysis for Action–branded
#   navbar at the top and a centred card containing the
#   dataset selector, load button, status badge, and view
#   mode buttons. The footer bar anchors the page at the
#   bottom with project attribution.
# Parameters:
#   id – Shiny module identifier.
# Returns:
#   A tagList() with navbar, body, and footer elements.
# ------------------------------------------------------------
mod_entry_ui <- function(id) {
  ns <- NS(id)

  section_label_style <- paste(
    "font-size:0.875rem;",
    "font-weight:600;",
    "color:#48553F;",
    "margin-bottom:6px;"
  )

  tagList(
    useShinyjs(),

    # --------------------------------------------------------
    # Top navbar — AfA dark green (styles in custom.css)
    # --------------------------------------------------------
    tags$nav(
      class = "afa-navbar",
      tags$span(
        class = "afa-navbar-brand",
        afa_logo_ui(),
        tags$span(class = "afa-navbar-title", "SEIR Dashboard")
      )
    ),

    # --------------------------------------------------------
    # Main body — centred card layout on AfA tint background
    # --------------------------------------------------------
    tags$div(
      style = paste(
        "min-height:calc(100vh - 100px);",
        "background-color:#F4F6F5;",
        "display:flex;",
        "flex-direction:column;",
        "align-items:center;",
        "justify-content:center;",
        "padding:40px 16px;"
      ),

      # Header text above the card
      tags$div(
        style = "text-align:center; margin-bottom:28px;",
        tags$h1(
          "Epidemiological modelling platform",
          style = paste(
            "font-size:2.4rem;",
            "font-weight:600;",
            "color:#1E2A16;",
            "margin-bottom:8px;"
          )
        ),
        tags$p(
          "Select a dataset to initialise the simulation,",
          "then choose a view mode to explore epidemic scenarios.",
          style = "font-size:1rem; color:#48553F; max-width:440px; margin:0 auto;"
        )
      ),

      # Central card
      tags$div(
        style = paste(
          "background:#ffffff;",
          "border:0.5px solid #D0D4CE;",
          "border-radius:12px;",
          "padding:28px 32px;",
          "width:100%;",
          "max-width:480px;"
        ),

        # --- Dataset selector ---
        tags$div(
          style = "margin-bottom:16px;",
          tags$div("Dataset source", style = section_label_style),
          selectInput(
            inputId  = ns("dataset_selector"),
            label    = NULL,
            choices  = c(
              "Simulated (mock)"          = "mock",
              "Upload your own dataset (CSV)" = "csv"
            ),
            selected = "mock",
            width    = "100%"
          )
        ),

        # --- Load Dataset button ---
        actionButton(
          ns("load_dataset"),
          "Load dataset",
          class = "btn btn-primary w-100",
          style = "margin-bottom:12px;"
        ),

        # --- Status message (success / error badge) ---
        uiOutput(ns("status_message")),

        tags$hr(style = "border-color:#D0D4CE; margin:16px 0;"),

        # --- View mode label ---
        tags$div("View mode", style = section_label_style),

        # --- View buttons row ---
        # Disabled until a dataset has been loaded; the server
        # enables them (see observe() on dataset_loaded()).
        tags$div(
          style = "display:flex; gap:10px;",

          shinyjs::disabled(
            actionButton(
              ns("go_advanced"),
              "Advanced view",
              class = "btn btn-primary flex-fill"
            )
          ),

          shinyjs::disabled(
            actionButton(
              ns("go_simple"),
              "Simple view",
              class = "btn btn-outline-secondary flex-fill"
            )
          )
        ),

        tags$p(
          class = "afa-help-text",
          style = "margin:10px 0 0;",
          "Load a dataset first: the view buttons are enabled once it is ready."
        )
      )
    )
  )
}


# ------------------------------------------------------------
# Function: mod_entry_server()
# Description:
#   Server logic for the entry screen. Handles dataset loading,
#   status feedback, and navigation to the Advanced or Simple
#   views. Resets state when the user returns to the entry
#   screen.
# Parameters:
#   id               – Shiny module identifier.
#   screen           – reactiveVal(character); controls active view.
#   dataset_selector – reactiveVal(character); active source key.
#   dataset_loaded   – reactiveVal(data.frame); loaded dataset.
#   dataset_params   – reactiveVal(list); calibrated parameters of
#                      the loaded dataset. Pass it BY NAME.
# Returns:
#   None (side effects only).
# ------------------------------------------------------------
mod_entry_server <- function(id, screen, dataset_selector,
                             dataset_loaded,
                             dataset_params = NULL) {
  moduleServer(id, function(input, output, session) {
    ns         <- session$ns
    first_load <- reactiveVal(TRUE)

    # --------------------------------------------------------
    # Enable the view buttons only while a dataset is loaded
    # --------------------------------------------------------
    observe({
      has_data <- !is.null(dataset_loaded())
      shinyjs::toggleState("go_advanced", condition = has_data)
      shinyjs::toggleState("go_simple",   condition = has_data)
    })

    # --------------------------------------------------------
    # Reset UI when returning to entry screen
    # --------------------------------------------------------
    observeEvent(screen(), {
      if (screen() == "entry") {
        output$status_message <- renderUI(NULL)
        if (!first_load()) {
          dataset_selector(NULL)
          dataset_loaded(NULL)
        }
        first_load(FALSE)
      }
    })

    # --------------------------------------------------------
    # Load dataset — shows status badge inside the card.
    # For CSV source: opens a modal with upload instructions
    # and a fileInput. For mock: loads directly.
    # --------------------------------------------------------
    observeEvent(input$load_dataset, {

      # CSV source — show upload modal before loading
      if (isTRUE(input$dataset_selector == "csv")) {
        showModal(modalDialog(
          title     = "Upload your own dataset",
          size      = "m",
          easyClose = FALSE,

          tags$p(
            style = "color:#48553F; margin-bottom:16px;",
            "Upload a CSV file with your epidemiological and ",
            "healthcare resource parameters. The platform will ",
            "use these values as the starting point for the simulation ",
            "— your own regional ‘photo’."
          ),

          tags$div(
            style = paste(
              "background:#F8F5F1;",
              "border:0.5px solid #D0D4CE;",
              "border-radius:8px;",
              "padding:14px 16px;",
              "margin-bottom:16px;"
            ),
            tags$p(
              tags$strong("Required format:"),
              " two columns — ",
              tags$code("parameter"),
              " and ",
              tags$code("value"),
              " — with the following rows. Values outside the ",
              "range are rejected.",
              style = "margin-bottom:10px; font-size:0.875rem;"
            ),
            csv_param_table_ui()
          ),

          tags$p(
            style = "font-size:0.875rem; color:#48553F; margin-bottom:12px;",
            "Argentina reference defaults are shown above as a guide — ",
            "replace them with your own regional figures."
          ),

          fileInput(
            ns("csv_upload"),
            label    = "Select CSV file",
            accept   = ".csv",
            multiple = FALSE
          ),

          footer = tagList(
            modalButton("Cancel"),
            actionButton(
              ns("confirm_csv_upload"),
              "Load dataset",
              class = "btn btn-primary"
            )
          )
        ))
        return()
      }

      # mock — load directly
      shinyjs::disable("load_dataset")
      shinyjs::runjs("document.body.style.opacity = 0.6;")

      dataset_selector(input$dataset_selector)

      tryCatch({
        result <- get_data(input$dataset_selector)
        req(result$data)
        dataset_loaded(result$data)

        if (!is.null(dataset_params)) {
          dataset_params(list(
            parametros = result$parametros,
            recursos   = result$recursos,
            poblacion  = result$poblacion
          ))
        }

        # Success badge
        output$status_message <- renderUI({
          status_badge_ui(ns("alert_box"), "Dataset loaded successfully.", ok = TRUE)
        })

        shinyjs::delay(3000,
                       shinyjs::hide(id       = ns("alert_box"),
                                     anim     = TRUE,
                                     animType = "fade"))

      }, error = function(e) {
        output$status_message <- renderUI({
          status_badge_ui(ns("alert_box"),
                          paste("Error loading dataset:", conditionMessage(e)),
                          ok = FALSE)
        })
        shinyjs::delay(4000,
                       shinyjs::hide(id       = ns("alert_box"),
                                     anim     = TRUE,
                                     animType = "fade"))
      })

      shinyjs::runjs("document.body.style.opacity = 1;")
      shinyjs::enable("load_dataset")
    })

    # --------------------------------------------------------
    # CSV upload confirmation — fired when user clicks
    # "Load dataset" inside the modal.
    # Validates the uploaded file via validate_user_csv(),
    # builds the dataset, updates reactive state, and closes
    # the modal. Shows a success or error badge on completion.
    # --------------------------------------------------------
    observeEvent(input$confirm_csv_upload, {
      req(input$csv_upload)

      shinyjs::disable("confirm_csv_upload")

      tryCatch({
        result <- get_data(
          source = "csv",
          params = list(path = input$csv_upload$datapath)
        )
        req(result$data)

        dataset_selector("csv")
        dataset_loaded(result$data)

        if (!is.null(dataset_params)) {
          dataset_params(list(
            parametros = result$parametros,
            recursos   = result$recursos,
            poblacion  = result$poblacion
          ))
        }

        removeModal()

        output$status_message <- renderUI({
          status_badge_ui(ns("alert_box"),
                          "Custom dataset loaded successfully.", ok = TRUE)
        })

        shinyjs::delay(3000,
                       shinyjs::hide(id       = ns("alert_box"),
                                     anim     = TRUE,
                                     animType = "fade"))

        log_message("INFO", "User CSV loaded successfully", .module = "ENTRY")

      }, error = function(e) {
        removeModal()
        output$status_message <- renderUI({
          status_badge_ui(ns("alert_box"),
                          paste("Error loading CSV:", conditionMessage(e)),
                          ok = FALSE)
        })
        # Longer on screen: the message lists the offending values
        shinyjs::delay(12000,
                       shinyjs::hide(id       = ns("alert_box"),
                                     anim     = TRUE,
                                     animType = "fade"))
        log_message("ERROR", paste("CSV upload failed:", conditionMessage(e)),
                    .module = "ENTRY")
      })

      shinyjs::enable("confirm_csv_upload")
    })

    # --------------------------------------------------------
    # Navigation to Advanced view
    # --------------------------------------------------------
    observeEvent(input$go_advanced, {
      req(dataset_loaded())
      screen("advanced")
      log_message("INFO", "User navigated to Advanced View",
                  .module = "ENTRY")
    })

    # --------------------------------------------------------
    # Navigation to Simple view
    # --------------------------------------------------------
    observeEvent(input$go_simple, {
      req(dataset_loaded())
      screen("simple")
      log_message("INFO", "User navigated to Simple View",
                  .module = "ENTRY")
    })
  })
}
