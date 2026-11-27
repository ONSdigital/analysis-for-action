#' Import births data set for chosen year
#'
#' @param sql_server Name of SQL server, as a character string.
#' @param database Name of database, as a character string.
#' @param year 4-digit year of data, as integer.
#'
#' @return Data frame of births data.
#' @export
#'
import_births_ew <- function(sql_server,
                             database,
                             year) {

  halefunctionlib::sql_data_import(
    server = sql_server,
    database =  database,
    variables = paste("agebm, sex, multbth, mattab, multtype, prevchl, sbind,",
                      "agebf, bthimar, pcdrm, birthwgt, gestatn, bwigs10,",
                      "sourcetable, esttypeb, dob, secclrm, secclrf, pind,",
                      "dobm, dobf"),
    filter = paste0("sourcetable =", year))
}


#' Import National Statistics Postcode Lookup (NSPL)
#'
#' @param sql_server Name of SQL server, as a character string.
#' @param database Name of database, as a character string.
#' @param met_county_colname Column name for metropolitan county codes in NSPL
#' data set, which varies in each version, as a character string.
#'
#' @return Data frame of NSPL data.
#' @export
#'
import_nspl <- function(sql_server,
                        database,
                        met_county_colname) {

  halefunctionlib::sql_data_import(
    server = sql_server,
    database = database,
    variables = paste("pcd, gor, ctry, laua, cty, lsoa11,", met_county_colname),
    filter = "laua LIKE 'W%' OR laua LIKE 'E%'")

}

### Further import functions including import_births_scot, import_births_ni,
## import_births_notif, import_populations etc. not shown ###
