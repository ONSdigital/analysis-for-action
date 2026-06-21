#' Creates unreliability columns to data frame
#'
#' @description Checks whether any values from the specified columns contain
#' counts that are considered unreliable. If so, it adds unreliability columns
#' and populates, otherwise returns original data frame.
#'
#' @param data Output data frame.
#' @param columns Vector of quoted column names to be checked against threshold.
#' @param lower Integer value of lower threshold to use (inclusive).
#' Default is 3.
#' @param upper Integer value of upper threshold to use (inclusive).
#' Default is 19.
#'
#' @return Data frame with additional unreliability columns if applicable.
#' @export
#'
create_unreliability_columns <- function(data,
                                         columns,
                                         lower = 3,
                                         upper = 19) {

  check <- (
    (sum(data[, columns] <= upper)) &
      (sum(data[, columns] >=  lower))
    > 0) # Check if any columns meet criteria

  if (check == TRUE) {
    for (col in columns) {
      data <- create_unreliability_col(
        data, col, lower, upper)
    }
  }
  data
}


#' Inserts unreliability column to data frame after and based on single column
#'
#' @description Adds an unreliability column after original column and populates
#' with \[u] if between upper and lower thresholds (inclusive). This is for
#' counts when the unreliable column is next to the count, not rate.
#'
#' @param data Processed data frame.
#' @param column String name of column.
#' @param lower Integer value of lower threshold to use (inclusive).
#' @param upper Integer value of upper threshold to use (inclusive).
#'
#' @return Data frame with additional unreliability column.
#' @export
#'
create_unreliability_col <- function(data, column, lower, upper) {

  dplyr::mutate(
    data,
    "Unreliable indicator {column}" := dplyr::if_else(
      (.data[[column]] <= upper) & (.data[[column]] >=  lower),
      "[u]",
      ""),
    .after = {column}
  )
}


#' Formats the output of `multi_mat_count_rate_agegrp_ew` to publishing-ready
#' single row of data
#'
#' @param data Dataframe output of `multi_mat_count_rate_agegrp_ew`.
#' @param year Numeric or string value of year of data (YYYY).
#'
#' @return Single dataframe row of data for publication.
#' @export
format_multi_mat_count_rate_agegrp <- function(data, year) {

  formatted_data <- data %>%
    dplyr::select(-freq) %>%
    dplyr::filter(agegrp != "age not stated") %>%
    dplyr::mutate(
      agegrp = factor(
        agegrp,
        levels = c("all ages",
                   create_factor_levels()$age_mother[-c(7, 9)]))) %>%
    dplyr::arrange(agegrp, .by_group = TRUE) %>%
    dplyr::rename(
      `Maternities with multiple births` = multi_freq,
      `Rate (maternities with multiple births per 1,000 all maternities)` =
        multibirth_rate) %>%
    tidyr::pivot_wider(
      names_from = agegrp,
      values_from =
        c(`Maternities with multiple births`,
          `Rate (maternities with multiple births per 1,000 all maternities)`),
      names_glue = "{agegrp} {.value}",
      names_sep = " ")

  colnames(formatted_data) <- paste("Mothers", colnames(formatted_data))
  colnames(formatted_data) <- gsub(" Rate", "\nRate", colnames(formatted_data))
  colnames(formatted_data) <- gsub(
    " Maternities", "\nMaternities", colnames(formatted_data))

  dplyr::mutate(formatted_data, Year = year, .before = dplyr::everything())
}

#' Add unreliable columns to maternities with multiple births rate
#'
#' @param data Data frame.
#'
#' @return Data frame with unreliability indicator columns if applicable.
#' @export
unreliable_rate_mat_mulbth <- function(data) {

  prefix <- paste0(
    "Mothers ", c("all ages", create_factor_levels()$age_mother[-c(7, 9)]))

  cols <- paste0(prefix, "\nMaternities with multiple births")
  rate <- "\nRate (maternities with multiple births per 1,000 all maternities)"
  rate_unrel_cols <- c()

  for (i in seq_along(prefix)){
    rate_unrel_cols[(2 * i - 1)] <- paste0(prefix[i], rate)
    rate_unrel_cols[2 * i] <- paste0(prefix[i], rate, "\nUnreliable indicator")
  }

  col_order <- c("Year", cols, rate_unrel_cols)

  names_vec <- setNames(
    paste0(
      "Unreliable indicator ", prefix, "\nMaternities with multiple births"),
    paste0(prefix, rate, "\nUnreliable indicator"))

  create_unreliability_columns(data, columns = cols) %>%
    dplyr::rename(dplyr::any_of(names_vec)) %>%
    dplyr::mutate(dplyr::across((
      dplyr::contains(c("Unrel"))),
      .fns = ~ ifelse(.x != "[u]", NA_character_, "[u]"))) %>%
    janitor::remove_empty("cols") %>%
    dplyr::select(dplyr::any_of(col_order)) %>%
    dplyr::mutate(dplyr::across(-Year, as.character))
}

### Further formatting functions e.g. create_unreliability_col not shown ###
