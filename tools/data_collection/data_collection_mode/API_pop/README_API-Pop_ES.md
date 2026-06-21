# API-Pop - Formulario de Reporte Rápido de Casos Sospechosos

**Versión:** v1.3 
**Despliegue:** [https://epigen.shinyapps.io/API-Pop/](https://epigen.shinyapps.io/API-Pop/)

## Descripción

Esta aplicación Shiny forma parte del Work Package WS5 (WP1.1) del proyecto PPT-UK – Argentina. El objetivo principal de este producto es ofrecer al usuario una plataforma accesible con tamaños de poblaciones estimados actualizados para grupos susceptibles o en riesgo. Estos estimados, estratificados por sexo, edad, y ubicación geografica pueden ser usados como denominadores en calculos epidemiologicos tales como tasas de incidencia y prevalencia, así como proyecciones de casos esperados para vigilancia y análisis epidemiológico.



## Características
- Informacion actualizada de locación y población
- Descarga en CSV de todos los formularios filtrados
- Descarga en CSV de casos por cada semana y locación
- Imagen de fondo institucional (SVG CEMIC)

## Cómo Ejecutarla Localmente

### Requisitos
- R (>= 4.2.0)
- RStudio
- Paquetes necesarios:
  ```r
  install.packages(c("shiny", "dplyr", "uuid", "httr", "jsonlite", "rsconnect", "leaflet", "shinyjs", "here", "arrow"))
  ```
- Versión de Rcpp compatible:
  ```r
  install.packages("remotes")
  remotes::install_version("Rcpp", version = "1.0.11")
  ```

### Estructura del Proyecto
```
API-Pop/
├── app.R
└── www/
    └── Imagen_FondoPPT_CEMIC.svg
    └── config.css
└── R/
    └── modulos.R
└── data/
    └── información geografica.gpgg
```

### Ejecutar la App
```r
setwd("ruta/a/API-Pop")
shiny::runApp()
```

## Publicar en shinyapps.io
1. Crear cuenta gratuita en [https://www.shinyapps.io](https://www.shinyapps.io)
2. Configurar `rsconnect`:
   ```r
   install.packages("rsconnect")
   rsconnect::setAccountInfo(name='usuario', token='token', secret='clave')
   ```
3. Subir la app:
   ```r
   rsconnect::deployApp()
   ```

## Demo en Línea
🌐 [https://epigen.shinyapps.io/API-Pop/](https://epigen.shinyapps.io/API-Pop/)

## Contacto
**Proyecto:** PPT-UK – Argentina WS5  
**Institution - Delivery Partner:** CEMIC
