# README
# Build a timeseries of area population estimates (0-90+)
# Requires reconciling area codes with local government changes

# syoa fixes:
# all areas in 2000 are 85+, we use England 85-90+ to apportion
# very old (90-100+) only for England from 2002, we use to apportion LAD 90+ for
# 2000-2001


# get mye 90+ ----
get_mye_90p <- function(df) {

  # LADs 2001+ 90+
  lad_2001p <- df |>
    dplyr::filter(grp == "90plus", area_code != "E92000001", age != "85+") |>
    dplyr::select(-grp) |>
    dplyr::mutate(age = as.integer(stringr::str_extract(age, "[0-9]+")))

  # LADs 2000
  lad_2000 <- df |>
    dplyr::filter(year == 2000L, area_code != "E92000001", age != "85") |>
    dplyr::select(-grp) |>
    dplyr::mutate(age = as.integer(stringr::str_extract(age, "[0-9]+"))) |>
    dplyr::group_by(area_code, year, sex) |>
    tidyr::fill(pop, .direction = "down") |>
    dplyr::ungroup()

  # England 2001 distribution 85-90+
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

  # apportion LADs 85+ using England shares
  lad_2000_fixed <- lad_2000 |>
    dplyr::left_join(eng_2001, dplyr::join_by(year, sex, age)) |>
    dplyr::mutate(
      pop = dplyr::case_when(age < 85 ~ pop, age >= 85 ~ pct * pop)
    ) |>
    dplyr::select(-pct)

  # combine 2000 and 2001+
  dplyr::bind_rows(lad_2000_fixed, lad_2001p)
}

# get mye 100+ ----
get_mye_100p <- function(df_vo, df_mye) {

  vo_pct <- df_vo |>
    dplyr::group_by(year, sex) |>
    dplyr::mutate(total = sum(pop)) |>
    dplyr::group_by(year, sex, age) |>
    dplyr::summarise(pct = pop / total)

  df_mye |>
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
# source(here("R/tests", "test_build_historic_pop.R"))

# reconcile local government changes ----
# WARNING this can easily become a rabbit hole!
# historic mye timseries has 309 lads - map to 296 lads (ONS Apr 2023)
get_mye_series <- function(mye_100p, lookup_lad18_lad23, lad23, cty23, icb23) {

  # compile LADs
  mye_lad <- mye_100p
    # redundant with NEW data from NOMIS that uses April 2023 codes
    # dplyr::left_join(
    #   lookup_lad18_lad23,
    #   dplyr::join_by(area_code == lad18cd)
    # ) |>
    # dplyr::mutate(
    #   area_code = dplyr::case_when(
    #     !is.na(new_ladcd) ~ new_ladcd,
    #     TRUE ~ area_code
    #   )
    # ) |>
    # dplyr::select(-tidyselect::contains("lad"), -yrofchg) |>
    # dplyr::group_by(dplyr::across(-pop)) |>
    # dplyr::summarise(pop = sum(pop, na.rm = TRUE)) |>
    # dplyr::ungroup() |>
    # # pull area name
    # dplyr::left_join(lad23, dplyr::join_by("area_code" == "lad23cd")) |>
    # dplyr::rename(area_name = lad23nm) |>
    # dplyr::select(area_code, area_name, tidyselect::everything())

  # # compile Countys
  mye_cty <- cty23 |>
    dplyr::left_join(mye_lad, dplyr::join_by(lad23cd == area_code)) |>
    dplyr::group_by(dplyr::across(starts_with("cty")), year, sex, age) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup() |>
    dplyr::rename(area_code = cty23cd, area_name = cty23nm)

  # # compile ICBs
  mye_icb <- icb23 |>
    dplyr::left_join(mye_lad, dplyr::join_by(lad23cd == area_code)) |>
    dplyr::group_by(
      dplyr::across(tidyselect::starts_with("icb"))
      , year, sex, age
    ) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup() |>
    dplyr::rename(area_code = icb23cd, area_name = icb23nm)

  # # compile England
  mye_eng <- mye_lad |>
    dplyr::group_by(year, sex, age) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      area_code = "E92000001",
      area_name = "England",
      .before = tidyselect::everything()
    )

  # combine
  dplyr::bind_rows(mye_lad, mye_cty, mye_icb, mye_eng)
}
