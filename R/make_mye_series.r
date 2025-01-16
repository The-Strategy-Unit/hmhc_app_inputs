# README
# make a timeseries of area population estimates (0-90+)
# may require reconciling local government changes
# single-year-of-age assumptions:
# all areas in 2000 stop at 85+, we use England pct 85-90+ from 2001 to
# apportion 85+ in 2000
# data on the very old (90-100+) is for England only from 2002, we use England
# 2002 pct to apportion 90+ in 2000-2001

# make mye to 90+ ----
mk_mye_to90 <- function(df) {

  # lad 2001+ 90+
  lad_2001_onw <- df |>
    dplyr::filter(grp == "90 plus", area_code != "E92000001", age != "85+") |>
    dplyr::select(-grp) |>
    dplyr::mutate(age = as.integer(stringr::str_extract(age, "[0-9]+")))

  # lad 2000
  lad_2000 <- df |>
    dplyr::filter(year == 2000L, area_code != "E92000001", age != "85") |>
    dplyr::select(-grp) |>
    dplyr::mutate(age = as.integer(stringr::str_extract(age, "[0-9]+"))) |>
    dplyr::group_by(area_code, year, sex) |>
    tidyr::fill(pop, .direction = "down") |>
    dplyr::ungroup()

  # England 2001 dist 85-90+
  eng_2001 <- df |>
    dplyr::filter(
      year == 2001L,
      area_code == "E92000001",
      age %in% c("85", "86", "87", "88", "89", "90+")
    ) |>
    dplyr::select(-grp) |>
    # reset year
    dplyr::mutate(
      year = 2000L,
      age = as.integer(stringr::str_extract(age, "[0-9]+"))
    ) |>
    dplyr::group_by(year, sex) |>
    dplyr::mutate(total = sum(pop)) |>
    dplyr::group_by(year, sex, age) |>
    dplyr::summarise(pct = pop / total) |>
    dplyr::ungroup()

  # apportion 85+ in 2000 using England pct from 2001
  lad_2000_update <- lad_2000 |>
    dplyr::left_join(eng_2001, dplyr::join_by(year, sex, age)) |>
    dplyr::mutate(
      pop = dplyr::case_when(age < 85 ~ pop, age >= 85 ~ pct * pop)
    ) |>
    dplyr::select(-pct)

  # combine 2000 and 2001+
  dplyr::bind_rows(lad_2000_update, lad_2001_onw)
}

# make mye to 100+ ----
mk_mye_to100 <- function(very_old, mye) {

  vo_pct <- very_old |>
    dplyr::group_by(year, sex) |>
    dplyr::mutate(total = sum(pop)) |>
    dplyr::group_by(year, sex, age) |>
    dplyr::summarise(pct = pop / total)

  mye |>
    dplyr::group_by(area_code, year, sex) |>
    tidyr::complete(
      age = tidyr::full_seq(91:100, 1L), pop = dplyr::last(pop)
    ) |>
    dplyr::left_join(vo_pct, dplyr::join_by(year, sex, age)) |>
    dplyr::group_by(area_code, year, sex) |>
    dplyr::mutate(pop = dplyr::if_else(!is.na(pct), pct * pop, pop)) |>
    dplyr::ungroup() |>
    dplyr::select(-pct) |>
    dplyr::arrange(area_code, year, sex, age)
}

# test ----
# source(here("R/tests", "test_build_historic_pop.R")) # nolint: commented_code_linter, line_length_linter.

# reconcile local government changes ----
# WARNING this can easily become a rabbit hole!
# current mye series has 296 lads matches ONS Apr 2023 - no recon. required
mk_mye_compl <- function(mye, lad23, cty23, icb23) {

  # # compile Countys
  mye_cty <- cty23 |>
    dplyr::left_join(mye, dplyr::join_by(lad23cd == area_code)) |>
    dplyr::group_by(dplyr::across(starts_with("cty")), year, sex, age) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup() |>
    dplyr::rename(area_code = cty23cd, area_name = cty23nm)

  # # compile ICBs
  mye_icb <- icb23 |>
    dplyr::left_join(mye, dplyr::join_by(lad23cd == area_code)) |>
    dplyr::group_by(
      dplyr::across(tidyselect::starts_with("icb"))
      , year, sex, age
    ) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup() |>
    dplyr::rename(area_code = icb23cd, area_name = icb23nm)

  # # compile England
  mye_eng <- mye |>
    dplyr::group_by(year, sex, age) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      area_code = "E92000001",
      area_name = "England",
      .before = tidyselect::everything()
    )

  # combine
  dplyr::bind_rows(mye, mye_cty, mye_icb, mye_eng)
}
