# README
# Read national population projections 2018-based
# https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationprojections/bulletins/nationalpopulationprojections/2018based # nolint: line_length_linter.
# x17 variant projections were published alongside the principal

# dark arts ----
# files provided with xml extension
# this fn runs a powershell script to change the extension to xls
# only need to run once
change_file_ext <- function(x) {
  system2("powershell", args = c("-file", x))
}
# change_file_ext("cmd_line_dark_arts.ps1") # nolint: commented_code_linter.

# prep ----
prep_npp <- function(path) {

  id <- stringr::str_extract(path, "(?<=npp_2018b/).*(?=_opendata)")

  df <- readxl::read_xls(path, sheet = "Population") |>
    dplyr::rename_all(tolower) |>
    tidyr::pivot_longer(
      cols = `2018`:`2118`,
      names_to = "year",
      values_to = "pop"
    ) |>
    dplyr::mutate(
      id = stringr::str_remove(id, "en_"),
      age = stringr::str_trim(age),
      area = "England",
      sex = dplyr::if_else(sex == "1", "m", "f")
    ) |>
    dplyr::mutate(
      age = dplyr::case_when(
        age %in% c("105 - 109", "110 and over") ~ "105",
        TRUE ~ as.character(age)
      )
    ) |>
    dplyr::mutate(
      dplyr::across(c(age, year), as.integer)
    )

  # regroup by age
  df |>
    dplyr::group_by(dplyr::across(-pop)) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup()
}

# variant codes ----
prep_npp_codes <- function(pathin, pathout) {
  readr::read_lines(pathin) |>
    tibble::as_tibble() |>
    dplyr::filter(stringr::str_detect(value, "^[a-z]{3}:")) |>
    tidyr::separate(value, c("proj_cd", "proj_nm"), ": ") |>
    dplyr::mutate(proj_cd = stringr::str_c("en_", proj_cd)) |>
    readr::write_csv(pathout)
}
