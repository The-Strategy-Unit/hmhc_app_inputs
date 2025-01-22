# README
# assemble model results i.e., est. percent change in healtchare activity
# between model baseline and model horizon year


# get_demographic_chg() - treatment of omit hsagrps - create calling environemnt when run all this grp and incl once in there for all fns
# get_hsa_chg()

# get_demographic_chg() ----
# change in activity due to changes in population size and age structure
# param: area_code, type: string, ONS geography code
# param: base_year, type: integer, model baseline
# param: end_year, type: integer, model horizon
# param: proj_id, type: string, population projection variant
# returns:
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

  demo_fac <- create_demographic_factors(
    area_code, base_year, end_year, proj_id
  )

  act |>
    dplyr::left_join(demo_fac, dplyr::join_by(sex, age)) |>
    dplyr::mutate(end_n = n * demo_fac) |>
    dplyr::group_by(id, hsagrp, sex) |>
    dplyr::summarise(base_n = sum(n), end_n = sum(end_n)) |>
    dplyr::ungroup() |>
    dplyr::mutate(end_p = end_n / base_n) |>
    dplyr::arrange(hsagrp, sex)
}

# get_hsa_chg() ----
# change in activity due to changes in population + HSA
# param: area_code, type: string, ONS geography code
# param: base_year, type: integer, model baseline
# param: end_year, type: integer, model horizon
# param: proj_id, type: string, population projection variant
# returns: a dataframe of modeled activity and percent change from base
# year by hsagrp and sex, rtype: rtype: df (vector columns) ...
get_hsa_chg <- function(
  area_code,
  base_year,
  end_year,
  proj_id,
  model_runs,
  rng_state,
  method = c("interp", "gams")
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

  demo_fac <- create_demographic_factors(
    area_code, base_year, end_year, proj_id
  )

  hsa <- get_hsa_factors(
    area_code, base_year, end_year, proj_id, model_runs, rng_state,
    method = method
  )

  act |>
    dplyr::left_join(demo_fac, dplyr::join_by(sex, age)) |>
    dplyr::left_join(hsa, dplyr::join_by(hsagrp, sex, age)) |>
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
    dplyr::select(hsagrp, sex, age, n, end_n) |>
    dplyr::group_by(hsagrp, sex) |>
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
    dplyr::select(hsagrp, sex, base_n, end_n)
}
