# README
# helper fns to help with modeling health status adjustment

# TODO
# load_life_expectancy - hsa_age_range hard coded
# get_ex_id - arg_match to specify possible values

# functions ----
# path_closure
# create_demographic_factors
# load_activity_data
# load_life_expectancy
# get_ex_id
# random_split_norm
# create_hsa_params
# create_hsa_mode
# model_rt_hsa_ages

# path_closure() ----
# helper closure function for returning file paths
# closures, functions written by functions http://adv-r.had.co.nz/Functional-programming.html # nolint: line_length_linter.
# param: area_code, type: string, local authority code
# param: base_year, type: int, model baseline
# returns: a function requesting a filename
path_closure <- function(area_code, base_year) {
  function(filename) {
    here::here("data", base_year, area_code, filename)
  }
}

# create_demographic_factors() ----
# calculate demographic change factors for an area
# change factors are returned for all variants
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, model baseline
# param: end_year, type: int, model horizon
# returns: a dataframe of demographic change factors, rtype: df
create_demographic_factors <- function(
  area_code, base_year, end_year, proj_id
) {

  path_self <- path_closure(area_code, base_year)

  readr::read_rds(path_self("pop_dat.rds")) |>
    dplyr::filter(id == proj_id) |>
    dplyr::mutate(demo_fac = !!as.name(end_year) / !!as.name(base_year)) |>
    dplyr::select(id, sex, age, demo_fac)
}

# load_activity_data() ----
# load activity data for baseline year
# param: area_code, type: string, ONS geography code
# param: base_year, type: integer, model baseline
# param: setting, type: string, settings, one or more of 'edc', 'apc', and 'opc'
# returns: a dataframe of activity data, rtype: df
load_activity_data <- function(
  area_code,
  base_year,
  # default to all 3 main acute hospital settings
  setting = c("edc", "apc", "opc")
) {

  setting <- rlang::arg_match(
    setting,
    values = c("edc", "apc", "opc"),
    multiple = TRUE
  )

  path_self <- path_closure(area_code, base_year)

  x <- purrr::map(
    setting, \(x) {
      readr::read_rds(
        path_self(paste0(x, "_dat.rds"))
      )
    }
  )

  dplyr::bind_rows(x)
}

# load_life_expectancy() ----
# calculate change in life expectancy
# changes are returned for all variants
# param: base_year, type: int, model baseline
# param: end_year, type: int, model horizon
# returns: a dataframe of life expectancy changes, rtype: df
load_life_expectancy <- function(base_year, end_year) {

  # age range for health status adjustment
  hsa_age_range <- seq.int(55, 90)

  ex_dat <- targets::tar_read(df_lifetbl) |>
    # use period life expectancy
    dplyr::filter(type == "period", age %in% hsa_age_range)

  ex_dat |>
    dplyr::filter(year %in% c(base_year, end_year)) |>
    dplyr::group_by(id, sex, age) |>
    tidyr::pivot_wider(names_from = year, values_from = ex) |>
    dplyr::summarise(ex_chg = !!as.name(end_year) - !!as.name(base_year)) |>
    dplyr::ungroup()
}

# get_ex_id() ----
# helper fn to fetch life expectancy variant mapped from projection variant
# param: proj_id, type: string, population projection variant
# returns: life ex variant, rtype: string, either 'lle', 'ppp' or 'hle'
get_ex_id <- function(proj_id) {

  lookup_proj_id <- readr::read_csv(
    here::here("data", "lookup_proj_id.csv"),
    show_col_types = FALSE
  )

  lookup_proj_id |>
    dplyr::filter(proj_id == {{ proj_id }}) |>
    dplyr::pull(ex_id)
}

# random_split_norm() ----
# helper function to draw random values from a split normal distribution
# param: n, type: integer, number of observations
# param: mode, type: double, mode
# param: sd1, type: double, left-hand-side standard deviation
# param: sd2, type: double, right-hand-side standard deviation
# param: rng_state, type: integer vector, RNG state
# returns: n random number values sampled from the split normal distribution,
# rtype: vector
random_split_norm <- function(n, mode, sd1, sd2, rng_state) {

  # get the probability of the mode
  A <- sqrt(2 / pi) / (sd1 + sd2) # nolint: object_name_linter.
  a_sqrt_tau <- A * sqrt(2 * pi)
  p <- (a_sqrt_tau * sd1) / 2

  # generate n random uniform values
  set.seed(seed = rng_state)
  u <- runif(n = n)

  # whether u is less than the mode or not
  a1 <- u <= p

  # make a single sd vector
  sd <- dplyr::if_else(a1, sd1, sd2)
  x <- dplyr::if_else(a1, 0, a_sqrt_tau * sd2 - 1)

  return(mode + sd * qnorm(p = (u + x) / (a_sqrt_tau * sd)))
}

# create_hsa_params() ----
# draw hsa parameter values
# param: end_year, type: integer, model horizon
# param: var, type: string, life ex variant, either 'ppp', 'lle' or 'hle'
# param: model_runs, type: integer, number of times to run model
# param: rng_state, type: integer vector, RNG state
# returns: parameters for the health status adjustment, rtype: list of 2
# (females and males), length = model_runs
create_hsa_params <- function(
  end_year, var, model_runs, rng_state, mode = FALSE
) {

  # load split normal parameters
  sp_norm_params <- readr::read_csv(
    here::here(
      "data", "split_normal_parameters.csv"
    ),
    show_col_types = FALSE
  ) |>
    dplyr::filter(year == {{ end_year }}, var == {{ var }})

  sex <- sp_norm_params$sex

  # draw values dependent on mode argument
  if (isTRUE(mode)) {
    # return mode (single value)
    params_ls <- purrr::map(sp_norm_params$mode, \(x) x)
  } else {
    # return sample (many values)
    params_ls <- purrr::pmap(
      sp_norm_params[, c("mode", "sd1", "sd2")],
      random_split_norm,
      n = model_runs,
      rng_state = rng_state
    )
  }

  names(params_ls) <- sex

  return(params_ls)
}

# create_hsa_mode() ----
# return the mode of a split normal distribution
# param: end_year, type: integer, model horizon
# param: var, type: string, life table variant, either 'ppp', 'lle' or 'hle'
# return: parameters for the health status adjustment, rtype: list of 2
# (females and males), length = 1
create_hsa_mode <- function(end_year, var) {

  # load split normal parameters
  sp_norm_params <- readr::read_csv(
    here::here(
      "data", "split_normal_parameters.csv"
    ),
    show_col_types = FALSE
  ) |>
    dplyr::filter(year == {{ end_year }}, var == {{ var }})

  sex <- sp_norm_params$sex

  # return mode
  params_ls <- purrr::map(sp_norm_params$mode, \(x) x)

  names(params_ls) <- sex

  return(params_ls)
}

# model_rt_hsa_ages() ----
# model activity rates using gams for hsa ages (predict)
# do this n times, where n = model_runs
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, model baseline
# param: adjusted_ages, type: list of 2 (f/m), list of 36 (ages 55-90), vector
# (length = model runs) of health status adjusted ages
# returns: a list of modeled activity rates for supplied adjusted ages,
# rtype: list of 2 (f/m), list of 16 (hsagrps), list of 36 (ages 55-90), vector
# (length = model runs)
model_rt_hsa_ages <- function(area_code, base_year, adjusted_ages) {

  path_self <- path_closure(area_code, base_year)

  gams <- readr::read_rds(path_self("hsa_gams.rds"))

  # list is preferred as model runs can be large
  gams <- gams |>
    tidyr::unnest(gams) |>
    split(~ sex)

  # predict.gam returns an array (convert to vector)
  f <- purrr::map(gams$f$gams, \(x) {
    purrr::map(adjusted_ages[["f"]], \(y) {
      as.vector(mgcv::predict.gam(x, newdata = y))
    })
  })

  m <- purrr::map(gams$m$gams, \(x) {
    purrr::map(adjusted_ages[["m"]], \(y) {
      as.vector(mgcv::predict.gam(x, newdata = y))
    })
  })

  list(f = f, m = m)
}

# interp_rt_hsa_ages() ----
# model activity rates using gams for hsa ages (interpolate as oppose to
# predict, interpolation is faster and any difference should be small)
# do this n times, where n = model_runs
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, model baseline
# param: adjusted_ages, type: list of 2 (f/m), list of 36 (ages 55-90), vector
# (length = model runs) of health status adjusted ages
# returns: a list of modeled activity rates for supplied adjusted ages,
# rtype: list of 2 (f/m), list of 16 (hsagrps), list of 36 (ages 55-90), vector
# (length = model runs)
interp_rt_hsa_ages <- function(area_code, base_year, adjusted_ages) {

  path_self <- path_closure(area_code, base_year)

  act_df <- readr::read_csv(
    here::here(
      path_self("model_rt_tbl.csv")
    )
  ) |>
    dplyr::group_by(setting, hsagrp, sex) |>
    tidyr::nest(.key = "data") |>
    dplyr::mutate(
      user_approxfun = purrr::map(data, \(x) {
        approxfun(x = x$age, y = x$gam_rt, method = "linear", rule = 2)
      })
    )

  act_df <- split(act_df, ~ sex)

  f <- purrr::map(
    act_df$f$user_approxfun, \(x) {
      purrr::map_depth(adjusted_ages[[1]], 2, \(y) x(v = y))
    }
  )

  m <- purrr::map(
    act_df$m$user_approxfun, \(x) {
      purrr::map_depth(adjusted_ages[[2]], 2, \(y) x(v = y))
    }
  )

  f <- purrr::map_depth(f, 2, unlist, use.names = FALSE)
  m <- purrr::map_depth(m, 2, unlist, use.names = FALSE)

  list(f = f, m = m)
}
