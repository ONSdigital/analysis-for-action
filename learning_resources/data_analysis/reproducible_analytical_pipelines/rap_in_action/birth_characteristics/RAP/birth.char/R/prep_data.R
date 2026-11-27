#' Process NSPL data
#'
#' @description Process National Statistics Postcode Location (NSPL) data.
#' Rename column containing Metropolitan County codes to "mcounty", remove space
#' from postcodes column and create a joint local authority unitary authority
#' (laua) code for Cornwall and Isle of Scilly.
#'
#' @param nspl NSPL data frame.
#' @param met_county_colname Column name for Metropolitan County codes in NSPL,
#' which varies in each NSPL data version, as a character string.
#'
#' @return Processed NSPL data frame.
#' @export
#'
process_nspl <- function(nspl, met_county_colname) {

  nspl %>%
    dplyr::rename(mcounty = dplyr::all_of(met_county_colname)) %>%
    dplyr::mutate(
      pcd = gsub(" ", "", pcd),
      laua = ifelse(
        laua %in% c("E06000052", "E06000053"),
        "E06000052, E06000053",
        laua))
}

#' Process births data from England and Wales
#'
#' @description Apply processing to both births registrations and notifications
#' data from England and Wales. Joins NSPL codes, changes mother's age to 2
#' digits and add gestation weeks groupings and number of previous live-born
#' children.
#'
#' @param df Births data frame from England and Wales, registrations or
#' notifications.
#' @param nspl NSPL data frame.
#' @param gest_col Column name with gestation time, either "gestatn" or
#' "gest10", as a string.
#'
#' @return Births data frame with added geography columns, age (in years) for
#' mothers, age groupings (agegrp) for mothers, gestational time groupings
#' (gest) and number of previous live-born children.
#' @export
#'
process_ew_notif <- function(df, nspl, gest_col) {
  df %>%
    join_births_nspl(nspl) %>%
    dplyr::mutate(age = as.numeric(substr(agebm, 1, 2))) %>%
    cut_mothers_age() %>%
    flag_gest(gest_col) %>%
    flag_previous_children()
}

#' Join births and NSPL data
#'
#' @description Removes the space from the births postcode column (pcdrm) and
#' then left joins the NSPL onto the births dataframe.
#'
#' @param births_df Births data frame containing `pcdrm` column.
#' @param nspl NSPL data frame.
#'
#' @return Births data frame with NSPL information.
#' @export
#'
join_births_nspl <- function(births_df, nspl) {
  births_df %>%
    dplyr::mutate(pcdrm = gsub(" ", "", pcdrm)) %>%
    dplyr::left_join(nspl, by = dplyr::join_by(pcdrm == pcd))
}

### Further processing functions e.g. process_pops, add_laua_ni_scot,
### process_ew_notif etc... not shown ###
