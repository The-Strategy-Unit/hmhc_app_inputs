# README
# assemble model results i.e., est. percent change in healtchare activity
# between model baseline and model horizon year

# TODO
# treatment of omit hsagrps - maybe create a calling environemnt for running
# the model and include in that so all fns can see it

# functions ---
# get_demographic_chg
# get_hsa_chg

# get_demographic_chg() ----
# change in activity due to changes in population size and age structure
# param: area_code, type: string, ONS geography code
# param: base_year, type: integer, model baseline
# param: end_year, type: integer, model horizon
# param: proj_id, type: string, population projection variant
# returns: a dataframe of modeled activity in end year and percent change from
# base year by hsagrp and sex
# rtype: df
get_demographic_chg <- function(area_code, base_year, end_year, proj_id) {

  path_self <- path_closure(area_code, base_year)

  omit_hsagrps <- tibble::tribble(
    ~ setting, ~ omit,
    "edc", NA_character_,
    "apc", "birth_n",
    "apc", "birth_bds",
    "apc", "mat_n",
    "apc", "mat_bds",
    "apc", "paeds-ordelec_n",
    "apc", "paeds-ordelec_bds",
    "apc", "paeds-emer_n",
    "apc", "paeds-emer_bds",
    "opc", NA_character_
  )

  act <- load_activity_data(area_code, base_year) |>
    dplyr::filter(!hsagrp %in% omit_hsagrps$omit)

  # add end year
  act <- act |>
    dplyr::mutate(end_year = end_year)

  demo_fac <- create_demographic_factors(
    area_code, base_year, end_year, proj_id
  )

  act |>
    dplyr::left_join(demo_fac, dplyr::join_by(sex, age)) |>
    dplyr::mutate(end_n = n * demo_fac) |>
    dplyr::group_by(area_code, id, end_year, setting, hsagrp, sex) |>
    dplyr::summarise(base_n = sum(n), end_n = sum(end_n)) |>
    dplyr::ungroup() |>
    dplyr::arrange(hsagrp, sex)
}

# get_hsa_chg() ----
# change in activity due to changes in population + adjustement for changes in
# health status
# param: area_code, type: string, ONS geography code
# param: base_year, type: integer, model baseline
# param: end_year, type: integer, model horizon
# param: proj_id, type: string, population projection variant
# param: model_runs, type: integer, number of times to run model
# param: rng_state, type: integer vector, RNG state
# param: method, type: string, method for obtaining modeled activity rates for
# hsa ages, either 'interp' or 'gams'
# param: mode, type: bool, monte carlo or modal value
# returns: a dataframe with a list column of modeled activity in end year by
# hsagrp and sex
# rtype: df (end_n = vector, length = model runs)
get_hsa_chg <- function(
  area_code,
  base_year,
  end_year,
  proj_id,
  model_runs,
  rng_state,
  method = c("interp", "gams"),
  mode = FALSE
) {

  method <- rlang::arg_match(method, values = c("interp", "gams"))

  path_self <- path_closure(area_code, base_year)

  omit_hsagrps <- tibble::tribble(
    ~ setting, ~ omit,
    "edc", NA_character_,
    "apc", "birth_n",
    "apc", "birth_bds",
    "apc", "mat_n",
    "apc", "mat_bds",
    "apc", "paeds-ordelec_n",
    "apc", "paeds-ordelec_bds",
    "apc", "paeds-emer_n",
    "apc", "paeds-emer_bds",
    "opc", NA_character_
  )

  act <- load_activity_data(area_code, base_year) |>
    dplyr::filter(!hsagrp %in% omit_hsagrps$omit)

  # add end year
  act <- act |>
    dplyr::mutate(end_year = end_year)

  demo_fac <- create_demographic_factors(
    area_code, base_year, end_year, proj_id
  )

  hsa_fac <- get_hsa_factors(
    area_code, base_year, end_year, proj_id, model_runs, rng_state,
    method = method, mode = mode
  )

  if (isTRUE(mode)) {
    x <- act |>
      dplyr::left_join(
        demo_fac,
        dplyr::join_by(sex, age)
      ) |>
      dplyr::left_join(
        hsa_fac,
        dplyr::join_by(area_code, id, end_year, setting, hsagrp, sex, age)
      ) |>
      # replace missing hsa factors (NA values) with 1
      dplyr::mutate(f = dplyr::if_else(is.na(f), 1, f)) |>
      dplyr::mutate(f = f * demo_fac) |>
      dplyr::mutate(end_n = n * f) |>
      dplyr::select(area_code, id, end_year, setting, hsagrp, sex, age, n, end_n) |>
      dplyr::group_by(area_code, id, end_year, setting, hsagrp, sex) |>
      tidyr::nest(.key = "data") |>
      dplyr::ungroup() |>
      dplyr::mutate(
        base_n = purrr::map_dbl(
          data, \(x) {
            sum(x$n)
          }
        )
      ) |>
      dplyr::mutate(
        end_n = purrr::map_dbl(
          data, \(x) {
            sum(x$end_n)
          }
        )
      ) |>
      dplyr::mutate(end_p = end_n / base_n) |>
      dplyr::select(area_code, id, end_year, setting, hsagrp, sex, base_n, end_n)

  } else {

    x <- act |>
      dplyr::left_join(
        demo_fac,
        dplyr::join_by(sex, age)
      ) |>
      dplyr::left_join(
        hsa_fac,
        dplyr::join_by(area_code, id, end_year, setting, hsagrp, sex, age)
      ) |>
      # replace missing hsa factors (empty lists) with 1
      dplyr::mutate(
        f = purrr::map_if(
          f,
          # predicate function
          .p = \(x) length(x) == 0,
          # where .p evaluates to TRUE then
          .f = \(x) c(rep(1, model_runs))
        )
      ) |>
      dplyr::mutate(
        f = purrr::map2(
          f, demo_fac, \(x, y) {
            x * y
          }
        )
      ) |>
      dplyr::mutate(
        end_n = purrr::map2(
          n, f, \(x, y) {
            x * y
          }
        )
      ) |>
      dplyr::select(area_code, id, end_year, setting, hsagrp, sex, age, n, end_n) |>
      dplyr::group_by(area_code, id, end_year, setting, hsagrp, sex) |>
      tidyr::nest(.key = "data") |>
      dplyr::ungroup() |>
      dplyr::mutate(
        base_n = purrr::map_dbl(
          data, \(x) {
            sum(x$n)
          }
        )
      ) |>
      dplyr::mutate(
        end_n = purrr::map(
          data, \(x) {
            rowSums(sapply(x$end_n, unlist))
          }
        )
      ) |>
      dplyr::mutate(
        end_p = purrr::map2(
          base_n, end_n, \(x, y) {
            y / x
          }
        )
      ) |>
      dplyr::select(area_code, id, end_year, setting, hsagrp, sex, base_n, end_n)
  }

  return(x)
}
