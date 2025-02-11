# README
# read life tables from national population projections 2018-based
# nolint start: line_length_linter
# https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/lifeexpectancies/datasets/expectationoflifeprincipalprojectionengland
# https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/lifeexpectancies/datasets/expectationoflifehighlifeexpectancyvariantengland
# https://www.ons.gov.uk/peoplepopulationandcommunity/birthsdeathsandmarriages/lifeexpectancies/datasets/expectationoflifelowlifeexpectancyvariantengland
# nolint end: line_length_linter
# x2 variant life tables were published alongside the principal

# prep ----
prep_life_tbl <- function(path) {

  id <- stringr::str_extract(path, "[a-z]{3}(?=18ex)")

  sheets <- readxl::excel_sheets(path) |>
    stringr::str_subset(pattern = "period|cohort")

  # iterate over sheets
  purrr::map(sheets, \(x) {
    readxl::read_xls(path, x, skip = 9) |>
      dplyr::filter(!dplyr::row_number() == 1L) |>
      dplyr::rename_with(.cols = 1, ~"age") |>
      dplyr::mutate(base = "2018b") |>
      tidyr::pivot_longer(
        cols = `1981`:`2068`,
        names_to = "year",
        values_to = "ex"
      ) |>
      dplyr::mutate(
        sex = tolower(stringr::str_extract(x, "Female|Male")),
        sex = stringr::str_sub(sex, 1L, 1L),
        type = stringr::str_extract(x, "period|cohort"),
        year = as.integer(year)
      )
  }) |>
    # combine sheets
    dplyr::bind_rows() |>
    dplyr::mutate(id = id)
}

life_tbl_csv <- function(df) {
  path <- here::here("data", "life_tables_2018b.csv")
  readr::write_csv(df, path)
  return(path)
}