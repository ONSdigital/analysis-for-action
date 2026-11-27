#' Add yearly backseries to data
#'
#' @description Binds the backseries data below the current year data (has a
#' column for "Year" which is descending). Or binds the backseries to the right
#' of the current year data where columns of year descend to the right and the
#' rows are "Date" if specified.
#'
#' @details If the current `year` of data already exists in the backseries, will
#' error.
#'
#' @param data Data frame of current year data.
#' @param drive_name String of name of drive where backseries data is stored.
#' @param file_name String of csv file name.
#' @param year Numeric value of current year of data (YYYY).
#' @param date_col Boolean (TRUE or FALSE) for whether the backseries needs to
#' be joined onto the right of the current data using the Date column (i.e. rows
#' contain days of the year, not `Years`). Default is FALSE.
#'
#' @return Data frame.
#' @export
#'
add_backseries <- function(data,
                           drive_name,
                           file_name,
                           year,
                           date_col = FALSE) {

  if (isFALSE(date_col)) {
    backseries <- readr::read_csv(
      file.path(drive_name, file_name), show_col_types = FALSE)
    if (sum(backseries$Year == year) > 0) {
      stop(paste("Backseries data already contains the row for year to add. It",
                 "would be duplicated."))
    }

    backseries %>%
      dplyr::bind_rows(data) %>%
      dplyr::arrange(dplyr::desc(Year))
  } else if (isTRUE(date_col)) {
    backseries <- readr::read_csv(
      file.path(drive_name, file_name), show_col_types = FALSE)
    if (as.character(year) %in% colnames(backseries)) {
      stop(paste("Backseries data already contains the column of the year to",
                 "add. It would be duplicated"))
    }

    backseries %>%
      dplyr::left_join(data, by = dplyr::join_by(Date)) %>%
      dplyr::relocate(as.character(year), .after = Date)
  } else {
    stop("date_col argument must be TRUE or FALSE")
  }
}
