# README
# Read-in local authority district lists and lookups from ONS Open Geography
# Portal https://geoportal.statistics.gov.uk/

# read ONS codes ----
read_lad18 <- function(filenm_in, filenm_out) {
  readr::read_csv(filenm_in) |>
    dplyr::filter(stringr::str_detect(LAD18CD, "E[0-1][6-9]")) |>
    dplyr::select(-LAD18NMW, -FID) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(here::here("data", filenm_out))
}

read_lad22 <- function(filenm_in, filenm_out) {
  readr::read_csv(filenm_in) |>
    dplyr::filter(stringr::str_detect(LAD22CD, "E[0-1][6-9]")) |>
    dplyr::select(-LAD22NMW, -ObjectId) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(here::here("data", filenm_out))
}

read_lad23 <- function(filenm_in, filenm_out) {
  readr::read_csv(filenm_in) |>
    dplyr::filter(stringr::str_detect(LAD23CD, "E[0-1][6-9]")) |>
    dplyr::select(-LAD23NMW, -ObjectId) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(here::here("data", filenm_out))
}

read_cty18 <- function(filenm_in, filenm_out) {
  readr::read_csv(filenm_in) |>
    dplyr::filter(stringr::str_detect(CTY18CD, "^E10")) |>
    dplyr::select(-FID) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(here::here("data", filenm_out))
}

read_cty22 <- function(filenm_in, filenm_out) {
  readr::read_csv(filenm_in) |>
    dplyr::filter(stringr::str_detect(CTY22CD, "^E10")) |>
    dplyr::select(-ObjectId) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(here::here("data", filenm_out))
}

read_cty23 <- function(filenm_in, filenm_out) {
  readr::read_csv(filenm_in) |>
    dplyr::filter(stringr::str_detect(CTY23CD, "^E10")) |>
    dplyr::select(-ObjectId) |>
    dplyr::rename_with(tolower) |>
    readr::write_csv(here::here("data", filenm_out))
}

# get retired countys ----
get_retired_ctys <- function(old_ctys, cur_ctys, filenm_out) {
  retired <- dplyr::setdiff(old_ctys$cty18cd, cur_ctys$cty23cd)

  retired_cty <- old_ctys |>
    dplyr::filter(
      stringr::str_detect(cty18cd, stringr::str_c(retired, collapse = "|"))
    ) |>
    dplyr::distinct(cty18cd, cty18nm) |>
    readr::write_csv(here::here("data", filenm_out))
}
