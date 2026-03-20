# API-Pop – Suspected Case Reporting Tool

**Version:** `v1.3`  
**Live app:** [https://epigen.shinyapps.io/API-Pop](https://epigen.shinyapps.io/API-Pop)

## 📌 Overview

API-Pop is a rapid data filter tool built in R/Shiny to query specific information from suspected desease events reports ("rumor"). It was developed as part of the PPT-UK Project (Argentina Work Package WS5).


## 🚀 Features
- Up-to-date localization and population data
- CSV download of all filtered cases
- CSV download of cases added by week and location
- Fixed background image (PPT-CEMIC SVG)


## 📦 Installation

### Requirements

- R >= 4.2
- RStudio recommended
- R packages:
  ```r
   install.packages(c("shiny", "dplyr", "uuid", "httr", "jsonlite", "rsconnect", "leaflet", "shinyjs", "here", "arrow"))
  ```
- Downgrade Rcpp to compatible version:
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

## ▶️ Run Locally

```r
setwd("path/to/API-Pop")
shiny::runApp()
```

## ☁️ Deploy to shinyapps.io

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(name='your_name', token='your_token', secret='your_secret')
rsconnect::deployApp()
```

## 🔗 Demo

**[Click here to view the app online](https://epigen.shinyapps.io/API-Pop)**

## 📬 Contact

**Project:** PPT-UK – Argentina WP5  
**Institution - Delivery Partner:** CEMIC
