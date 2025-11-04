# R Shiny Colour Contrast Checker (WCAG)
# This app allows users to pick two colours, adjust their lightness and alpha, and checks WCAG contrast compliance.

library(shiny)
library(colourpicker)

# ---- Helper Functions ----------------------------------------------------
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
    ((channel + 0.055) / 1.055)^2.4
  }
}

apply_gamma_correction <- function(rgb) {
  sapply(rgb, gamma_correct)
}

relative_luminance <- function(rgb) {
  0.2126 * rgb[1] + 0.7152 * rgb[2] + 0.0722 * rgb[3]
}

contrast_ratio <- function(l1, l2) {
  L1 <- max(l1, l2)
  L2 <- min(l1, l2)
  if (L1 == 0 && L2 == 0) {
    return(1.0)
  }
  (L1 + 0.05) / (L2 + 0.05)
}

format_ratio <- function(r) {
  format(round(r, 2), nsmall = 2, trim = TRUE)
}

validate_colours <- function(cols) {
  for (colour in cols) {
    if (is.null(colour)) {
      stop("Colour cannot be NULL")
    }
    if (!is.character(colour) || !grepl("^#", colour) || !(nchar(colour) %in% c(4, 7))) {
      stop(paste("Invalid colour format:", colour))
    }
    hex_chars <- gsub("#", "", colour)
    if (!grepl("^[0-9A-Fa-f]+$", hex_chars)) {
      stop(paste("Invalid hex characters:", colour))
    }
  }
}

blend_colours <- function(fg_rgb, bg_rgb, alpha) {
  setNames(alpha * fg_rgb + (1 - alpha) * bg_rgb, c("r", "g", "b"))
}

adjust_lightness <- function(hex_colour, lightness) {
  rgb <- hex_to_rgb(hex_colour) / 255
  hls <- grDevices::convertColor(matrix(rgb, ncol = 3), from = "sRGB", to = "HLS")
  h <- hls[1]
  s <- hls[3]
  rgb2 <- grDevices::convertColor(matrix(c(h, lightness, s), ncol = 3), from = "HLS", to = "sRGB")
  rgb2 <- pmax(pmin(rgb2, 1), 0) # clamp
  sprintf("#%02x%02x%02x", as.integer(rgb2[1] * 255), as.integer(rgb2[2] * 255), as.integer(rgb2[3] * 255))
}

get_lightness <- function(hex_colour) {
  rgb <- hex_to_rgb(hex_colour) / 255
  hls <- grDevices::convertColor(matrix(rgb, ncol = 3), from = "sRGB", to = "HLS")
  hls[2]
}

# ---- UI ------------------------------------------------------------------
ui <- fluidPage(
  tags$head(
    tags$script(HTML(
      "function getPageHeight() {
        const body = document.body;
        const html = document.documentElement;

        return Math.max(body.scrollHeight, body.offsetHeight);
      }

      function sendHeightMessage() {
          const height = getPageHeight();
          console.log(`Height of ${height} has been sent to parent.`);
          window.parent.postMessage({
              type: 'iframeHeight',
              height,
          });
      }

      window.addEventListener('load', () => {
          sendHeightMessage();

          if (document.body) {
              const observer = new ResizeObserver(() => sendHeightMessage());
              observer.observe(document.body);
          } else {
              console.error('document.body is not available for ResizeObserver.');
          }
      });

      window.addEventListener('message', (event) => {
          if (event.data?.type === 'getHeight') {
              sendHeightMessage();
          }
      });"
    ))
  ),
  titlePanel("Colour Contrast Checker (WCAG)"),
  sidebarLayout(
    sidebarPanel(
      h4(tags$b("Select Colours")),
      fluidRow(
        column(6, colourInput("fg", "Foreground Colour", value = "#006000")),
        column(6, colourInput("bg", "Background Colour", value = "#FFFFFF"))
      ),
      actionButton("check", "Check Contrast", class = "btn-primary")
    ),
    mainPanel(
      h4(tags$b("Contrast Ratio Result")),
      uiOutput("ratio"),
      uiOutput("wcag_table"),
      br(),
      p("Source: Analysis for Action platform")
    )
  )
)

# ---- Server --------------------------------------------------------------
server <- function(input, output, session) {
  observeEvent(input$check, {
    validate_colours(c(input$fg, input$bg))

    fg_rgb <- hex_to_rgb(input$fg)
    bg_rgb <- hex_to_rgb(input$bg)

    norm_fg <- normalise_rgb(fg_rgb)
    norm_bg <- normalise_rgb(bg_rgb)
    gamma_fg <- apply_gamma_correction(norm_fg)
    gamma_bg <- apply_gamma_correction(norm_bg)

    lum_fg <- relative_luminance(gamma_fg)
    lum_bg <- relative_luminance(gamma_bg)
    ratio <- contrast_ratio(lum_fg, lum_bg)

    output$ratio <- renderUI({
      ratio_text <- paste0("Contrast Ratio: ", format_ratio(ratio), ":1")
      div(
        style = "font-size:1.3em;font-weight:600;padding:8px 16px;background:#f5f5f5;border:2px solid #228B22;border-radius:8px;color:#222;margin-bottom:10px;display:inline-block;",
        ratio_text
      )
    })

    checks <- list(
      normal_text_AA = ratio >= 4.5,
      normal_text_AAA = ratio >= 7,
      large_text_AA = ratio >= 3,
      large_text_AAA = ratio >= 4.5,
      graphical_AA = ratio >= 3
    )

    output$wcag_table <- renderUI({
      tagList(
        h4(tags$b("WCAG Checks")),
        div(
          h5(tags$b("Normal Text")),
          p(
            "Normal Text AA: Contrast ratio \u2265 4.5:1 for normal text (WCAG AA)",
            span(
              ifelse(checks$normal_text_AA, "Pass", "Fail"),
              style = ifelse(
                checks$normal_text_AA,
                "color:#006000;font-weight:bold;",
                "color:#8C0000;font-weight:bold;"
              )
            )
          ),
          p(
            "Normal Text AAA: Contrast ratio \u2265 7:1 for normal text (WCAG AAA)",
            span(
              ifelse(checks$normal_text_AAA, "Pass", "Fail"),
              style = ifelse(
                checks$normal_text_AAA,
                "color:#006000;font-weight:bold;",
                "color:#8C0000;font-weight:bold;"
              )
            )
          ),
          uiOutput("sample_text_normal")
        ),
        div(
          h5(tags$b("Large Text")),
          p(
            "Large Text AA: Contrast ratio \u2265 3:1 for large text (WCAG AA)",
            span(
              ifelse(checks$large_text_AA, "Pass", "Fail"),
              style = ifelse(
                checks$large_text_AA,
                "color:#006000;font-weight:bold;",
                "color:#8C0000;font-weight:bold;"
              )
            )
          ),
          p(
            "Large Text AAA: Contrast ratio \u2265 4.5:1 for large text (WCAG AAA)",
            span(
              ifelse(checks$large_text_AAA, "Pass", "Fail"),
              style = ifelse(
                checks$large_text_AAA,
                "color:#006000;font-weight:bold;",
                "color:#8C0000;font-weight:bold;"
              )
            )
          ),
          uiOutput("sample_text_large")
        ),
        div(
          h5(tags$b("Graphical / UI Components")),
          p(
            "Graphical AA: Contrast ratio \u2265 3:1 for graphics and UI components (WCAG AA)",
            span(
              ifelse(checks$graphical_AA, "Pass", "Fail"),
              style = ifelse(
                checks$graphical_AA,
                "color:#006000;font-weight:bold;",
                "color:#8C0000;font-weight:bold;"
              )
            )
          ),
          uiOutput("sample_text_ui")
        )
      )
    })

    output$sample_text_normal <- renderUI({
      div(
        style = sprintf(
          "padding:6px 10px;background:%s;color:%s;border:1px solid #ccc;border-radius:4px;margin-bottom:6px;",
          input$bg, input$fg
        ),
        "Sample Text (Normal)"
      )
    })

    output$sample_text_large <- renderUI({
      div(
        style = sprintf(
          "padding:6px 10px;font-size:1.4em;background:%s;color:%s;border:1px solid #ccc;border-radius:4px;margin-bottom:6px;",
          input$bg, input$fg
        ),
        "Sample Text (Large)"
      )
    })

    output$sample_text_ui <- renderUI({
      div(
        style = sprintf(
          "display:inline-block;padding:8px 18px;background:%s;color:%s;border:1px solid #ccc;border-radius:24px;font-weight:600;box-shadow:0 2px 6px rgba(0,0,0,0.08);",
          input$bg, input$fg
        ),
        "Sample UI Component"
      )
    })
  })
}

# ---- App -----------------------------------------------------------------
shinyApp(ui, server)
