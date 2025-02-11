# README
# read administrative geography names and codes
# sourced from ONS Open Geography Portal https://geoportal.statistics.gov.uk/

# read lad codes ----
# 2018
read_lad18 <- function(path) {
  readr::read_csv(path) |>
    dplyr::filter(stringr::str_detect(LAD18CD, "E[0-1][6-9]")) |>
    dplyr::select(-LAD18NMW, -FID) |>
    dplyr::rename_with(tolower)
}

lad18_csv <- function(df) {
  path <- here::here("data", "local_authority_districts_2018.csv")
  readr::write_csv(df, path)
  return(path)
}

# 2022
read_lad22 <- function(path) {
  readr::read_csv(path) |>
    dplyr::filter(stringr::str_detect(LAD22CD, "E[0-1][6-9]")) |>
    dplyr::select(-LAD22NMW, -ObjectId) |>
    dplyr::rename_with(tolower)
}

lad22_csv <- function(df) {
  path <- here::here("data", "local_authority_districts_2022.csv")
  readr::write_csv(df, path)
  return(path)
}

# 2023
read_lad23 <- function(path) {
  readr::read_csv(path) |>
    dplyr::filter(stringr::str_detect(LAD23CD, "E[0-1][6-9]")) |>
    dplyr::select(-LAD23NMW, -ObjectId) |>
    dplyr::rename_with(tolower)
}

lad23_csv <- function(df) {
  path <- here::here("data", "local_authority_districts_2023.csv")
  readr::write_csv(df, path)
  return(path)
}

# read county codes ----
# 2018
read_cty18 <- function(path) {
  readr::read_csv(path) |>
    dplyr::filter(stringr::str_detect(CTY18CD, "^E10")) |>
    dplyr::select(-FID) |>
    dplyr::rename_with(tolower)
}

cty18_csv <- function(df) {
  path <- here::here("data", "lookup_lad2018_cty.csv")
  readr::write_csv(df, path)
  return(path)
}

# 2022
read_cty22 <- function(path) {
  readr::read_csv(path) |>
    dplyr::filter(stringr::str_detect(CTY22CD, "^E10")) |>
    dplyr::select(-ObjectId) |>
    dplyr::rename_with(tolower)
}

cty22_csv <- function(df) {
  path <- here::here("data", "lookup_lad2022_cty.csv")
  readr::write_csv(df, path)
  return(path)
}

# 2023
read_cty23 <- function(path) {
  readr::read_csv(path) |>
    dplyr::filter(stringr::str_detect(CTY23CD, "^E10")) |>
    dplyr::select(-ObjectId) |>
    dplyr::rename_with(tolower)
}

cty23_csv <- function(df) {
  path <- here::here("data", "lookup_lad2023_cty.csv")
  readr::write_csv(df, path)
  return(path)
}

# get retired countys ----
get_retired_ctys <- function(cty18, cty23) {

  retired <- dplyr::setdiff(cty18$cty18cd, cty23$cty23cd)

  cty18 |>
    dplyr::filter(
      stringr::str_detect(cty18cd, stringr::str_c(retired, collapse = "|"))
    ) |>
    dplyr::distinct(cty18cd, cty18nm)
}

retired_ctys_csv <- function(df) {
  path <- here::here("data", "retired_ctys_2018_2023.csv")
  readr::write_csv(df, path)
  return(path)
}
