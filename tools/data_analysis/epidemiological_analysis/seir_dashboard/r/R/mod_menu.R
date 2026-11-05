# ============================================================
# File: mod_menu.R
# ------------------------------------------------------------
# Description: Top navigation menu module. Renders an Analysis for
#   Action–branded dark green navbar that persists across all non-entry views.
#   Provides:
#     - Brand name (and logo, when www/img/afa-logo-white.png exists).
#     - Active dataset indicator (italic, muted).
#     - Three view buttons: Home, Simple, Advanced.
#   Simple and Advanced buttons use uiOutput so the server can
#   apply the correct active-state border colour depending on
#   the current screen.
# Author: Cristian Paez
# Created: 2025-11-07
# Updated: 2026-03-19 — Simple View button enabled;
#   dynamic active-state highlight added for both view buttons.
# Updated: 2026-10 — Testing recommendation (round 1):
#   Same navbar as the entry screen (class "afa-navbar" in
#   custom.css: darker green, logo hook, larger title). The
#   active view is marked with the AfA orange and aria-current.
#   No text smaller than 0.875rem.
# ============================================================


# ------------------------------------------------------------
# Function: nav_button_ui()
# Description:
#   One navigation button. The active one gets the orange
#   accent (class "afa-nav-btn--active", styles in custom.css).
# ------------------------------------------------------------
nav_button_ui <- function(input_id, label, active = FALSE) {
  actionButton(
    input_id, label,
    class = paste("afa-nav-btn", if (active) "afa-nav-btn--active"),
    `aria-current` = if (active) "page" else NULL
  )
}


# ------------------------------------------------------------
# Function: mod_menu_ui()
# Description:
#   Renders the top navigation bar as an Analysis for Action dark green navbar.
#   Injected above main content by app.R when screen() != "entry".
# Parameters:
#   id – Shiny module identifier.
# Returns:
#   A tagList() containing the <nav> element.
# ------------------------------------------------------------
mod_menu_ui <- function(id) {
  ns <- NS(id)

  tagList(
    tags$nav(
      class = "afa-navbar",

      # Left: logo + brand name
      tags$span(
        class = "afa-navbar-brand",
        afa_logo_ui(),
        tags$span(class = "afa-navbar-title", "SEIR Dashboard")
      ),

      # Centre: active dataset indicator
      tags$span(
        class = "afa-navbar-meta",
        textOutput(ns("active_dataset"), inline = TRUE)
      ),

      # Right: navigation buttons
      tags$div(
        class = "afa-navbar-actions",

        # Home — static, no active-state needed
        actionButton(ns("btn_home"), "Home", class = "afa-nav-btn"),

        # Simple — dynamic active-state via uiOutput
        uiOutput(ns("btn_simple_ui"), inline = TRUE),

        # Advanced — dynamic active-state via uiOutput
        uiOutput(ns("btn_advanced_ui"), inline = TRUE)
      )
    )
  )
}


# ------------------------------------------------------------
# Function: mod_menu_server()
# Description:
#   Server logic for the navigation menu. Renders the active
#   dataset label, applies the correct active-state highlight
#   to the current view button, and wires navigation.
# Parameters:
#   id               – Shiny module identifier.
#   screen           – reactiveVal(character); active view.
#   dataset_selector – reactiveVal(character); active source key.
# Returns:
#   None (side effects only).
# ------------------------------------------------------------
mod_menu_server <- function(id, screen, dataset_selector) {
  moduleServer(id, function(input, output, session) {

    # --- Reactive block: render active dataset label ---
    output$active_dataset <- renderText({
      ds <- dataset_selector()
      if (is.null(ds)) return("No dataset loaded")

      # Human-readable label for each source key.
      # toupper() is not used — "CSV" is not meaningful to
      # a decision-maker; the full label is more informative.
      label <- switch(ds,
        "mock" = "Simulated (mock)",
        "csv"  = "Custom dataset",
        toupper(ds)   # fallback for any future source keys
      )
      paste("Dataset:", label)
    })
    # --- End of reactive block ---

    # --------------------------------------------------------
    # Dynamic Simple / Advanced buttons
    # Orange accent when active, muted otherwise.
    # --------------------------------------------------------
    output$btn_simple_ui <- renderUI({
      nav_button_ui(session$ns("btn_simple"), "Simple",
                    active = isTRUE(screen() == "simple"))
    })

    output$btn_advanced_ui <- renderUI({
      nav_button_ui(session$ns("btn_advanced"), "Advanced",
                    active = isTRUE(screen() == "advanced"))
    })

    # --- Reactive block: Home button ---
    observeEvent(input$btn_home, {
      screen("entry")
    })
    # --- End of reactive block ---

    # --- Reactive block: Simple button ---
    observeEvent(input$btn_simple, {
      screen("simple")
      log_message("INFO", "User navigated to Simple View via menu",
                  .module = "MENU")
    })
    # --- End of reactive block ---

    # --- Reactive block: Advanced button ---
    observeEvent(input$btn_advanced, {
      screen("advanced")
    })
    # --- End of reactive block ---
  })
}
