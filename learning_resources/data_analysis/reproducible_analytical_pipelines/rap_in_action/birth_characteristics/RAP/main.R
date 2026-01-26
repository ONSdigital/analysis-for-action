# This script is based on old code created to produce publication tables for
# Birth Characteristics.
# It has been been heavily edited and sections have been removed for
# example purposes.
# This repository should only be used as an example alongside the Analysis for
# Action Birth Characteristics RAP learning resource.

# Setup ----

source("config.R")
library(birth.char)

# Import data ----

births <- list(
  ew = import_births_ew(sqldb$server, sqldb$births_ew, cfg$year_full),
  scotland = import_births_scot(sqldb$server, sqldb$births_scot, cfg$year_full),
  ni = import_births_ni(sqldb$server, sqldb$births_ni, cfg$year_full)
)

births_notifications <- import_births_notif(sqldb$server,
                                            sqldb$births_notif,
                                            cfg$year_full)

pops <- import_populations(sqldb$server, sqldb$pops, cfg$year_full)

nspl <- import_nspl(sqldb$server, sqldb$nspl, sqldb$met_county_colname)

# Data processing ----

nspl <- process_nspl(nspl, sqldb$met_county_colname)

pops <- process_pops(pops)

births$scotland <- add_laua_ni_scot(births$scotland, "S")
births$ni <- add_laua_ni_scot(births$ni, "N")
births$ew <- process_ew_notif(births$ew, nspl, "gestatn")
births <- lapply(births, process_births)

# Birth Characteristics tables ----

### Processing of table 1 to 11 not shown ###

table_12 <- multi_mat_count_rate_agegrp_ew(births$ew) %>%
  format_multi_mat_count_rate_agegrp(cfg$year_full) %>%
  unreliable_rate_mat_mulbth() %>%
  add_backseries(backseries$drive, backseries$t12, cfg$year_full)

### Processing of tables 13 onwards not shown ###

### Processing of Parents Characteristics tables not shown ###

# Output ----

wb_source <- "Source: Office for National Statistics"

wb <- openxlsx::createWorkbook()

### Outputs of table 1 to 11 not shown ###

halefunctionlib::create_data_table_tab(
   wb, table_12, "Table_12",
   heading = paste(
      "Worksheet 12: Maternities with multiple births (numbers and rates) by",
      "age of mother, England and Wales, 1938 to",
      cfg$year_full),
   additional_text = wb_source,
   no_decimal = c(2:9),
   one_decimal = c(10:17),
   num_char_cols = 2:17,
   column_width = c(17, rep(20, 16)),
   border_type = "outline"
)

### Outputs of table 13 onwards not shown ###
### Outputs of Parents Characteristics tables not shown ###
