> An edited version of the original README is included below. It has been simplified and shortened to focus on key concepts.
**Please note: This codebase is not functional and is provided for demonstration purposes only.**

# Birth characteristics RAP: (Work in progress)
Repository for producing the Birth characteristics and Births by parents’ characteristics publications.

## Contents
- [Project description](#project-description)
- [Code authors](#code-authors)
- [How to run the pipeline](#how-to-run-the-pipeline)
- [Methodology](#methodology)
- [Desk notes](#desk-notes)

## Project description
The releases Birth characteristics and Birth by parents’ characteristics  are annual live births in England and Wales by sex, birthweight, gestational age, ethnicity and month, maternities by place of birth and with multiple births, and stillbirths by age of parents and calendar quarter.

Births Characteristics comprises a bulletin and 2 workbooks (birth characteristics and birth by parents' characteristics).

#### Existing publications
- Birth Characteritics bulletin
- Birth characteritics data
- Births by parents characteritics data
- User guide to birth statistics
- Births QMI


## Code authors

Authors of birth.char package:


## How to run the pipeline

### `birth.char` package installation
You will need to have the `devtools` package installed. Clone this repository and run `devtools::install("birth.char")` to install the `R` package. Please note that your working directory needs to be set as the project directory, e.g.: `setwd(“location_on_your_PC/birth-characteristics”)`.

<br>

### Running the pipeline:

To run the analysis, your working directory should be set to the `birth.characteristics` folder, where the cloned repository is stored. Firstly, **update** the variables in `config.R`, and then run `main.R`.

#### Required packages
The following packages should be installed:

*   `birth.char`
*   `halefunctionlib`

#### Config

General config parameters, stored in the `cfg` list object:
*   `year_full`: 4-digit year of data used.
*   `year`: Do not edit. Uses to `year_full` to produce 2 digit year of data.

SQL import parameters, stored in the `sqldb` list object:
*   `server`: Name of server, as a character string.
*   `met_county_colname`: Column name for met county codes in NSPL data set, which varies in each version, as a character string.
*   `births_ew`: Births registrations database for England and Wales
*   `births_scot`: Births database for Scotland
*   `births_ni`: Births database for Northern Ireland
*   `births_notif`: Births notifications database.
*   `pops`: Populations database
*   `nspl`: National Statistics Postcode Lookup database

<br>

### Contribution guidance
*  Never push directly to the main branch. Develop new code in separate branch and create a merge request.

*  Another analyst should peer review your code before merging with the main branch.

*  When new functions are added to the package, they should have complete documentation and unit tests written.

*  Code should follow the tidyverse [style guide](https://style.tidyverse.org/), and utilise the functions within this collection of packages.

*  Use the standardised commit messages:


    **feat** — A new feature

    **fix** — A bug fix

    **docs** — Changes only to documentation

    **style** — Changes to formatting (missing semicolons, etc.)

    **refactor** — A code change that neither fixes a bug nor adds a feature

    **update** — Changes to update code but not change functionality

    **test** — Adding missing, or correcting existing, tests

    **chore** — Change to build process or auxiliary tools, or maintenance

<br>

## Methodology
For more in-depth information on the methodology of this publication, please see the following files:

- Births QMI
- Births User guide
- Births Characteristics desknotes

## Desk notes
- Births Characteristics desknotes
- Birth Characteristic & Birth by parents' characteristic wash-up meeting notes
