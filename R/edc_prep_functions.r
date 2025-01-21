# README
# prepare ED data

# prep_edc() -----
prep_edc <- function(
  df, lookup_lad18_lad23, df_icb23, df_raw_cty23, df_raw_lad23
) {

  df <- df |>
    tidyr::drop_na() |>
    dplyr::filter(
      stringr::str_detect(lacd, "^(?:E10|E0[6-9])")
    ) |>
    # set upper age group to 90+
    dplyr::mutate(
      age = dplyr::case_when(
        age >= 90 ~ 90,
        TRUE ~ as.double(age)
      )
    ) |>
    dplyr::rename(area_code = lacd, hsagrp = arrmode) |>
    dplyr::mutate(dplyr::across(c(age, n), as.integer)) |>
    dplyr::group_by(area_code, setting, hsagrp, sex, age) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::ungroup()

  # reconcile local government changes
  # WARNING this can easily become a rabbit hole!
  # edc in 2022 has 313 lads - map to 296 lads (ONS Apr 2023)
  df_lad <- df |>
    # make explicit any missing sex/age combinations
    # by hsagrp in all areas
    tidyr::complete(
      area_code, setting, hsagrp,
      tidyr::nesting(sex, age),
      fill = list(n = NA),
      explicit = FALSE
    ) |>
    # lookup most recent lad codes
    dplyr::left_join(
      lookup_lad18_lad23,
      dplyr::join_by(area_code == lad18cd)
    ) |>
    dplyr::mutate(
      area_code = dplyr::case_when(
        !is.na(new_ladcd) ~ new_ladcd,
        TRUE ~ area_code
      )
    ) |>
    dplyr::select(-tidyselect::contains("lad"), -yrofchg) |>
    dplyr::group_by(dplyr::across(-n)) |>
    dplyr::summarise(n = sum(n, na.rm = TRUE)) |>
    dplyr::ungroup() |>
    # fetch area name
    dplyr::left_join(
      df_raw_lad23,
      dplyr::join_by(area_code == lad23cd)
    ) |>
    dplyr::rename(area_name = lad23nm) |>
    dplyr::select(area_code, area_name, tidyselect::everything())

  # compile Countys
  df_cty <- df_raw_cty23 |>
    dplyr::left_join(
      df_lad,
      dplyr::join_by("lad23cd" == "area_code")
    ) |>
    dplyr::group_by(
      dplyr::across(
        tidyselect::starts_with("cty")
      ),
      setting, hsagrp, sex, age
    ) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::ungroup() |>
    dplyr::rename(area_code = cty23cd, area_name = cty23nm)

  # compile ICBs
  df_icb <- df_icb23 |>
    dplyr::left_join(
      df_lad,
      dplyr::join_by("lad23cd" == "area_code")
    ) |>
    dplyr::group_by(
      dplyr::across(
        tidyselect::starts_with("icb")
      ),
      setting, hsagrp, sex, age
    ) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::ungroup() |>
    dplyr::rename(area_code = icb23cd, area_name = icb23nm)

  # compile England
  df_eng <- df_lad |>
    dplyr::group_by(setting, hsagrp, sex, age) |>
    dplyr::summarise(n = sum(n)) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      area_code = "E92000001",
      area_name = "England",
      .before = tidyselect::everything()
    )

  dplyr::bind_rows(df_lad, df_cty, df_icb, df_eng)
}

# edc_to_dirs ----
edc_to_dirs <- function(df) {
  readr::write_rds(
    df, here::here("data", "2022", df$area_code[[1]], "edc_dat.rds")
  )
}