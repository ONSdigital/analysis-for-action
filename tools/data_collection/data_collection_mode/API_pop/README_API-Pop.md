# RumorForm WP1.1 - Rapid Reporting Form for Suspected Cases

**Version:** v1.3  
**Deployment:** [https://epigen.shinyapps.io/API-Pop/](https://epigen.shinyapps.io/API-Pop/)

## Description

This Shiny application is part of the Argentina Work Package WS5 (WP1.1) within the PPT-UK project. The primary objective of this product is to offer users an accessible platform with up-to-date population size estimates for at-risk or susceptible groups. These estimates, stratified by sex, age, and geographic location, can be used as denominators in epidemiological calculations such as incidence and prevalence rates, as well as projections of expected cases for epidemiological surveillance and analysis.

## Features
- Up-to-date localization and population data
- CSV download of all filtered cases
- CSV download of cases added by week and location
- Fixed background image (PPT-CEMIC SVG)

## Run Locally

### Requirements
- R (version >= 4.2.0)
- RStudio (recommended)
- Installed packages:
  ```r
  install.packages(c("shiny", "dplyr", "uuid", "httr", "jsonlite", "rsconnect", "leaflet", "shinyjs", "here", "arrow"))
  ```
- **Rcpp version 1.0.11** is required:
  ```r
  install.packages("remotes")
  remotes::install_version("Rcpp", version = "1.0.11")
  ```

### Folder Structure
```
API-Pop/
├── app.R
└── www/
    └── PPT_cemic_images.svg
    └── config.css
└── R/
    └── modules.R
└── data/
    └── geografic data.gpgg
```

### Run the App
```r
setwd("path/to/API-pop")
shiny::runApp()
```

## Deploy to shinyapps.io
1. Get a free account at [https://www.shinyapps.io](https://www.shinyapps.io)
2. Install and configure `rsconnect`:
   ```r
   install.packages("rsconnect")
   rsconnect::setAccountInfo(name='your_name', token='your_token', secret='your_secret')
   ```
3. Deploy:
   ```r
   rsconnect::deployApp()
   ```

## Live Demo
Access the online deployed app here:  
🌐 **[https://epigen.shinyapps.io/API-Pop/](https://epigen.shinyapps.io/API-Pop/)**

## Contact
For questions or contributions:  
**Project:** PPT-UK – Argentina Work Package WS5  
**Institution - Delivery Partner:** CEMIC
