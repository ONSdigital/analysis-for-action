# What’s included:
## On git repo

1. **Python Code**
Contains the Python version of the training script. This has already been run and includes all outputs.


2. **R Code**
* Training code.R - Contains all the training code for learners. This includes links so users can click on a topic and jump straight to it.
* Mortality Training Unit.Rmd - The R Markdown version of the training code.
* Mortality-Training-Unit.html - The fully rendered HTML version, showing all outputs including charts. This version is especially useful if users want to link directly from the Word document to a specific section in the code.
 
 ## On Google Drive

 3. **Data**
**Used for calculating mortality rates:**

* synthetic_death_registration_dataset.csv - Contains 153,198 synthetic death records for England and Wales, including neonatal deaths. 
* synthetic_death_registration_data_dictionary.xlsx - Describes all variables in the synthetic death registration dataset.
* synthetic_birth_notifications_dataset.csv - Contains synthetic birth notification records for England and Wales.
* synthetic_birth_notifications_dictionary.csv - Describes all variables in the birth notifications dataset.
* mid_year_population_estimates.csv - Contains mid-year population estimates for England and Wales, England, Wales, and regions.
* european_standard_population.csv - Provides standard population weights for ASMR calculations.

**Used for calculating life expectancy:**
* synthetic_life_table.csv - Contains synthetic age-specific death counts and population estimates. Used to calculate life expectancy using life table methods.

**Used for modelling expected deaths and excess mortality:**
* synthetic_deaths_weekly.csv - Contains synthetic weekly death registrations for England and Wales.
* synthetic_mid_year_estimates.csv - Contains synthetic mid-year population estimates by year, age group, sex, and geography.
 

4. **Outputs**
Contains the outputs generated from running the R code for the excess deaths and life tables sections.

5. **Additional**

* Mortality rates inc. Dobson method for 95% CIs New.xlsx - An Excel tool that calculates a range of mortality rates and 95% confidence intervals using the Dobson method. This allows users to produce key rates outside of R or Python. This also includes examples on each table. [This file can also be found on Google Drive]