# README
# create a set of GAMs (generalised additive models) that model the relationship
# between age and activity, by sex, and by hsagrp.

# TODO
# create_obs_rt_tbl
# incl. omit_hasgrps? (output csv joined to gams in review_gams() what happens if different?)
# create_setting_gams
# treatment of omit_hsagrps
# assumes baseline is equal to or after first year in projections - will probably be true, but?
# variant is hardcoded - again prob. makes sense
# gam fitting age range hard coded
# create_model_rt_tbl
# gam predict age range hard coded
# create_area_gams
# treatment of omit_hsagrps
# obs_rt_tbl.csv, model_rt_tbl.csv, hsa_gams.rds - hard coded file names saved out

# functions ----
# create_obs_rt_tbl
# create_setting_gams
# create_model_rt_tbl
# create_area_gams
# run_area_gams

# create_obs_rt_tbl() ----
# function for returning observed activity rates
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, base year for gams
# param: setting, type: string, settings, one or more of 'edc', 'apc', and 'opc'
# returns: the filename where the df has been saved to, rtype: string
create_obs_rt_tbl <- function(
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

  # load the activity data
  act_ls <- purrr::map(
    setting, \(x) {
      readr::read_rds(
        path_self(paste0(x, "_dat.rds"))
      )
    }
  )

  act_df <- dplyr::bind_rows(act_ls)

  # load the population data
  pop_df <- readr::read_rds(
    path_self(
      filename = "pop_dat.rds"
    )
  )

  # possibly redundant (data should be pre-aggregated)
  act_df <- act_df |>
    dplyr::group_by(area_code, setting, hsagrp, sex, age) |>
    dplyr::summarise(dplyr::across(n, sum)) |>
    dplyr::ungroup()

  # select population projection variant
  pop_df <- pop_df |>
    dplyr::filter(id == "principal_proj") |>
    dplyr::select(id, sex, age, !!as.name(base_year)) |>
    dplyr::rename(base_year = !!as.name(base_year))

  act_df <- act_df |>
    dplyr::left_join(pop_df, dplyr::join_by(sex, age))

  # rate per person per year
  act_df$rt <- act_df$n / act_df$base_year

  filenm <- path_self("obs_rt_tbl.csv")

  act_df |>
    dplyr::select(-id) |>
    readr::write_csv(filenm)

  return(filenm)
}

# create_setting_gams() ----
# helper function for creating gams
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, base year for gams
# param: setting, type: string, either 'ed', 'apc' or 'opc'
# param: omit_hsagrps, type: string vector, activity groups to omit from hsa
# returns: dataframe of gams by hasgrp and sex for a single setting, rtype: df
create_setting_gams <- function(
  area_code, base_year, setting, omit_hsagrps = NULL
) {

  setting <- rlang::arg_match(setting, values = c("edc", "apc", "opc"))
  path_self <- path_closure(area_code, base_year)

  # load the activity data
  act_df <- readr::read_rds(
    path_self(
      filename = paste0(setting, "_dat.rds")
    )
  )

  # load the population data
  pop_df <- readr::read_rds(
    path_self(
      filename = "pop_dat.rds"
    )
  )

  if (!is.null(omit_hsagrps)) {
    act_df <- act_df |>
      dplyr::filter(!hsagrp %in% omit_hsagrps)
  }

  # make explicit missing age values
  act_df <- act_df |>
    dplyr::group_by(area_code, hsagrp, sex, age) |>
    dplyr::summarise(dplyr::across(n, sum)) |>
    dplyr::ungroup() |>
    tidyr::complete(tidyr::nesting(hsagrp, sex), age = 0:90) |>
    dplyr::mutate(dplyr::across(n, \(x) replace(x, is.na(x), 0)))

  # select population projection variant
  pop_df <- pop_df |>
    dplyr::filter(id == "principal_proj") |>
    dplyr::select(id, sex, age, !!as.name(base_year)) |>
    dplyr::rename(base_year = !!as.name(base_year))

  # limit age range for fitting gams
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
    dplyr::nest_by(area_code, hsagrp, sex) |>
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
    dplyr::select(area_code, hsagrp, sex, data, gams)

  return(gams)
}

# create_model_rt_tbl() ----
# helper function for saving modeled activity rates from gams
# param: gams, type: df, dataframe of gams
# param: filenm, type: string, filename for saving modeled rates
create_model_rt_tbl <- function(gams, filenm) {

  # set age range for modeled values
  gam_age_range <- tibble::tibble(age = seq.int(18, 90))

  # obtain modeled values
  gams |>
    tidyr::unnest(gams) |>
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
# create gams for an area (all settings)
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, base year for gams
# returns: dataframe of gams by hsagrp and sex for all settings, rtype: df
create_area_gams <- function(area_code, base_year) {

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

  omit_hsagrps <- omit_hsagrps |>
    dplyr::group_by(setting) |>
    dplyr::summarise(omit = list(omit))

  # create the gams
  gams <- omit_hsagrps |>
    dplyr::mutate(
      gams = purrr::map2(setting, omit, \(x, y) {
        create_setting_gams(
          area_code = area_code,
          base_year = base_year,
          setting = x,
          omit_hsagrps = y
        )
      })
    ) |>
    dplyr::select(-omit)

  create_model_rt_tbl(
    gams,
    filenm = path_self("model_rt_tbl.csv")
  )

  return(gams)
}

# run_area_gams() ----
# create and save gams for an area
# param: area_code, type: string, ONS geography code
# param: base_year, type: int, base year for gams
# returns: the filename where the gams have been saved to, rtype: string
run_area_gams <- function(area_code, base_year) {

  path_self <- path_closure(area_code, base_year)
  gams      <- create_area_gams(area_code, base_year)
  filenm    <- path_self("hsa_gams.rds")

  # save gams
  readr::write_rds(gams, filenm)
  return(filenm)
}
