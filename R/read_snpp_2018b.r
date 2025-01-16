# README
# read sub-national population projections 2018-based
# https://www.ons.gov.uk/releases/subnationalpopulationprojectionsforengland2018based # nolint: line_length_linter.
# x4 variant projections were published alongside the principal

# prep ----
prep_snpp <- function(path) {

  id <- stringr::str_match(path, "2018b_(.*?)/2018")[, 2]

  readr::read_csv(path) |>
    dplyr::rename_all(tolower) |>
    tidyr::pivot_longer(
      cols = `2018`:`2043`,
      names_to = "year",
      values_to = "pop"
    ) |>
    dplyr::filter(age_group != "All ages") |>
    dplyr::select(-component) |>
    dplyr::mutate(sex = stringr::str_sub(sex, 1L, 1L)) |>
    # remove metropolitan counties and regions (keep only local authorities)
    dplyr::filter(stringr::str_detect(area_code, "^E11|^E12", negate = TRUE)) |>
    dplyr::mutate(
      age_group = dplyr::case_match(age_group,
        "90 and over" ~ "90",
        .default = age_group
      )
    ) |>
    dplyr::mutate(dplyr::across(c(age_group, year), as.integer)) |>
    dplyr::rename(age = age_group) |>
    dplyr::mutate(id = id)
}
