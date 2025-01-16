# README
# Read-in mid-year population estimates for years 2000 to 2023
# https://www.nomisweb.co.uk
# MYE for 2000 are 0-85+. We use England numbers from 2001 to apportion 85+
# population in 2000 to ages 85-90+.

# read LADs ----
process_mye_lad <- function(filenm, skip = 6, na = c("", NA, "-")) {

  start_year <- 1991
  end_year   <- 2023
  grp_85plus <- start_year:2000
  grp_90plus <- 2001:end_year

  readr::read_csv(filenm, skip = skip, na = na) |>
    dplyr::rename(
      area_name = Area,
      area_code = mnemonic,
      all_ages = `All Ages`,
      row_id = row
    ) |>
    dplyr::filter(
      !is.na(area_name),
      stringr::str_detect(area_code, "^E0|^E92")
    ) |>
    dplyr::mutate(row_id = as.integer(row_id)) |>
    dplyr::mutate(
      tbl_id = cumsum(row_id == 1),
      year = dplyr::if_else(tbl_id %% 2 == 1, (tbl_id + 1) / 2, tbl_id / 2),
      year = year + start_year - 1,
      sex = dplyr::if_else(tbl_id %% 2 == 1, "m", "f"),
    ) |>
    dplyr::select(-c(row_id, tbl_id, area_name, all_ages)) |>
    tidyr::pivot_longer(
      tidyselect::starts_with("Age"),
      names_to = "age",
      values_to = "pop"
    ) |>
    dplyr::mutate(age = stringr::str_extract(age, "[0-9].*$")) |>
    dplyr::mutate(
      across(c("year"), as.integer),
      pop = as.double(pop)
    ) |>
    dplyr::mutate(
      grp = dplyr::case_when(
        year %in% grp_85plus ~ "85plus",
        year %in% grp_90plus ~ "90plus"
      )
    )
}
