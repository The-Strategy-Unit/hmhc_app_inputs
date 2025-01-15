# README
# Read-in population estimates of the very old including centenarians
# https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/ageing/datasets/midyearpopulationestimatesoftheveryoldincludingcentenariansengland # nolint: line_length_linter.
# Data is missing for 2000 and 2001 - we impute using data for 2002.
# We use the distribution for ages 90-100+ for England to approximate the
# distribution in local areas. The only place this is used is to determine the
# length of bars in the population pyramid. For modeling, the upper age group is
# 90+, any higher and the variation in activity rates becomes excessive.

# read ----
read_very_old <- function(filenm, skip = 3, n_max = 70) {
  readr::read_csv(
    filenm,
    skip = skip,
    n_max = n_max,
  )
}

# process ----
process_very_old <- function(df) {
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
    # check males first
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
    dplyr::mutate(across(c("year", "age"), as.integer))
}

# impute missing data ----
# no data for 2000 and 2001 - impute using data for 2002
impute_very_old <- function(df) {
  df |>
    dplyr::group_by(sex, age) |>
    tidyr::complete(
      year = tidyr::full_seq(2000:2001, 1L),
      pop = dplyr::first(pop)
    ) |>
    dplyr::ungroup()
}
