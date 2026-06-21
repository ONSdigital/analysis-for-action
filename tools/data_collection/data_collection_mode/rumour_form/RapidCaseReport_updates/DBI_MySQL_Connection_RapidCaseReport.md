# MySQL Database Connection and Table Setup – RumorForm WP1.1

This script demonstrates how to use `DBI` and `RMariaDB` to:

- Connect to a MySQL database
- Create a table for form submissions
- Insert new records from the Shiny app

```r
library(DBI)
library(RMariaDB)

# 1. Connect to MySQL Database
con <- dbConnect(
  RMariaDB::MariaDB(),
  dbname = "your_database_name",
  host = "your_host",
  port = 3306,
  user = "your_username",
  password = "your_password"
)

# 2. Create table if it doesn't exist
dbExecute(con, """
CREATE TABLE IF NOT EXISTS rumor_reports (
  id_code VARCHAR(36) PRIMARY KEY,
  report_opened DATETIME,
  consultation_date DATE,
  sex CHAR(1),
  birth_date DATE,
  residence_country VARCHAR(100),
  residence_province VARCHAR(100),
  residence_locality VARCHAR(100),
  symptom_onset_date DATE,
  symptom_description TEXT,
  hpo_codes VARCHAR(255),
  suspected_diagnosis TEXT,
  icd10_code VARCHAR(10),
  confirmation_time DATETIME
);
""")

# 3. Function to insert a record
db_insert_rumor <- function(con, data) {
  dbWriteTable(
    con, "rumor_reports", data,
    append = TRUE, row.names = FALSE
  )
}

# Example use inside a Shiny server after form confirmation:
# db_insert_report(con, new_entry)

# Disconnect when done
dbDisconnect(con)
```
