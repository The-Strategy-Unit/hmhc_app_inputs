# README
# read administrative geography names and codes
# sourced from ONS Open Geography Portal https://geoportal.statistics.gov.uk/

# read lad codes ----
# 2018
read_lad18 <- function(pathin, pathout) {
  readr::read_csv(pathin) |>
    dplyr::filter(stringr::str_detect(LAD18CD, "E[0-1][6-9]")) |>
    dplyr::select(-LAD18NMW, -FID) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(pathout)
}

# 2022
read_lad22 <- function(pathin, pathout) {
  readr::read_csv(pathin) |>
    dplyr::filter(stringr::str_detect(LAD22CD, "E[0-1][6-9]")) |>
    dplyr::select(-LAD22NMW, -ObjectId) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(pathout)
}

# 2023
read_lad23 <- function(pathin, pathout) {
  readr::read_csv(pathin) |>
    dplyr::filter(stringr::str_detect(LAD23CD, "E[0-1][6-9]")) |>
    dplyr::select(-LAD23NMW, -ObjectId) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(pathout)
}

# read county codes ----
# 2018
read_cty18 <- function(pathin, pathout) {
  readr::read_csv(pathin) |>
    dplyr::filter(stringr::str_detect(CTY18CD, "^E10")) |>
    dplyr::select(-FID) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(pathout)
}

# 2022
read_cty22 <- function(pathin, pathout) {
  readr::read_csv(pathin) |>
    dplyr::filter(stringr::str_detect(CTY22CD, "^E10")) |>
    dplyr::select(-ObjectId) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(pathout)
}

# 2023
read_cty23 <- function(pathin, pathout) {
  readr::read_csv(pathin) |>
    dplyr::filter(stringr::str_detect(CTY23CD, "^E10")) |>
    dplyr::select(-ObjectId) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(pathout)
}

# get retired countys ----
get_retired_ctys <- function(cty18, cty23, pathout) {

  retired <- dplyr::setdiff(cty18$cty18cd, cty23$cty23cd)

  cty18 |>
    dplyr::filter(
      stringr::str_detect(cty18cd, stringr::str_c(retired, collapse = "|"))
    ) |>
    dplyr::distinct(cty18cd, cty18nm) |>
    readr::write_csv(pathout)
}
