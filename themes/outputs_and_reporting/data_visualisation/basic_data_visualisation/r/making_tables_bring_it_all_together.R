create_table <- function(){
  ## Script to accompany 'Bring it all together' section of Basic Data Visualisation

  # Set up

  install.packages(c(
    readr, # for read_csv()
    dplyr, # for data manipulation
    tidyr, # for pivot_wider() and drop_na()
    janitor, # for clean_names()
    gt # for creating and styling tables
  ))


  library(readr)
  library(dplyr)
  library(tidyr)
  library(janitor)
  library(gt)

  # Importing data using the readr package and read_csv function

  vulnerable <- read_csv("D:/repos/ons-ppt/data/vulnerable.csv")


  # Prepare the data to make it suitable for a table

  vuln_for_select_countries_3y <- vulnerable %>%

    filter(year %in% c(1997, 2002, 2007)) %>%

    select(country, continent, year, vulnerable_pop) %>%

    # Reshaping the data

    tidyr::pivot_wider(names_from = year, values_from = vulnerable_pop) %>%

    tidyr::drop_na() %>%

    group_by(continent) %>%

    # Selecting the top 2 values

    dplyr::top_n(n = 2)


  # Cleaning the column names

  vuln_for_select_countries_3y <- janitor::clean_names(vuln_for_select_countries_3y)

  # To Display the data

  vuln_for_select_countries_3y

  # Make a table
  # Add a title
  # Add a subtitle
  # Add a source
  # Add a footnote
  # Use locations to specify where it should appear
  # Label your columns

  vuln_for_select_countries_3y <- vuln_for_select_countries_3y%>%

    gt(rowname_col = "country",

      groupname_col = "continent") %>%

    tab_header(title = gt::md("**Table 1: Vulnerable populations increase in size over time**"),

              subtitle = gt::md("*Size of vulnerable population in select countries in 1997, 2002, and 2007*")

    ) %>%

    tab_source_note(source_note = gt::md("Source: Pandemic Preparedness Toolkit")

    ) %>%

    # Add a footnote

    tab_footnote(footnote = "Data from 1997 is incomplete",

                locations = cells_column_labels(columns = ("x1997"))

    ) %>%

    # Add a spanner

    tab_spanner(label = gt::md("**Years**"), columns = everything()

    ) %>%

    # Add a stub head

    tab_stubhead(label = gt::md("**Continent**")

    )

  # Save the table as HTML

  vuln_for_select_countries_3y %>%

    gtsave(filename = "R_table.html", path = "D:/Temp/")
}
create_table()
