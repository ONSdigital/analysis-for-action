# Office for National Statistics (ONS)
# Mortality Analysis Training Package
# Unit: Key Concepts – Mortality Rates in R
# Date: August 2025

# Unit: Key Concepts – Mortality Rates in R ----

## Overview: ----
# This script is part of the ONS mortality analysis training package.
# It supports the "Key Concepts" unit and demonstrates how to calculate
# a range of mortality rates using R. These methods are used in official
# statistics and public health reporting, and align with ONS guidance.

## Purpose: ----
# To provide practical examples of calculating mortality rates using
# synthetic data.

## Rates Covered: ----
# 1. Crude Mortality Rate
# 2. Age-Specific Mortality Rate
# 3. Age-Standardised Mortality Rate (ASMR)
# 4. Infant Mortality Rate
# 5. Perinatal Mortality Rate
# 6. Years of Life Lost (YLL)
# 7. Years of Working Life Lost (YWLL)
# 8. Mean Age at Death
# 9. Crude Rate of YLL
# 10. Potential Years of Life Lost (PYLL) and Standardised PYLL (SYLL)

## Unit: Life Expectancy Methods & Modelling Expected Deaths and Excess Mortality  
# Modelling Expected Deaths and Excess Mortality   
# Life Expectancy Calculation Using Life Table Methods  

## Learning Outcomes: ----
# - Understand key mortality concepts and terminology
# - Apply standard methods to calculate mortality rates
# - Interpret and present mortality statistics responsibly


## Data Requirements: ----
# The following files are provided with this training unit:

# - synthetic_death_registration_dataset.csv
#     > Contains 153,198 synthetic death records for England and Wales,
#       including neonatal deaths

# - synthetic_death_registration_data_dictionary.xlsx
#     > Describes all variables in the synthetic death registration dataset

# - synthetic_birth_notifications_dataset.csv
#     > Contains synthetic birth notification records for England and Wales

# - synthetic_birth_notifications_dictionary.csv
#     > Describes all variables in the synthetic birth notifications dataset

# - mid_year_population_estimates.csv
#     > Contains mid-year population estimates for:
#         - England and Wales
#         - England
#         - Wales
#         - Regions

# - european_standard_population.csv
#     > Provides standard population weights for age-standardised mortality rate (ASMR) calculations

## Required Packages: ----            
# - dplyr (for data manipulation)
# - readr (for reading CSV files)
# - readxl (for reading Excel files)
# - ggplot2 (optional, for visualisation)
# - tidyr (optional, for reshaping data)

## Setup: Working Directory and Package Loading ----

# Set working directory to the root folder of the training unit
# Update this path to match your local setup
setwd("D:/Mortality Training Unit")

# Optional: install packages if not already installed
# install.packages("dplyr")
# install.packages("readr")
# install.packages("readxl")
# install.packages("ggplot2")
# install.packages("tidyr")


# Load Required Packages
library(readr)    # For reading CSV files
library(readxl)   # For reading Excel files
library(dplyr)    # For data manipulation
library(ggplot2)  # Optional: for visualisation
library(tidyr)    # Optional: for reshaping data


# Load Data Files with Checks ----
## Check and load synthetic death registration dataset ----
if (!file.exists("Data/synthetic_death_registration_dataset.csv")) {
  stop("Death registration dataset not found. Please check your file path.")
}
deaths <- read_csv("Data/synthetic_death_registration_dataset.csv")

## Check and load mid-year population estimates ----
if (!file.exists("Data/mid_year_population_estimates.csv")) {
  stop("Population estimates file not found.")
}
population_estimates <- read_csv("Data/mid_year_population_estimates.csv")

## Check and load European Standard Population weights ----
if (!file.exists("Data/european_standard_population.csv")) {
  stop("European Standard Population file not found.")
}
esp_weights <- read_csv("Data/european_standard_population.csv")

## Check and load synthetic death registration data dictionary ----
if (file.exists("Data/synthetic_death_registration_data_dictionary.xlsx")) {
  death_dictionary <- read_excel("Data/synthetic_death_registration_data_dictionary.xlsx")
} else {
  warning("Death registration data dictionary not found.")
}

## Check and load synthetic birth notifications data dictionary ----
if (file.exists("Data/synthetic_birth_notifications_dictionary.csv")) {
  birth_dictionary <- read_csv("Data/synthetic_birth_notifications_dictionary.csv")
} else {
  warning("Birth notifications data dictionary not found.")
}

## Check and load synthetic birth notifications dataset ----
if (!file.exists("Data/synthetic_birth_notifications_dataset.csv")) {
  stop("Birth notifications dataset not found. Please check your file path.")
}
births <- read_csv("Data/synthetic_birth_notifications_dataset.csv")


# Preview Data (Optional for Learners) ----
# Preview first few rows of each dataset
cat("Death Registration Dataset:\n")
head(deaths)

cat("\nMid-Year Population Estimates:\n")
head(population_estimates)

cat("\nEuropean Standard Population Weights:\n")
head(esp_weights)

# Optional: preview death registration data dictionary
if (exists("death_dictionary")) {
  cat("\nDeath Registration Data Dictionary:\n")
  head(death_dictionary)
} else {
  warning("Death registration data dictionary not loaded.")
}

# Optional: preview birth notifications data dictionary
if (exists("birth_dictionary")) {
  cat("\nBirth Notifications Data Dictionary:\n")
  head(birth_dictionary)
} else {
  warning("Birth notifications data dictionary not loaded.")
}

cat("\nBirth Notifications Dataset:\n")
head(births)

# Mortality Rates ----
# 1. Crude Mortality Rate ----

# Step 1: Count the total number of deaths
# Each row in the 'deaths' dataset represents one registered death
total_deaths <- nrow(deaths)

# Step 2: Sum the total population for England and Wales
# The 'population_estimates' dataset includes population broken down by age and sex
# We filter for rows where Areatype is "E&W" (England and Wales)
# Then we sum the 'popn' column to get the total population
total_population <- population_estimates %>%
  filter(Areatype == "E&W") %>%
  summarise(total_pop = sum(Popn, na.rm = TRUE)) %>%
  pull(total_pop)

# Step 3: Calculate the Crude Mortality Rate
# Formula: (Total Deaths / Total Population) * 100,000
# This gives the number of deaths per 100,000 population
crude_mortality_rate <- (total_deaths / total_population) * 100000

# Step 4: Display the result
# We round the result to 2 decimal places for readability
cat("Crude Mortality Rate (per 100,000 population):", round(crude_mortality_rate, 2), "\n")


## Additional: Crude Mortality Rate by Sex ----

# Step 1: Count total deaths by sex
# The 'deaths' dataset uses 'SEX' to indicate sex
# 1 male
# 2 female
deaths_by_sex <- deaths %>%
  group_by(SEX) %>%
  summarise(total_deaths = n())

# Step 2: Sum population by sex for England and Wales
# The 'population_estimates' dataset uses 'Sex' and 'Areatype'
population_by_sex <- population_estimates %>%
  filter(Areatype == "E&W") %>%
  group_by(Sex) %>%
  summarise(total_population = sum(Popn, na.rm = TRUE))

# Step 3: Join deaths and population data by sex
# We match 'SEX' from deaths with 'Sex' from population estimates
crude_rate_by_sex <- deaths_by_sex %>%
  left_join(population_by_sex, by = c("SEX" = "Sex")) %>%
  mutate(crude_rate = (total_deaths / total_population) * 100000)

# Step 4: Display results
# Round the crude rate to 2 decimal places for readability

# Step 4: Display the result using cat()
# We loop through each row and print the sex-specific crude mortality rate
crude_rate_by_sex %>%
  mutate(crude_rate = round(crude_rate, 2)) %>%
  rowwise() %>%
  mutate(
    output = paste0("Crude Mortality Rate for ", SEX, " (per 100,000 population): ", crude_rate)
  ) %>%
  pull(output) %>%
  cat(sep = "\n")

# 2. Age-Specific Mortality Rate ----

# Step 1: Count total deaths by age group
# We group the 'deaths' dataset by Agegroup2 and count the number of records in each group.
# This gives us the total number of deaths per age group.
deaths_by_age <- deaths %>%
  group_by(Agegroup2) %>%
  summarise(total_deaths = n())

# Step 2: Sum population by age group for England and Wales
# We filter the population estimates to include only England & Wales (Areatype == "E&W"),
# then group by Agegroup2 and sum the population within each group.
population_by_age <- population_estimates %>%
  filter(Areatype == "E&W") %>%
  group_by(Agegroup2) %>%
  summarise(total_population = sum(Popn, na.rm = TRUE))

# Step 3: Join deaths and population data by age group
# We perform a left join to combine the deaths and population datasets by Agegroup2.
# This ensures all age groups from the deaths data are retained, even if population data is missing.
# We then calculate the Age-Specific Mortality Rate (ASMR) per 100,000 population.
age_specific_rates <- deaths_by_age %>%
  left_join(population_by_age, by = "Agegroup2") %>%
  mutate(ASMR = (total_deaths / total_population) * 100000)

# Step 4: Display results in a readable format
# We round the ASMR to two decimal places for clarity.
# Then, for each age group, we create a formatted string describing the ASMR.
# Finally, we print each line using cat(), which outputs to the console.
age_specific_rates %>%
  mutate(ASMR = round(ASMR, 2)) %>%
  rowwise() %>%
  mutate(
    output = paste0("Age-Specific Mortality Rate for ", Agegroup2, " (per 100,000): ", ASMR)
  ) %>%
  pull(output) %>%
  cat(sep = "\n")


## Addtional: Age-Specific Mortality Rate by Region (England Only) ----


# Step 1: Filter deaths to England only and count by age group and region
# 'CTRYIR == 1' identifies records from England.
# 'RGN' is the region code, and 'Agegroup2' is the age group variable.
# We group by region and age group, then count the number of deaths in each group.
deaths_by_age_region <- deaths %>%
  filter(CTRYIR == 1) %>%
  group_by(RGN, Agegroup2) %>%
  summarise(total_deaths = n(), .groups = "drop")

# Step 2: Sum population by age group and region
# The population estimates dataset uses 'Code' for region codes and 'Agegroup2' for age groups.
# We filter to include only regional-level data (Areatype == "REG"),
# then group by region and age group and sum the population for each group.
population_by_age_region <- population_estimates %>%
  filter(Areatype == "REG") %>%
  group_by(Code, Agegroup2) %>%
  summarise(total_population = sum(Popn, na.rm = TRUE), .groups = "drop")

# Step 3: Join deaths and population data by region and age group
# We join the two datasets using region code and age group as keys.
# This aligns death counts with corresponding population estimates.
# We then calculate the Age-Specific Mortality Rate (ASMR) per 100,000 population.
age_specific_rates_region <- deaths_by_age_region %>%
  left_join(population_by_age_region, by = c("RGN" = "Code", "Agegroup2" = "Agegroup2")) %>%
  mutate(ASMR = (total_deaths / total_population) * 100000)

# Step 4: Display results in a readable format
# We round the ASMR to two decimal places for clarity.
# For each region and age group, we create a formatted output string.
# Finally, we print each line using cat(), which outputs to the console.
age_specific_rates_region %>%
  mutate(ASMR = round(ASMR, 2)) %>%
  rowwise() %>%
  mutate(
    output = paste0("Region Code: ", RGN, " | Age Group: ", Agegroup2, " | ASMR (per 100,000): ", ASMR)
  ) %>%
  pull(output) %>%
  cat(sep = "\n")


# 3. Age-Standardised Mortality Rate (ASMR) ----
# Using European Standard Population (ESP) weights
# Including confidence intervals

# Step 0: Adjust ESP weights to match Agegroup2 format
# The ESP dataset uses "85-89" and "90+", but our mortality data uses "85+"
# To ensure consistency, we combine these two ESP groups into a single "85+" group
esp_weights_adjusted <- esp_weights %>%
  mutate(Agegroup2 = ifelse(agegroup %in% c("85-89", "90+"), "85+", agegroup)) %>%
  group_by(Agegroup2) %>%
  summarise(esp = sum(esp), .groups = "drop")

# Step 1: Count total deaths by Agegroup2
# We group the deaths dataset by Agegroup2 and count the number of deaths in each group
deaths_by_age <- deaths %>%
  group_by(Agegroup2) %>%
  summarise(total_deaths = n(), .groups = "drop")

# Step 1a: Ensure all age groups are present, even if there are zero deaths
# This is essential for accurate ASMR calculation — missing age groups would distort the result
# We create a complete list of age groups from the ESP weights and join it with the deaths data
# Any missing age groups will have NA for total_deaths, which we replace with 0
all_agegroups <- esp_weights_adjusted %>%
  dplyr::select(Agegroup2) %>%
  distinct()

deaths_by_age_complete <- all_agegroups %>%
  left_join(deaths_by_age, by = "Agegroup2") %>%
  mutate(total_deaths = replace_na(total_deaths, 0))

# Step 2: Sum population by Agegroup2 for England and Wales
# We filter the population estimates to include only national-level data (Areatype == "E&W")
# Then we group by Agegroup2 and sum the population for each group
population_by_age <- population_estimates %>%
  filter(Areatype == "E&W") %>%
  group_by(Agegroup2) %>%
  summarise(total_population = sum(Popn, na.rm = TRUE), .groups = "drop")

# Step 3: Join deaths and population data to calculate age-specific mortality rates
# We calculate the mortality rate per 100,000 population for each age group
age_specific_rates <- deaths_by_age_complete %>%
  left_join(population_by_age, by = "Agegroup2") %>%
  mutate(rate = (total_deaths / total_population) * 100000)

# Step 4: Join with adjusted ESP weights
# This applies the standard population weights to each age-specific rate
# These weights allow us to standardise the rates across age groups
rates_with_weights <- age_specific_rates %>%
  left_join(esp_weights_adjusted, by = "Agegroup2") %>%
  mutate(weighted_rate = rate * esp)

# Step 5: Calculate the ASMR
# We sum the weighted rates and divide by the total ESP to get the standardised rate
asmr <- sum(rates_with_weights$weighted_rate, na.rm = TRUE) / sum(rates_with_weights$esp, na.rm = TRUE)

# Step 6: Calculate ASMR confidence intervals using the Dobson method
# This method estimates the variance of the ASMR using the formula:
# Var(ASMR) = sum((w_i^2 * d_i) / p_i^2), where:
# - w_i = ESP weight for age group i
# - d_i = number of deaths in age group i
# - p_i = population in age group i

rates_with_weights <- rates_with_weights %>%
  mutate(variance_component = (esp^2 * total_deaths) / (total_population^2))

# Sum variance components to get total variance
asmr_variance <- sum(rates_with_weights$variance_component, na.rm = TRUE)

# Calculate standard error and 95% confidence interval
asmr_se <- sqrt(asmr_variance)
asmr_lower <- asmr - 1.96 * asmr_se
asmr_upper <- asmr + 1.96 * asmr_se

# Step 7: Display results
# We round the ASMR and confidence interval to two decimal places for reporting
cat("Age-Standardised Mortality Rate (ASMR) for England and Wales (per 100,000):", round(asmr, 2), "\n")
cat("95% Confidence Interval (Dobson method):", round(asmr_lower, 2), "to", round(asmr_upper, 2), "\n")


# 4. Infant Mortality Rate (IMR) ----
# Calculated as deaths under age 1 per 1,000 live births

# Step 1: Filter deaths under age 1
# We use AGEINYRS to identify infant deaths in the deaths dataset
infant_deaths <- deaths %>%
  filter(AGEINYRS < 1)

# Step 2: Count total infant deaths
# This gives the numerator for the IMR calculation
total_infant_deaths <- nrow(infant_deaths)

# Step 3: Count total live births
# We assume each record in the births dataset represents a live birth
# This gives the denominator for the IMR calculation
total_live_births <- nrow(births)

# Step 4: Calculate Infant Mortality Rate (IMR)
# IMR = (Infant deaths / Live births) × 1,000
imr <- (total_infant_deaths / total_live_births) * 1000

# Step 5: Display result
# We round the IMR to two decimal places for reporting
cat("Infant Mortality Rate (IMR) for England and Wales (per 1,000 live births):", round(imr, 2), "\n")


# 5. Perinatal Mortality Rate (PMR) ----
# Calculated as stillbirths + deaths under 7 days per 1,000 total births

# Step 1: Identify deaths of liveborn infants under 7 days
# We use AGECUNIT == 4 (age in days) and AGEC < 7 to capture deaths
# that occurred before the infant reached 7 full days of life.
# This is the most accurate method for identifying perinatal deaths.
perinatal_deaths <- deaths %>%
  filter(AGECUNIT == 4 & AGEC < 7)

# Step 2: Count deaths under 7 days
# These are the early neonatal deaths included in the PMR calculation
total_perinatal_deaths <- nrow(perinatal_deaths)

# Step 3: Identify and count stillbirths
# SBINDZ == 1 indicates a stillbirth; SBINDZ is NULL for live births
stillbirths <- births %>%
  filter(SBIND == 1)

total_stillbirths <- nrow(stillbirths)

# Step 4: Count total births (live births + stillbirths)
# All records in the births dataset are either stillbirths or live births
total_births <- nrow(births)

# Step 5: Calculate Perinatal Mortality Rate (PMR)
# PMR = ((stillbirths + deaths under 7 days) / total births) × 1,000
pmr <- ((total_stillbirths + total_perinatal_deaths) / total_births) * 1000

# Step 6: Display the PMR result
cat("Perinatal Mortality Rate (PMR) for England and Wales (per 1,000 total births):", round(pmr, 2), "\n")


# 6. Years of Life Lost (YLL) due to Accidents ----
# Based on ICD-10 codes V01–X59 and ages 1–74

# Load stringr for string manipulation functions
library(stringr)

# Step 1: Define the ICD-10 codes that represent accidental deaths
# These codes cover unintentional injuries and are grouped as follows:
# - V01–V99: Transport accidents (e.g. pedestrian, cyclist, car, bus, water, air)
# - W00–W99: Other external causes (e.g. falls, mechanical forces, suffocation)
# - X00–X59: Environmental exposures and poisoning (e.g. fire, heat, drowning, poisoning)

accident_codes <- c(
  paste0("V", sprintf("%02d", 1:99)),   # Transport accidents
  paste0("W", sprintf("%02d", 0:99)),   # Falls, mechanical forces, suffocation
  paste0("X", sprintf("%02d", 0:59))    # Fire, heat, natural forces, poisoning
)

# Step 2: Filter the deaths dataset to include only:
# - Deaths where age at death is between 1 and 74 (inclusive of 1, exclusive of 75)
# - Deaths where the underlying cause (FIC10UND) matches one of the accident codes
#   We match only the first 3 characters of the ICD-10 code to account for decimal-point codes (e.g. W85.3)
accident_deaths <- deaths %>%
  filter(AGEINYRS >= 1, AGEINYRS < 75) %>%
  filter(str_sub(FIC10UND, 1, 3) %in% accident_codes)

# Step 3: Calculate Years of Life Lost (YLL) for each death
# YLL is calculated as the difference between the threshold age (75)
# and the midpoint of the age group (age + 0.5)
accident_deaths <- accident_deaths %>%
  mutate(yll = 75 - (AGEINYRS + 0.5))

# Step 4: Summarise the results
# We calculate:
# - Total YLL across all accident deaths
# - Average YLL per accident death
# - Total number of accident deaths included in the analysis
total_accident_yll <- sum(accident_deaths$yll, na.rm = TRUE)
average_accident_yll <- mean(accident_deaths$yll, na.rm = TRUE)
n_accident_deaths <- nrow(accident_deaths)

# Step 5: Display the results
cat("Number of deaths due to accidents (ages 1–74):", n_accident_deaths, "\n")
cat("Total Years of Life Lost (YLL) due to accidents:", round(total_accident_yll, 1), "years\n")
cat("Average YLL per accident death:", round(average_accident_yll, 1), "years\n")


# 7. Years of Working Life Lost (YWLL) ----
# Based on deaths registered in 2024 (REGYR)
# Using working-age definition from 2012 onwards: ages 16–64

# Step 1: Define the working-age range for YWLL calculations
# From the 2012 data year onwards, the working-age population is defined as ages 16 to 64.
# Deaths occurring within this age range are considered premature in terms of economic and social impact.
# The upper age limit for YWLL is fixed at 65 years, representing the notional retirement age.
# Deaths at age 65 or older are excluded from this analysis.

# Step 2: Filter the deaths dataset to include only:
# - Deaths registered in the year 2024 (REGYR == 2024)
# - Deaths where age at death is between 16 and 64 (inclusive of 16, exclusive of 65)
# This ensures that only deaths within the defined working-age range are included.
working_age_deaths <- deaths %>%
  filter(REGYR == 2024, AGEINYRS >= 16, AGEINYRS < 65)

# Step 3: Calculate Years of Working Life Lost (YWLL) for each death
# YWLL is calculated as the difference between the retirement age (65)
# and the midpoint of the age at death (age + 0.5).
# This midpoint adjustment assumes deaths are evenly distributed within each age year.
# For example, a death at age 30 contributes 34.5 YWLL (i.e. 65 - 30.5).
working_age_deaths <- working_age_deaths %>%
  mutate(ywll = 65 - (AGEINYRS + 0.5))

# Step 4: Summarise the results
# We calculate:
# - Total YWLL across all deaths in the working-age range
# - Average YWLL per death (i.e. mean years lost per individual)
# - Total number of deaths included in the YWLL analysis
# These metrics provide insight into the burden of premature mortality on the workforce.
total_ywll <- sum(working_age_deaths$ywll, na.rm = TRUE)
average_ywll <- mean(working_age_deaths$ywll, na.rm = TRUE)
n_working_age_deaths <- nrow(working_age_deaths)

# Step 5: Display the results
# These figures can be used to assess the economic and social impact of premature death
# among the working-age population in England and Wales.
cat("Number of deaths in working age range (16–64):", n_working_age_deaths, "\n")
cat("Total Years of Working Life Lost (YWLL):", round(total_ywll, 1), "years\n")
cat("Average YWLL per death:", round(average_ywll, 1), "years\n")


# 8. Mean Age at Death ----

# Step 1: Calculate the mean age at death
# We use AGEINYRS, which represents age in completed years
# The mean is calculated across all death records
mean_age <- deaths %>%
  summarise(mean_age = mean(AGEINYRS, na.rm = TRUE)) %>%
  pull(mean_age)

# Step 2: Display result
# We round the mean age to one decimal place for reporting
cat("Mean Age at Death for England and Wales:", round(mean_age, 1), "years\n")


## Additional: Mean Age at Death by Region ----

# Step 1: Group deaths by region and calculate mean age
# We use AGEINYRS to calculate the average age at death for each region
mean_age_by_region <- deaths %>%
  group_by(RGNNM) %>%
  summarise(mean_age = round(mean(AGEINYRS, na.rm = TRUE), 1), .groups = "drop")

# Step 2: Display results
# This prints the mean age at death for each region
print(mean_age_by_region)


# 9. Crude Rate of Years of Life Lost (YLL) due to Accidents----
# Based on ICD-10 codes V01–X59 and ages 1–74
# Expressed per 100,000 population

# Step 1: Define ICD-10 codes for accidental deaths
# These codes cover unintentional injuries and are grouped as follows:
# - V01–V99: Transport accidents
# - W00–W99: Other external causes
# - X00–X59: Environmental exposures and poisoning
accident_codes <- c(
  paste0("V", sprintf("%02d", 1:99)),
  paste0("W", sprintf("%02d", 0:99)),
  paste0("X", sprintf("%02d", 0:59))
)

# Step 2: Filter deaths for ages 1–74 and matching accident codes
# Match only the first 3 characters of FIC10UND to handle decimal codes
library(stringr)

accident_deaths <- deaths %>%
  filter(AGEINYRS >= 1, AGEINYRS < 75) %>%
  filter(str_sub(FIC10UND, 1, 3) %in% accident_codes) %>%
  mutate(yll = 75 - (AGEINYRS + 0.5))

# Step 3: Calculate total YLL due to accidents
total_yll <- sum(accident_deaths$yll, na.rm = TRUE)

# Step 4: Extract total mid-year population for England and Wales
mid_year_pop_2024 <- population_estimates %>%
  filter(Areatype == "E&W") %>%
  summarise(total_population = sum(Popn, na.rm = TRUE)) %>%
  pull(total_population)

# Step 5: Calculate crude YLL rate
crude_yll_rate <- (total_yll / mid_year_pop_2024) * 100000

# Step 6: Display the result
cat("Crude YLL rate due to accidents per 100,000 population (2024):", round(crude_yll_rate, 1), "\n")


# 10. Potential Years of Life Lost (PYLL) and Standardised PYLL (SYLL) ----
# PYLL measures premature mortality by weighting deaths at younger ages more heavily
# SYLL adjusts PYLL using the 2013 European Standard Population (ESP)
# Dataset includes deaths registered in 2024 only

# Step 1: Select deaths where age at death is below 75
# PYLL is only calculated for deaths under the defined cut-off age of 75
# This excludes deaths at older ages where cause may be less certain
pyll_deaths <- deaths %>%
  filter(AGEINYRS < 75)

# Step 2: Calculate PYLL for each death
# PYLL is defined as 75 minus the midpoint of the age at death (age + 0.5)
# This assumes deaths are evenly distributed within each age year
pyll_deaths <- pyll_deaths %>%
  mutate(pyll = 75 - (AGEINYRS + 0.5))

# Step 3: Aggregate PYLL by Agegroup2
# We group deaths into standard age bands and sum the total PYLL per group
pyll_by_age <- pyll_deaths %>%
  group_by(Agegroup2) %>%
  summarise(total_pyll = sum(pyll), .groups = "drop")

# Step 4: Ensure all age groups are represented
# We join with the ESP age groups and fill in missing PYLL values with zero
# This ensures consistency when calculating standardised rates
all_agegroups <- esp_weights_adjusted %>%
  dplyr::select(Agegroup2) %>%
  distinct()

pyll_by_age_complete <- all_agegroups %>%
  left_join(pyll_by_age, by = "Agegroup2") %>%
  mutate(total_pyll = replace_na(total_pyll, 0))

# Step 5: Join with mid-year population estimates
# We group population data by Agegroup2 for England and Wales
# This allows us to calculate age-specific PYLL rates
population_by_age <- population_estimates %>%
  filter(Areatype == "E&W") %>%
  group_by(Agegroup2) %>%
  summarise(total_population = sum(Popn, na.rm = TRUE), .groups = "drop")

pyll_rates <- pyll_by_age_complete %>%
  left_join(population_by_age, by = "Agegroup2") %>%
  mutate(pyll_rate = (total_pyll / total_population) * 100000)

# Step 6: Apply ESP weights to calculate weighted PYLL rates
# This prepares the data for standardisation using the 2013 ESP
pyll_rates <- pyll_rates %>%
  left_join(esp_weights_adjusted, by = "Agegroup2") %>%
  mutate(weighted_rate = pyll_rate * esp)

# Step 7: Calculate the Standardised PYLL (SYLL)
# SYLL is the sum of weighted PYLL rates divided by the total ESP
syll <- sum(pyll_rates$weighted_rate, na.rm = TRUE) / sum(pyll_rates$esp, na.rm = TRUE)

# Step 8: Display the results
cat("Total Potential Years of Life Lost (PYLL):", round(sum(pyll_deaths$pyll, na.rm = TRUE), 1), "years\n")
cat("Standardised PYLL rate (SYLL) per 100,000 population:", round(syll, 1), "\n")


# Additional - Registration Delays ----
# Calculated as the number of days between date of death and date of registration
# Includes summary statistics: median, lower quartile, and upper quartile

# Step 1: Check if DOD and DOR are already in Date format
# If not, convert from character using format YYYYMMDD
if (!inherits(deaths$DOD, "Date")) {
  deaths <- deaths %>%
    mutate(DOD = as.Date(as.character(DOD), format = "%Y%m%d"))
}

if (!inherits(deaths$DOR, "Date")) {
  deaths <- deaths %>%
    mutate(DOR = as.Date(as.character(DOR), format = "%Y%m%d"))
}

# Step 2: Calculate registration delay in days
# Delay is defined as the difference between registration date and date of death
deaths <- deaths %>%
  mutate(delay = as.numeric(DOR - DOD))

# Step 3: Calculate summary statistics for registration delays
# Includes median, lower quartile (25th percentile), and upper quartile (75th percentile)
delay_summary <- deaths %>%
  summarise(median_delay = median(delay, na.rm = TRUE),
            lower_quantile = quantile(delay, probs = 0.25, na.rm = TRUE),
            upper_quantile = quantile(delay, probs = 0.75, na.rm = TRUE))

# Step 4: Display results
cat("Median registration delay:", round(delay_summary$median_delay, 1), "days\n")
cat("Lower quartile (25th percentile):", round(delay_summary$lower_quantile, 1), "days\n")
cat("Upper quartile (75th percentile):", round(delay_summary$upper_quantile, 1), "days\n")


#Additional - Registration Delays by certification type ----
# Calculated as the number of days between date of death and date of registration
# Includes summary statistics: median, lower quartile, and upper quartile
# Grouped by certification type (CERTTYPE)

# Step 1: Check if DOD and DOR are already in Date format
# If not, convert from character using format YYYYMMDD
if (!inherits(deaths$DOD, "Date")) {
  deaths <- deaths %>%
    mutate(DOD = as.Date(as.character(DOD), format = "%Y%m%d"))
}

if (!inherits(deaths$DOR, "Date")) {
  deaths <- deaths %>%
    mutate(DOR = as.Date(as.character(DOR), format = "%Y%m%d"))
}

# Step 2: Calculate registration delay in days
# Delay is defined as the difference between registration date and date of death
deaths <- deaths %>%
  mutate(delay = as.numeric(DOR - DOD))

# Step 3: Create a lookup table for CERTTYPE descriptions
certtype_lookup <- tibble::tibble(
  CERTTYPE = 1:9,
  Description = c(
    "Certified by doctor, no post mortem",
    "Certified by doctor, post mortem",
    "Certified by coroner, inquest and post mortem",
    "Certified by coroner, inquest no post mortem",
    "Certified by coroner, no inquest, post mortem",
    "Uncertified",
    "PM info not known on Doctor’s Medical Certificate (new values)",
    "PM info not known on Coroner’s inquest (new values)",
    "Not known (unable to derive)"
  )
)

# Step 4: Filter to deaths registered in 2024
# This ensures the analysis is limited to a single registration year.
deaths_2024 <- deaths %>%
  filter(lubridate::year(DOR) == 2024)
 
# Step 5: Calculate summary statistics grouped by CERTTYPE
delay_by_certtype <- deaths_2024 %>%
  group_by(CERTTYPE) %>%
  summarise(
    median_delay = median(delay, na.rm = TRUE),
    lower_quantile = quantile(delay, probs = 0.25, na.rm = TRUE),
    upper_quantile = quantile(delay, probs = 0.75, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  left_join(certtype_lookup, by = "CERTTYPE") %>%
  dplyr::select(CERTTYPE, Description, median_delay, lower_quantile, upper_quantile) %>%
  arrange(CERTTYPE)

# Step 6: Display results as a tibble
print(delay_by_certtype)

# Unit: Life Expectancy Methods & Modelling Expected Deaths and Excess Mortality ----

## Overview: ----
# This script is part of the ONS mortality analysis training package.
# It demonstrates two key components of mortality analysis:
# 
# 1. Life Expectancy Methods:
#    - Calculates life expectancy using a period life table approach.
#    - Applies observed age-specific mortality rates to a hypothetical cohort.
#    - Outputs key life table columns including mx, qx, lx, dx, Lx, Tx, and ex.
#
# 2. Modelling Expected Deaths and Excess Mortality:
#    - Uses a quasi-Poisson regression to estimate expected deaths.
#    - Calculates excess deaths using synthetic weekly data.
#    - Visualises observed versus expected deaths for interpretation.

## Purpose: ----
# To provide practical examples of:
# - Constructing a life table and calculating life expectancy
# - Preparing weekly mortality and population data for modelling
# - Fitting a quasi-Poisson regression model to estimate expected deaths
# - Calculating excess deaths for recent years
# - Creating visual outputs suitable for reporting

## Learning Outcomes: ----
# - Understand the structure and purpose of a life table
# - Apply life table formulas to calculate life expectancy by age
# - Understand the structure of weekly mortality data
# - Apply statistical modelling to estimate expected deaths
# - Calculate excess deaths and interpret patterns
# - Create visual outputs suitable for reporting

## Data Requirements: ----
# The following files are provided with this training unit:

# - synthetic_life_table.csv
#     > Contains synthetic age-specific death counts and population estimates
#     > Used to calculate life expectancy using life table methods

# - synthetic_deaths_weekly.csv
#     > Contains synthetic weekly death registrations for England and Wales

# - synthetic_mid_year_estimates.csv
#     > Contains synthetic mid-year population estimates by year, age group, sex, and geography

## Required Packages: ----
# - readr (for reading CSV files)
# - dplyr (for data manipulation)
# - ggplot2 (for visualisation)
# - lubridate (for handling dates)

## Setup: Working Directory and Package Loading ----

# Set working directory to the root folder of the training unit
# Update this path to match your local setup
setwd("D:/Mortality Training Unit")

# Load Required Packages ----
# These packages support reading data, transforming variables, handling dates, and creating visualisations
library(readr)      # Reads CSV files into R
library(dplyr)      # Cleans and transforms data
library(ggplot2)    # Creates charts and plots
library(lubridate)  # Handles date formats and calculations

## Load Synthetic Weekly Deaths, Population Estimates, and Life Table Data ----
# These datasets simulate:
# - Weekly death registrations for England and Wales
# - Mid-year population estimates by year, age group, sex, and geography
# - Age-specific death counts and population estimates for life table calculations

## Check and load synthetic weekly deaths dataset ----
if (!file.exists("Data/synthetic_deaths_weekly.csv")) {
  stop("Weekly deaths dataset not found. Please check your file path.")
}
deaths <- read_csv("Data/synthetic_deaths_weekly.csv")

## Check and load synthetic mid-year population estimates ----
if (!file.exists("Data/synthetic_mid_year_estimates.csv")) {
  stop("Mid-year population estimates file not found.")
}
population_estimates <- read_csv("Data/synthetic_mid_year_estimates.csv")

## Check and load synthetic life table dataset ----
if (!file.exists("Data/synthetic_life_table.csv")) {
  stop("Synthetic life table dataset not found. Please check your file path.")
}
synthetic_life_table <- read_csv("Data/synthetic_life_table.csv")

## Preview Data (Optional for Learners) ----
# Display the first few rows of each dataset to understand their structure

cat("Weekly Deaths Dataset:\n")
head(deaths)

cat("\nMid-Year Population Estimates:\n")
head(population_estimates)

cat("\nSynthetic Life Table Dataset:\n")

# Life Expectancy Calculation Using Life Table Methods ----

## Step 1: Calculate Central Mortality Rate (mx) ----
# mx is the central mortality rate at each age.
# It is calculated as the number of deaths divided by the population at that age.
synthetic_life_table <- synthetic_life_table %>%
  mutate(mx = Deaths / Population)

## Step 2: Calculate Probability of Dying (qx) ----
# qx is the probability of dying between age x and x+1.
# For age 0 (infants), we use a simplified formula: qx = mx / (1 + mx)
# For ages 1+, we use the standard approximation: qx = (2 * mx) / (2 + mx)
#
# Note: In official ONS National Life Tables, infant mortality (q0) is calculated using
# grouped deaths under 1 year (<4 weeks, 1–2 months, 3–5 months, etc.) and matched
# monthly birth data to derive a more accurate q0. This method accounts for the uneven
# distribution of infant deaths and uses assumed average ages at death for each group.
# For training purposes, we use a simplified formula here.
synthetic_life_table <- synthetic_life_table %>%
  mutate(
    qx = case_when(
      Age == 0 ~ mx / (1 + mx),
      TRUE ~ (2 * mx) / (2 + mx)
    )
  )

## Step 3: Calculate Number of Survivors (lx) ----
# lx is the number of people surviving to exact age x from a starting cohort of 100,000 live births.
# We initialise lx at age 0 and calculate subsequent lx values using qx.
synthetic_life_table <- synthetic_life_table %>%
  mutate(lx = NA_real_) %>%
  mutate(lx = if_else(Age == 0, 100000, NA_real_))

for (i in 2:nrow(synthetic_life_table)) {
  synthetic_life_table$lx[i] <- synthetic_life_table$lx[i - 1] * (1 - synthetic_life_table$qx[i - 1])
}

## Step 4: Calculate Number of Deaths (dx) ----
# dx is the number of deaths between age x and x+1.
# It is calculated as dx = lx * qx
synthetic_life_table <- synthetic_life_table %>%
  mutate(dx = lx * qx)

## Step 5: Calculate Person-Years Lived (Lx) ----
# Lx is the number of person-years lived between age x and x+1.
# For most ages: Lx = (lx + lx+1) / 2
# For age 0: L0 = l1 + a0 * d0, where a0 is the average age at death in the first year (assumed 0.1)
# For the final age group: Lx = lx / mx
synthetic_life_table <- synthetic_life_table %>%
  mutate(Lx = NA_real_)

for (i in 1:(nrow(synthetic_life_table) - 1)) {
  synthetic_life_table$Lx[i] <- (synthetic_life_table$lx[i] + synthetic_life_table$lx[i + 1]) / 2
}

synthetic_life_table$Lx[1] <- synthetic_life_table$lx[2] + 0.1 * synthetic_life_table$dx[1]
synthetic_life_table$Lx[nrow(synthetic_life_table)] <- synthetic_life_table$lx[nrow(synthetic_life_table)] / synthetic_life_table$mx[nrow(synthetic_life_table)]

## Step 6: Calculate Total Person-Years Lived (Tx) ----
# Tx is the total number of person-years lived from age x onward.
# It is calculated as the cumulative sum of Lx from age x to the final age.
synthetic_life_table <- synthetic_life_table %>%
  mutate(Tx = NA_real_)

for (i in nrow(synthetic_life_table):1) {
  if (i == nrow(synthetic_life_table)) {
    synthetic_life_table$Tx[i] <- synthetic_life_table$Lx[i]
  } else {
    synthetic_life_table$Tx[i] <- synthetic_life_table$Tx[i + 1] + synthetic_life_table$Lx[i]
  }
}

## Step 7: Calculate Life Expectancy (ex) ----
# ex is the life expectancy at exact age x.
# It is calculated as ex = Tx / lx and rounded to 2 decimal places.
synthetic_life_table <- synthetic_life_table %>%
  mutate(ex = round(Tx / lx, 2))

## Step 8: Preview Final Life Table ----
# This shows the structure and calculated columns of the life table.
glimpse(synthetic_life_table)

## Step 9: Visualise Life Expectancy by Age ----
# This chart shows how life expectancy changes with age.
ggplot(synthetic_life_table, aes(x = Age, y = ex)) +
  geom_line(color = "blue") +
  labs(
    title = "Life Expectancy by Age",
    x = "Age",
    y = "Life Expectancy (ex)",
    caption = "Source: Synthetic training data"
  ) +
  theme_minimal()

## Step 10: Save Life Table Outputs ----
# Save the full life table with calculated columns for further analysis or reporting.
if (!dir.exists("Outputs")) dir.create("Outputs")

write_csv(synthetic_life_table, "Outputs/life_expectancy_table.csv")

write_csv(
  synthetic_life_table %>% mutate(across(where(is.numeric), ~ round(., 1))),
  "Outputs/life_expectancy_table_rounded.csv"
)

# Unit: Modelling Expected Deaths and Excess Mortality ----

## Step 1: Format Variables ----
# Convert date fields and categorical variables to appropriate formats for analysis.
# This ensures dates are recognised correctly and categorical variables are treated appropriately in modelling.
deaths <- deaths %>%
  mutate(
    week_start_date = as.Date(week_start_date),   # Convert start of week to Date format
    week_end_date = as.Date(week_end_date),       # Convert end of week to Date format
    age_group = as.factor(age_group),             # Convert age group to factor
    sex = as.factor(sex),                         # Convert sex to factor
    geography = as.factor(geography)              # Convert geography to factor
  )

population_estimates <- population_estimates %>%
  mutate(
    age_group = as.factor(age_group),             # Convert age group to factor
    sex = as.factor(sex),                         # Convert sex to factor
    geography = as.factor(geography)              # Convert geography to factor
  )

## Step 2: Merge Deaths with Population Estimates ----
# Join the weekly deaths dataset with population estimates.
# This allows each death count to be matched with the relevant population size for modelling.
merged_df <- deaths %>%
  left_join(population_estimates, by = c("year", "age_group", "sex", "geography"))

## Step 3: Create Coarse Age Groups ----
# Coarse age bands are used in seasonal interaction terms to reflect broader mortality patterns.
# These simplify the age structure for seasonal modelling while retaining key age distinctions.
merged_df <- merged_df %>%
  mutate(
    age_coarse = case_when(
      age_group %in% c("Under 1", "1-4", "5-9", "10-14", "15-19", "20-24") ~ "Under 30",
      age_group %in% c("25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69") ~ "30-69",
      TRUE ~ "70+"
    )
  )

## Step 4: Prepare Variables for Modelling ----
# Create variables needed for the statistical model:
# - weeknumber: captures seasonal variation across the year
# - timeindex: represents long-term trend across weeks
# - logpop: offset term to adjust for population size in the model
merged_df <- merged_df %>%
  mutate(
    weeknumber = week(week_start_date),                 # Extract week number from date
    timeindex = as.numeric(as.factor(week_start_date)), # Create numeric time index
    logpop = log(population)                            # Log of population for offset
  )

## Step 5: Define Model Fitting and Prediction Periods ----
# Fit the model using five years of historical data (2017 to 2022).
# Predict expected deaths for 2023 and 2024 only.
training_data <- merged_df %>% filter(year >= 2017 & year <= 2022)
prediction_data <- merged_df %>% filter(year %in% c(2023, 2024))

## Step 6: Fit Quasi-Poisson Regression Model ----
# This model estimates expected deaths using:
# - demographic and geographic variables
# - a linear time trend
# - seasonal effects by week
# - interaction between age and season
# - an offset for population size
glm_model <- glm(
  deaths ~ age_group + sex + geography +
    timeindex +
    factor(weeknumber) +
    factor(age_coarse):factor(weeknumber),
  offset = logpop,
  family = quasipoisson(link = "log"),
  data = training_data
)

## Step 7: Predict Expected Deaths and Calculate Excess Deaths ----
# Use the fitted model to estimate expected deaths for 2023 and 2024.
# Excess deaths are calculated as: observed deaths minus expected deaths.
prediction_data$expected_deaths <- predict(glm_model, newdata = prediction_data, type = "response")
prediction_data$excess_deaths <- prediction_data$deaths - prediction_data$expected_deaths

## Step 8: Aggregate Weekly Totals ----
# Summarise observed, expected, and excess deaths by week, geography, age group, and sex.
# This prepares the data for visualisation and reporting.
weekly_summary <- prediction_data %>%
  group_by(year, week_end_date, geography, age_group, sex) %>%
  summarise(
    observed = sum(deaths),
    expected = sum(expected_deaths),
    excess = sum(excess_deaths),
    .groups = "drop"
  )

## Step 9: Filter for England and Wales, All Ages, People ----
# This subset is used for visualisation and reporting.
# It focuses on total deaths across all ages and sexes for England and Wales.
EW_weekly_summary_recent <- weekly_summary %>%
  filter(
    geography == "England and Wales",
    age_group == "All ages",
    sex == "people"
  )

## Step 10: Visualise Observed versus Expected Deaths ----
# Create a chart showing:
# - observed deaths as blue bars
# - expected deaths as a black line
# This visualisation helps identify periods of excess mortality.
ggplot(EW_weekly_summary_recent, aes(x = week_end_date)) +
  geom_col(aes(y = observed), fill = "steelblue", width = 6) +
  geom_line(aes(y = expected), colour = "black", size = 1.2) +
  scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = "Weekly Observed versus Expected Deaths in England and Wales (2023 to 2024)",
    subtitle = "Observed deaths shown as bars; expected deaths shown as a line",
    x = "Week Ending",
    y = "Number of Deaths",
    caption = "Source: Synthetic training data"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major.y = element_line(color = "grey80"),
    panel.grid.minor = element_blank()
  )

## Step 11: Save Outputs for 2023 and 2024 ----
# Save both full and rounded versions of the dataset for analysis and presentation.
# Rounded versions are useful for public-facing outputs and charts.
if (!dir.exists("Outputs")) dir.create("Outputs")

write_csv(prediction_data, "Outputs/excess_deaths_by_stratum_2023_2024.csv")
write_csv(weekly_summary, "Outputs/weekly_excess_deaths_summary_2023_2024.csv")

write_csv(
  prediction_data %>% mutate(across(where(is.numeric), ~ round(., 0))),
  "Outputs/excess_deaths_by_stratum_2023_2024_rounded.csv"
)

write_csv(
  weekly_summary %>% mutate(across(where(is.numeric), ~ round(., 0))),
  "Outputs/weekly_excess_deaths_summary_2023_2024_rounded.csv"
)