# README
# Read-in 2018-based national population projections
# x17 variant projections were published alongside the principal

# xxxx ----
change_file_ext <- function(x) {
  system2("powershell", args = c("-file", x))
}
# only need to run this once to change file extension
# change_file_ext("cmd_line_dark_arts.ps1")

# process ----
process_npp <- function(npp_path) {

  id <- stringr::str_extract(npp_path, "(?<=npp_2018b/).*(?=_opendata)")

  df <- readxl::read_xls(npp_path, sheet = "Population") |>
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
    dplyr::mutate(across(c(age, year), as.integer))
  
  # regroup by age
  df <- df |>
    dplyr::group_by(across(-pop)) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup()
}

# read npp variant codes ----
process_npp_codes <- function(filenm_in, filenm_out) {
  readr::read_lines(filenm_in) |>
    tibble::as_tibble() |>
    dplyr::filter(stringr::str_detect(value, "^[a-z]{3}:")) |>
    tidyr::separate(value, c("proj_cd", "proj_nm"), ": ") |>
    dplyr::mutate(proj_cd = stringr::str_c("en_", proj_cd)) |>
    readr::write_csv(here::here("data", filenm_out))
}
