# API-POP: Administration and User Guide

## 1. App Overview
API-POP is a Shiny application developed as part of the Argentina Work Package WS5 (WP1.1) within the PPT-UK project. Its primary objective is to offer users an accessible platform with up-to-date population size estimates for at-risk or susceptible groups.

**Key Features:**
* Dynamic population size estimates stratified by sex, age, and geographic location.
* Provides essential denominators for epidemiological calculations (e.g., incidence and prevalence rates).
* Supports projections of expected cases for epidemiological surveillance and analysis.
* Easily switchable configuration profiles for development and production environments.

## 2. Administrator Setup & Credentials
This application uses a profile-based configuration system. Administrators can easily toggle between testing databases and live production databases without rewriting code.

### Environment Toggle (`.Renviron`)
The `.Renviron` file in the project's root directory determines which configuration profile the app should load. 
* **`R_CONFIG_ACTIVE`**: Set this to `"default"` for local testing or `"production"` for the live deployment.

### App Configuration (`config.yaml`)
The `config.yaml` file defines the specific file paths for each environment profile. Depending on what you set in your `.Renviron`, the app will read the corresponding block:
* **`db_name`**: The file path to the population database (e.g., `"your_database.dba"` or `"prod_database.dba"`).
* **`gpkg_name`**: The spatial data file used for the maps (e.g., `"Argentina.gpkg"`).
* **`json_config_path`**: The path to the regional mapping file (e.g., `"config.json"`).

## 3. Customization & Localization

### Modifying the UI Design (`config.css`)
The application's styling is centrally controlled by the `:root` section at the top of the `config.css` file. To change the app's branding, update the hex color codes in the `:root` variables:
* **`--nav-bg-color`**: Changes the top navigation bar.
* **`--hero-bg-color`**: Changes the background of the title area.
* **`--btn-green-bg`**: Updates the primary "Run Query" button color.
*Note: Do not modify the CSS rules below the `:root` section unless making structural changes to the layout.*

### Preparing Geographic Data (`.gpkg`)
To assist with setting up new country maps, a helper script is included to merge your raw geographic boundary files into a single Geopackage (`.gpkg`). You can find this script (`merge_layers.R`) and its full, step-by-step instruction manual in the `data_prep` folder. When run in the R console, the tool uses an interactive prompt to ask for your country name and raw file paths, automatically combining them into the exact format required by the application.

### Adding Countries & Regions (`config.json`)
The application uses `config.json` to dynamically build the location filters. To add a new country or modify existing regional levels, ensure the JSON structure follows this format:
* **`name`**: The display name of the country.
* **`file_name`**: The spatial data file (e.g., `"Argentina.gpkg"`).
* **`levels`**: An ordered list of administrative tiers (e.g., `["country", "level1", "level2", "level3"]`).
* **`mapping`**: Details how each level connects to the spatial data and database.
    * **`db_column`**: The column name in the database.
    * **`layer_name`**: The name of the layer in the spatial file.
    * **`spatial_id`**: The unique geographic identifier code (e.g., `"cpr"` or `"cde"`).
    * **`name_col`**: The column containing the display name for the UI (e.g., `"nam"`).
    * **`parent_col`**: *(For sub-levels only)* The `spatial_id` of the level directly above it, allowing dropdowns to filter correctly.

## 4. End-User Guide
Welcome to API-POP. This platform provides rapid access to stratified population estimates to assist in your epidemiological calculations.

### Step 1: Geographic Filtering
Use the sidebar panel to select your geographic area of interest. The dropdowns are hierarchical; selecting a higher-level region (like a Province) will automatically filter the available sub-regions (like Departments or Fractions) to ensure accurate selections.

### Step 2: Demographic Stratification
Apply demographic filters to narrow down your susceptible or at-risk group. You can adjust the parameters for Sex and Age to get precise denominators for your specific study group.

### Step 3: Running the Query
Once your filters are set, click the primary "Run Query" button (highlighted in green). The application will calculate and display the up-to-date population size estimates based on your parameters. 

### Step 4: Resetting Selections
If you need to start a new calculation, simply click the "Reset Selections" button to clear all current filters and return the dashboard to its default state.

### Step 5: Downloading Information
Once your query is complete, you can export the results using the two available download options:
* **Cases List:** Downloads the detailed table containing the specific descriptions of the records.
* **Weekly Summary:** Downloads the aggregated amount of cases, incorporating the relevant population data, the year, and the epidemiological week (epi week).

## Live Demo
Access the online deployed app here:  
🌐 **[https://epigen.shinyapps.io/API-Pop-Final/](https://epigen.shinyapps.io/API-Pop-Final/)**