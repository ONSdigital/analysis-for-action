# R Shiny Colour Contrast Checker (WCAG)
# This app allows users to pick two colours, adjust their lightness and alpha, and checks WCAG contrast compliance.

library(shiny)
library(colourpicker)

# Helper functions
hex_to_rgb <- function(hex) {
  hex <- gsub("#", "", hex)
  if (nchar(hex) == 3) {
    hex <- paste(rep(strsplit(hex, "")[[1]], each = 2), collapse = "")
  }
  rgb <- as.numeric(strtoi(substring(hex, c(1, 3, 5), c(2, 4, 6)), 16L))
  names(rgb) <- c("r", "g", "b")
  rgb
}

normalise_rgb <- function(rgb) {
  rgb / 255
}

gamma_correct <- function(channel) {
  if (channel <= 0.03928) {
    channel / 12.92
  } else {
    ((channel + 0.055) / 1.055) ^ 2.4
  }
}

apply_gamma_correction <- function(rgb) {
  sapply(rgb, gamma_correct)
}

relative_luminance <- function(rgb) {
  0.2126 * rgb[1] + 0.7152 * rgb[2] + 0.0722 * rgb[3]
}

contrast_ratio <- function(lum1, lum2) {
  L1 <- max(lum1, lum2)
  L2 <- min(lum1, lum2)
  if (L1 == 0 && L2 == 0) return(1.0)
  (L1 + 0.05) / (L2 + 0.05)
}

format_ratio <- function(ratio) {
  format(round(ratio, 2), nsmall = 2, trim = TRUE)
}

validate_colours <- function(colours) {
  for (colour in colours) {
    if (is.null(colour)) stop("Colour cannot be NULL")
    if (!is.character(colour) || !grepl("^#", colour) || !(nchar(colour) %in% c(4, 7))) {
      stop(paste("Invalid colour format:", colour))
    }
    hex_chars <- gsub("#", "", colour)
    if (!grepl("^[0-9A-Fa-f]+$", hex_chars)) {
      stop(paste("Invalid hex characters in colour:", colour))
    }
  }
}

blend_colours <- function(fg_rgb, bg_rgb, alpha) {
  setNames(alpha * fg_rgb + (1 - alpha) * bg_rgb, c("r", "g", "b"))
}

adjust_lightness <- function(hex_colour, lightness) {
  rgb <- hex_to_rgb(hex_colour) / 255
  hls <- grDevices::convertColor(matrix(rgb, ncol=3), from="sRGB", to="HLS")
  h <- hls[1]
  s <- hls[3]
  rgb2 <- grDevices::convertColor(matrix(c(h, lightness, s), ncol=3), from="HLS", to="sRGB")
  rgb2 <- pmax(pmin(rgb2, 1), 0) # Clamp to [0,1]
  sprintf("#%02x%02x%02x", as.integer(rgb2[1]*255), as.integer(rgb2[2]*255), as.integer(rgb2[3]*255))
}

get_lightness <- function(hex_colour) {
  rgb <- hex_to_rgb(hex_colour) / 255
  hls <- grDevices::convertColor(matrix(rgb, ncol=3), from="sRGB", to="HLS")
  hls[2] # lightness
}

# UI
ui <- fluidPage(
  titlePanel("Colour Contrast Checker (WCAG)"),
  sidebarLayout(
    sidebarPanel(
      h4("Select Colours"),
      colourInput("fg", "Foreground Colour", value = "#008000"),
      sliderInput("fg_alpha", "Foreground Alpha (opacity)", min = 0, max = 1, value = 1, step = 0.01),
      colourInput("bg", "Background Colour", value = "#FFFFFF"),
      sliderInput("bg_alpha", "Background Alpha (opacity)", min = 0, max = 1, value = 1, step = 0.01),
      actionButton("check", "Check Contrast")
    ),
    mainPanel(
      h4("Contrast Ratio Result"),
      verbatimTextOutput("ratio"),
      h4("WCAG Checks"),
      tableOutput("wcag_table"),
      h4("Colour Swatches"),
      fluidRow(
        column(6, div(style = "width:100px;height:50px;border:1px solid #888;", uiOutput("fg_swatch"))),
        column(6, div(style = "width:100px;height:50px;border:1px solid #888;", uiOutput("bg_swatch")))
      ),
      br(),
      p("Source: Analysis for Action platform")
    )
  )
)

# Server
server <- function(input, output, session) {
  observeEvent(input$check, {
    fg_rgb <- hex_to_rgb(input$fg)
    bg_rgb <- hex_to_rgb(input$bg)
    fg_alpha <- input$fg_alpha
    bg_alpha <- input$bg_alpha
    # Blend fg and bg with alpha
    blended_fg <- fg_alpha * fg_rgb + (1 - fg_alpha) * bg_rgb
    blended_bg <- bg_alpha * bg_rgb + (1 - bg_alpha) * fg_rgb
    norm_fg <- normalise_rgb(blended_fg)
    norm_bg <- normalise_rgb(blended_bg)
    gamma_fg <- apply_gamma_correction(norm_fg)
    gamma_bg <- apply_gamma_correction(norm_bg)
    lum_fg <- relative_luminance(gamma_fg)
    lum_bg <- relative_luminance(gamma_bg)
    ratio <- contrast_ratio(lum_fg, lum_bg)
    output$ratio <- renderText({ paste0("Contrast Ratio: ", format_ratio(ratio), ":1") })
    # WCAG checks
    checks <- list(
      normal_text_AA = ratio >= 4.5,
      normal_text_AAA = ratio >= 7,
      large_text_AA = ratio >= 3,
      large_text_AAA = ratio >= 4.5,
      graphical_AA = ratio >= 3
    )
    wcag_table <- data.frame(
      Check = c("Normal Text AA (≥4.5)", "Normal Text AAA (≥7)", "Large Text AA (≥3)", "Large Text AAA (≥4.5)", "Graphical AA (≥3)"),
      Result = unlist(checks),
      Status = ifelse(unlist(checks), "Pass", "Fail")
    )
    output$wcag_table <- renderTable({ wcag_table }, striped = TRUE, bordered = TRUE, hover = TRUE)
    output$fg_swatch <- renderUI({
      div(style = sprintf("width:100%%;height:100%%;background:%s;opacity:%s;", input$fg, input$fg_alpha))
    })
    output$bg_swatch <- renderUI({
      div(style = sprintf("width:100%%;height:100%%;background:%s;opacity:%s;", input$bg, input$bg_alpha))
    })
  })
}

shinyApp(ui, server)
