# README
# target script file - configure and define the pipeline

# pkgs req to define the pipeline ----
library("targets")
library("tarchetypes")

# targets options ----
tar_option_set(
  packages = NULL, # renv?
  format = "auto" # use "qs" storage format
)

# *****************************************************************************
# development (test) or production ----
# *****************************************************************************
dev_run <- TRUE

if (!rlang::is_logical(dev_run)) {
  stop("dev_run must be of type logical")
}

areas_path <- here::here("data", "app_input_files", "area_names_and_codes.csv")

areas_all <- readr::read_csv(areas_path) |>
  dplyr::pull(cd)

areas_test <- c(
  "E07000235", # 1
  "E08000026", # 2
  "E09000030", # 3
  "E92000001" # 4
)

vars_all <- c(
  "hpp", # 1
  "lpp", # 2
  "php", # 3
  "plp", # 4
  "hhh", # 5
  "lll", # 6
  "lhl", # 7
  "hlh", # 8
  "principal_proj", # 9
  "var_proj_high_intl_migration", # 10
  "var_proj_low_intl_migration" # 11
)

param_areas  <- if (rlang::is_true(dev_run)) areas_test else areas_all
param_by     <- 2023L
param_ey     <- if (rlang::is_true(dev_run)) 2035 else seq(2025L, 2040L, 5L)
param_vars   <- vars_all
param_draws  <- if (rlang::is_true(dev_run)) 1e2 else 1e3
param_rng    <- 014796

# example of testing 'crossing' pattern for dynamic branching
tar_pattern(
  cross(param_areas, param_by, param_ey, param_vars),
  param_areas = length(param_areas),
  param_by = length(param_by),
  param_ey = length(param_ey),
  param_vars = length(param_vars)
)

# example showing how patterns are composable
tar_pattern(
  cross(
    param_areas, param_by, param_ey, param_vars,
    map(param_draws, param_rng)
  ),
  param_areas = length(param_areas),
  param_by = length(param_by),
  param_ey = length(param_ey),
  param_vars = length(param_vars),
  param_draws = 1,
  param_rng = 1
)

# load custom fns ----
fs::dir_ls(here::here("R"), glob = "*.r") |>
  purrr::walk(source)

# pipeline ----
# modularized
list(
  read_pop_data,
  read_geo_data,
  read_act_data,
  build_pop_series, # watch name clash!
  build_pop_inputs,
  build_act_inputs,
  build_res_inputs
)
