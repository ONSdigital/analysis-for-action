source("global.R")

ui <- fluidPage(
  # Call the fully encapsulated main module
  analysisUI("main_module")
)

server <- function(input, output, session) {
  # Initialize the main orchestrator module
  analysisServer("main_module", con = pool, gpkg_path = gpkg_path)
}

shinyApp(ui = ui, server = server)