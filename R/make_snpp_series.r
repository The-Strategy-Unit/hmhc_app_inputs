# README
# make a set of area population projections (0-90+) for use by the app
# requires reconciling local government changes

# make snpp series ----
mk_snpp_series <- function(
  snpp_custom_vars,
  snpp,
  lookup_lad18_lad23,
  retired_cty,
  npp,
  lookup_icb
) {

  # remove custom variants that already exist as published snpp variants
  # remove principal (ppp), low migration (ppl), and high migration (pph)
  keep_custom_vars <- snpp_custom_vars |>
    dplyr::filter(!id %in% c("ppp", "ppl", "pph"))

  # assemble df with x4 published snpp variants + 15 non-duplicate custom
  # variants, (4 + 15 + principal = 20)
  all_vars <- snpp |>
    dplyr::bind_rows(keep_custom_vars)

  # reconcile local government changes ----
  # WARNING this can easily become a rabbit hole!
  # snpp 2018b has 326 lads; this needs to become 296 lads (ONS Apr 2023)
  # snpp 2018b has 27 ctys; this needs to become 21 ctys (ONS Apr 2023)

  # lads
  all_vars_lad <- all_vars |>
    # remove all county councils
    dplyr::filter(
      stringr::str_detect(area_code, "^E10", negate = TRUE)
    ) |>
    dplyr::left_join(
      lookup_lad18_lad23,
      dplyr::join_by("area_code" == "lad18cd")
    ) |>
    dplyr::mutate(
      area_code = dplyr::case_when(
        !is.na(new_ladcd) ~ new_ladcd,
        TRUE ~ area_code
      ),
      area_name = dplyr::case_when(
        !is.na(new_ladnm) ~ new_ladnm,
        TRUE ~ area_name
      )
    ) |>
    dplyr::select(
      -tidyselect::starts_with("new"), -yrofchg, -lad18nm
    ) |>
    dplyr::group_by(dplyr::across(-pop)) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup()

  # countys
  all_vars_cty <- all_vars |>
    dplyr::filter(
      stringr::str_detect(area_code, "^E10")
    ) |>
    dplyr::anti_join(
      retired_cty,
      dplyr::join_by("area_code" == "cty18cd")
    )

  # compile England
  all_vars_eng <- npp |>
    dplyr::select(-area) |>
    dplyr::filter(year <= 2043) |>
    dplyr::mutate(
      age = dplyr::case_when(
        age > 90 ~ 90,
        TRUE ~ as.integer(age)
      )
    ) |>
    dplyr::group_by(dplyr::across(-pop)) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup() |>
    # match id names in snpp
    dplyr::mutate(
      id = dplyr::case_when(
        id == "ppp" ~ "principal_proj",
        id == "pph" ~ "var_proj_high_intl_migration",
        id == "ppl" ~ "var_proj_low_intl_migration",
        .default = id
      )
    ) |>
    dplyr::mutate(
      area_code = "E92000001",
      area_name = "England",
      .after = "id"
    )

  # compile icbs
  all_vars_icb <- lookup_icb |>
    dplyr::left_join(
      all_vars_lad,
      dplyr::join_by("lad23cd" == "area_code")
    ) |>
    dplyr::group_by(
      dplyr::across(
        tidyselect::starts_with("icb")
      ), id, sex, age, year
    ) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup() |>
    dplyr::rename(area_code = icb23cd, area_name = icb23nm)

  # combine
  dplyr::bind_rows(
    all_vars_lad,
    all_vars_cty,
    all_vars_icb,
    all_vars_eng
  )
}

# snpp_to_dirs ----
snpp_to_dirs <- function(df, dir_yyyy) {
  df |>
    tidyr::pivot_wider(names_from = "year", values_from = "pop") |>
    readr::write_rds(
      here::here("data", dir_yyyy, df$area_code[[1]], "pop_snpp_dat.rds")
    )
}

# test ----
# source(here("R/tests", "test_build_pop_90_inputs.R")) # nolint: commented_code_linter, line_length_linter.
