# README
# create a set of GAMs (generalised additive models) that model the relationship
# between age and healthcare activity, by sex, and by hsagrp

# functions ----
# create_obs_rt_df
# create_model_rt_df
# create_area_gams
# run_area_gams

# create_obs_rt_df() ----
# function for returning df of observed activity rates
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, base year for gams
# param: setting, type: string, setting, one or more of 'edc', 'apc', and 'opc'
# returns: the filepath for a saved df, rtype: string
create_obs_rt_df <- function(
  area_code,
  base_year,
  # default to all 3 main acute hospital settings
  setting = c("apc", "edc", "opc")
) {

  setting <- rlang::arg_match(
    setting,
    values = c("apc", "edc", "opc"),
    multiple = TRUE
  )

  path_self <- path_closure(area_code, base_year)

  # load activity data
  act_ls <- purrr::map(
    setting, \(x) {
      readr::read_rds(
        path_self(paste0(x, "_dat.rds"))
      )
    }
  )

  act_df <- dplyr::bind_rows(act_ls)

  # # load population data
  pop_df <- readr::read_rds(
    path_self(
      filename = "pop_dat.rds"
    )
  ) |>
    # always princiapal variant here
    dplyr::filter(id == "principal_proj") |>
    dplyr::select(id, sex, age, !!as.name(base_year)) |>
    dplyr::rename(base_year = !!as.name(base_year))

  act_df <- act_df |>
    dplyr::left_join(pop_df, dplyr::join_by(sex, age))

  # rate per person per year
  act_df$rt <- act_df$n / act_df$base_year

  filenm <- path_self("obs_rt_df.csv")

  act_df |>
    readr::write_csv(filenm)

  return(filenm)
}

# create_model_rt_df() ----
# helper function for saving modeled activity rates from gams
# param: gams, type: df, dataframe of gams
# param: filenm, type: string, filename for saved modeled rates
create_model_rt_df <- function(gams, filenm) {

  # fix age range for modeled values
  gam_age_range <- tibble::tibble(age = seq.int(18, 90))

  # save modeled values
  gams |>
    dplyr::mutate(age = list(gam_age_range)) |>
    # predict.gam returns an array (convert to vector)
    dplyr::mutate(
      gam_rt = purrr::map2(gams, age, \(x, y) {
        as.vector(mgcv::predict.gam(x, y))
      })
    ) |>
    dplyr::select(area_code, setting, hsagrp, sex, age, gam_rt) |>
    tidyr::unnest(c(age, gam_rt)) |>
    readr::write_csv(filenm)
}

# create_area_gams() ----
# create gams for an area (default is all settings)
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, base year for gams
# param: setting, type: string, setting, one or more of 'edc', 'apc', or 'opc'
# param: omit_hsagrps, type: ???,
# returns: dataframe of gams by hsagrp and sex for all settings, rtype: df
create_area_gams <- function(
  area_code,
  base_year,
  # default to all 3 main acute hospital settings
  setting = c("apc", "edc", "opc"),
  omit_hsagrps = NULL
) {

  setting <- rlang::arg_match(
    setting,
    values = c("apc", "edc", "opc"),
    multiple = TRUE
  )

  path_self <- path_closure(area_code, base_year)

  # load activity data
  act_ls <- purrr::map(
    setting, \(x) {
      readr::read_rds(
        path_self(paste0(x, "_dat.rds"))
      )
    }
  )

  act_df <- dplyr::bind_rows(act_ls)

  # load population data
  pop_df <- readr::read_rds(
    path_self(
      filename = "pop_dat.rds"
    )
  ) |>
    # always princiapal variant here
    dplyr::filter(id == "principal_proj") |>
    dplyr::select(id, sex, age, !!as.name(base_year)) |>
    dplyr::rename(base_year = !!as.name(base_year))

  # make explicit missing age values
  act_df <- act_df |>
    dplyr::group_by(area_code, setting, hsagrp, sex, age) |>
    dplyr::summarise(dplyr::across(n, sum)) |>
    dplyr::ungroup() |>
    tidyr::complete(tidyr::nesting(setting, hsagrp, sex), age = 0:90) |>
    dplyr::mutate(dplyr::across(n, \(x) replace(x, is.na(x), 0)))

  # fix age range for fitting gams
  act_df <- act_df |>
    dplyr::filter(age >= 18)
  act_df <- act_df |>
    dplyr::filter(age <= 90)

  act_df <- act_df |>
    dplyr::left_join(pop_df, dplyr::join_by(sex, age))

  # rate per person per year
  act_df$rt <- act_df$n / act_df$base_year

  # create gams
  gams <- act_df |>
    dplyr::nest_by(area_code, setting, hsagrp, sex) |>
    dplyr::mutate(
      gams = list(
        mgcv::gam(
          rt ~ s(age, bs = "bs", k = 10),
          method = "GCV.Cp",
          family = gaussian(),
          data = data
        )
      )
    ) |>
    dplyr::ungroup() |>
    dplyr::select(area_code, setting, hsagrp, sex, data, gams)

  create_model_rt_df(
    gams,
    filenm = path_self("model_rt_df.csv")
  )

  return(gams)
}

# run_area_gams() ----
# create and save gams for an area
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, base year for gams
# param: setting, type: string, setting, one or more of 'edc', 'apc', or 'opc'
# param: omit_hsagrps, type: ???,
# returns: the filepath for saved gams, rtype: string
run_area_gams <- function(
  area_code,
  base_year,
  setting = c("apc", "edc", "opc"),
  omit_hsagrps = NULL
) {

  path_self <- path_closure(area_code, base_year)
  gams      <- create_area_gams(area_code, base_year)
  filenm    <- path_self("hsa_gams.rds")

  # save gams
  readr::write_rds(gams, filenm)

  return(filenm)
}
