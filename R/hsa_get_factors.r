# README
# calculate HSA change factors for an area

# TODO
# should variable name be hsa_fac not f

# get_hsa_factors() ----
# calculate hsa change factors
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, model baseline
# param: end_year, type: int, model horizon
# param: proj_id, type: string, population projection variant
# param: model_runs, type: integer, number of times to run model
# param: rng_state, type: integer vector, RNG state
# param: method, type: string, method for obtaining modeled activity rates for
# hsa ages, either 'interp' or 'gams'
# param: mode, type: bool, monte carlo or modal value
# returns: df, with list column of hsa factors,
# rtype: df, (f = vector, length = model runs)
get_hsa_factors <- function(
  area_code, base_year, end_year, proj_id, model_runs, rng_state,
  method = c("interp", "gams"), mode = FALSE
) {

  method <- rlang::arg_match(method, values = c("interp", "gams"))

  path_self <- path_closure(area_code, base_year)

  # be careful!
  ex_id <- get_ex_id(!!proj_id)

  ex_chg <- load_life_expectancy(base_year, end_year)

  ex_chg <- split(
    ex_chg |>
      dplyr::filter(id == ex_id),
    ~ sex
  )

  ex_chg <- purrr::map(
    ex_chg, \(x) {
      x |>
        dplyr::pull(ex_chg)
    }
  )

  hsa_params <- create_hsa_params(
    end_year,
    var = ex_id,
    model_runs,
    rng_state,
    mode = mode
  )

  # age range for health status adjustment
  hsa_age_range <- seq.int(55, 90)

  # adjusted ages
  adj <- purrr::map2(
    ex_chg, hsa_params, \(x, y) {
      purrr::map(
        x, \(x) {
          x * y
        }
      )
    }
  )

  adjusted_ages <- purrr::map(
    adj, \(x) {
      purrr::map2(
        x, hsa_age_range, \(x, y) {
          list(age = y - x)
        }
      )
    }
  )

  chron_rt <- readr::read_csv(
    path_self("model_rt_df.csv"),
    show_col_types = FALSE
  )

  # add projection id and end year
  chron_rt <- chron_rt |>
    dplyr::mutate(
      id = proj_id,
      end_year = end_year,
      .after = area_code
    )

  chron_rt <- split(
    chron_rt |>
      dplyr::filter(age %in% hsa_age_range),
    ~ sex
  )

  if (method == "gams") {
    p <- model_rt_hsa_ages(area_code, base_year, adjusted_ages)
  } else {
    p <- interp_rt_hsa_ages(area_code, base_year, adjusted_ages)
  }

  # compile hsa factors
  f <- chron_rt$f |>
    dplyr::group_by(area_code, end_year, id, setting, hsagrp) |>
    tidyr::nest(.key = "data") |>
    dplyr::ungroup() |>
    dplyr::mutate(p = p$f) |>
    tidyr::unnest(c(data, p)) |>
    dplyr::mutate(
      f = purrr::map2(
        p, gam_rt, \(x, y) {
          x / y
        }
      )
    ) |>
    dplyr::select(-gam_rt, -p)

  m <- chron_rt$m |>
    dplyr::group_by(area_code, end_year, id, setting, hsagrp) |>
    tidyr::nest(.key = "data") |>
    dplyr::ungroup() |>
    dplyr::mutate(p = p$m) |>
    tidyr::unnest(c(data, p)) |>
    dplyr::mutate(
      f = purrr::map2(
        p, gam_rt, \(x, y) {
          x / y
        }
      )
    ) |>
    dplyr::select(-gam_rt, -p)

  if (isTRUE(mode)) {
    dplyr::bind_rows(f, m) |>
      tidyr::unnest(f)
  } else {
    dplyr::bind_rows(f, m)
  }
}
