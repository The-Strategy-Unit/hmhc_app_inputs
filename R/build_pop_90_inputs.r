# README
# Build a set of area populations (0-90+) for use in the app and the model
# requires reconciling area codes with local government changes

# build ----


build_90p_inputs <- function(snpp_2018b_custom_vars, snpp_2018b, lookup_lad18_lad23, retired_cty, npp_2018b, lookup_lad23_icb) {

  # remove custom variants that already exist as published snpp variants
  # remove principal (ppp), low migration (ppl), and high migration (pph)
  cus_vars <- snpp_2018b_custom_vars |>
    dplyr::filter(!id %in% c("ppp", "ppl", "pph"))

  # assemble single list with x4 published snpp variants + 15 non-duplicate custom
  # variants, 4 standard variants + 15 custom variants + 1 principal = 20
  app_vars <- snpp_2018b |>
    dplyr::bind_rows(cus_vars)

  # reconcile local government changes ----
  # WARNING this can easily become a rabbit hole!
  # snpp 2018b has 326 lads; this needs to become 296 lads (ONS Apr 2023)
  # snpp 2018b has 27 ctys; this needs to become 21 ctys (ONS Apr 2023)
  
  # districts
  app_vars_lad <- app_vars |>
    # remove all county councils
    dplyr::filter(stringr::str_detect(area_code, "^E10", negate = TRUE)) |>
    dplyr::left_join(lookup_lad18_lad23, dplyr::join_by("area_code" == "lad18cd")) |>
    dplyr::mutate(
      area_code = dplyr::case_when(!is.na(new_ladcd) ~ new_ladcd, TRUE ~ area_code),
      area_name = dplyr::case_when(!is.na(new_ladnm) ~ new_ladnm, TRUE ~ area_name)
    ) |>
    dplyr::select(-tidyselect::starts_with("new"), -yrofchg, -lad18nm) |>
    dplyr::group_by(dplyr::across(-pop)) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup()

  # county councils
  app_vars_cty <- app_vars |>
    dplyr::filter(stringr::str_detect(area_code, "^E10")) |>
    dplyr::anti_join(
      retired_cty, dplyr::join_by("area_code" == "cty18cd")
  )

  # compile England
  app_vars_eng <- npp_2018b |>
    dplyr::select(-area) |>
    dplyr::filter(year <= 2043) |>
    dplyr::mutate(age = dplyr::case_when(age > 90 ~ 90, TRUE ~ as.integer(age))) |>
    dplyr::group_by(dplyr::across(-pop)) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup() |>
    # match id names in snpp
    dplyr::mutate(id = dplyr::case_when(
      id == "ppp" ~ "principal_proj",
      id == "pph" ~ "var_proj_high_intl_migration",
      id == "ppl" ~ "var_proj_low_intl_migration",
      .default = id
    )) |>
    dplyr::mutate(area_code = "E92000001", area_name = "England", .after = "id")

  # compile icbs
  app_vars_icb <- lookup_lad23_icb |>
    dplyr::left_join(app_vars_lad, dplyr::join_by("lad23cd" == "area_code")) |>
    dplyr::group_by(dplyr::across(tidyselect::starts_with("icb")), id, sex, age, year) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup() |>
    dplyr::rename(area_code = icb23cd, area_name = icb23nm)

  # combine
  app_vars_all <- dplyr::bind_rows(app_vars_lad, app_vars_cty, app_vars_icb, app_vars_eng)

}















# test ----
# source(here("R/tests", "test_build_pop_90_inputs.R"))



# used as input to activity rates element in the app
# "app_pop_90_inputs"

# used as input to the model
# app_vars_all |>
#   pivot_wider(names_from = "year", values_from = "pop") |>
#   group_by(area_code, area_name) |>
#   group_walk(\(x, y) {
#     write_rds(x, here("data", "2022", y$area_code, "pop_dat.rds"))
#   })
