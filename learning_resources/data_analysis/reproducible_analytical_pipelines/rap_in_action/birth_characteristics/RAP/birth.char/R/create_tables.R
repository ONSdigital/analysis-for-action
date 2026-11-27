#' Multiple birth counts and rate by mothers age group (England and Wales)
#'
#' @description Uses processed births registrations for England and Wales to
#' create counts of multiple births and multibirth rate by mothers age group.
#'
#' @param data Processed birth dataframe (registrations) for a single year.
#'
#' @return Dataframe of multiple births and rates per mothers age group for a
#' single year.
#' @export
#'
multi_mat_count_rate_agegrp_ew <- function(data) {

  all_single_births <- data %>%
    dplyr::filter(mattab == 1) %>%
    cut_mothers_age_45() %>%
    dplyr::mutate(
      single_birth = ifelse(multibirth == "Single birth", "single", "multi"))

  all_single_births %>%
    dplyr::filter(single_birth == "multi") %>%
    plyr::count("agegrp") %>%
    dplyr::rename(multi_freq = freq) %>%
    dplyr::full_join(plyr::count(all_single_births, "agegrp"),
                     by = "agegrp") %>%
    dplyr::mutate_if(is.numeric, tidyr::replace_na, replace = 0) %>%
    janitor::adorn_totals("row", name = "all ages") %>%
    calc_multibirth_rate()
}
