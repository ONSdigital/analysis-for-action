# Project Setup ----

cfg <- list()

cfg$year_full <- 2021 # 4-digit data year as integer
cfg$year <- cfg$year_full %% 100 # Do not edit


# SQL ----

sqldb <- list()

sqldb$server <- "server"
# Depends which NSPL is being used
sqldb$met_county_colname <- "met_county"

#### Only edit if database names change
sqldb$births_ew <- "births_ew"
# "_reg" only included in table name for years > 2019
sqldb$births_scot <- paste0("births_scot", cfg$year, "b_reg")
sqldb$births_ni <- paste0("births_ni", cfg$year, "b_reg")
# "d" not included in table name for 2022
sqldb$births_notif <- paste0("births_notif", cfg$year, "bd")
# Pops may need to be most up to date file, rather than previous ones
sqldb$pops <- paste0("populations", cfg$year)
# Generally MAY of year after data year, same in all publications that year
sqldb$nspl <- paste0("NSPL", cfg$year + 1, "MAY")

# Backseries file paths
backseries <- list()

backseries$drive <- "drive"
backseries$t12 <- "table_12.csv"
