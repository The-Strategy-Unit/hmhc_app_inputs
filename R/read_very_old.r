# README
# read population estimates of the very old including centenarians
# https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/ageing/datasets/midyearpopulationestimatesoftheveryoldincludingcentenariansengland # nolint: line_length_linter.
# data is missing for 2000 and 2001 - we impute using data from 2002

# read ----
read_very_old <- function(path, skip = 3, n_max = 70) {
  readr::read_csv(
    path,
    skip = skip,
    n_max = n_max,
  )
}

# prep ----
prep_very_old <- function(df) {
  clean_very_old(df) |>
    impute_very_old()
}

# clean ---
clean_very_old <- function(df) {
  df |>
    # first column is blank
    dplyr::select(-1) |>
    dplyr::rename(year = 1) |>
    dplyr::filter(!is.na(year)) |>
    # identify male and female
    dplyr::mutate(tbl_id = cumsum(year == 2002)) |>
    dplyr::filter(tbl_id %in% c(2, 3)) |>
    # check males listed first
    dplyr::mutate(sex = dplyr::if_else(tbl_id == 2L, "m", "f")) |>
    dplyr::select(
      year, sex, dplyr::starts_with("9"), `100 & over`,
      -c(`90 & over`, `90-99`)
    ) |>
    dplyr::rename(`100` = `100 & over`) |>
    tidyr::pivot_longer(
      matches("[1,9]"),
      names_to = "age",
      values_to = "pop"
    ) |>
    dplyr::mutate(dplyr::across(c("year", "age"), as.integer))
}

# impute missing years ----
# no data for 2000 and 2001 - impute using data from 2002
impute_very_old <- function(df) {
  df |>
    dplyr::group_by(sex, age) |>
    tidyr::complete(
      year = tidyr::full_seq(2000:2001, 1L),
      pop = dplyr::first(pop)
    ) |>
    dplyr::ungroup()
}
