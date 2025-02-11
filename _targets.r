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
param_by     <- 2022L
param_ey     <- if (rlang::is_true(dev_run)) 2035L else seq(2025L, 2040L, 5L)
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

# nolint start: line_length_linter
# pipeline ----
list(
  #############################################################################
  # read population data ----
  #############################################################################
  tar_target(
    data_raw_very_old,
    here::here("data_raw", "englandevo2023.csv"),
    format = "file"
  ),
  tar_target(
    df_raw_very_old,
    read_very_old(data_raw_very_old)
  ),
  tar_target(
    df_very_old,
    prep_very_old(df_raw_very_old)
  ),
  # branch over life table files
  tarchetypes::tar_files_input(
    lt_files,
    fs::dir_ls(here::here("data_raw"), glob = "*18ex.xls")
  ),
  tar_target(
    df_lifetbl,
    prep_life_tbl(lt_files),
    pattern = map(lt_files)
  ),
  tar_target(
    csv_lifetbl,
    life_tbl_csv(df_lifetbl),
    format = "file"
  ),
  # branch over snpp variants files
  tarchetypes::tar_files_input(
    snpp_paths,
      fs::dir_ls(
        here::here("data_raw"), regexp = "2018 SNPP.*(females|males).*(.csv$)",
        recurse = TRUE
      )
  ),
  tar_target(
    df_snpp,
    prep_snpp(snpp_paths),
    pattern = map(snpp_paths)
  ),
  # branch over npp variants files
  tarchetypes::tar_files_input(
     npp_paths,
      fs::dir_ls(
        here::here("data_raw"), regexp = "2018(.xls)$",
        recurse = TRUE
      )
  ),
  tar_target(
    df_npp,
    prep_npp(npp_paths),
    pattern = map(npp_paths)
  ),
  tar_target(
    data_raw_npp_codes,
    here::here("data_raw", "npp_2018b", "NPP codes.txt"),
    format = "file"
  ),
  # not used posterity - split into 2
  tar_target(
    df_npp_codes,
    prep_npp_codes(data_raw_npp_codes)
  ),
  tar_target(
    csv_npp_codes,
    npp_codes_csv(df_npp_codes),
    format = "file"
  ),
  tar_target(
    data_raw_mye,
    here::here("data_raw", "nomis_mye_lad_1991to2023_20250116.csv"),
    format = "file"
  ),
  tar_target(
    df_mye,
    read_mye(data_raw_mye)
  ),
  #############################################################################
  # read area lookups
  #############################################################################
  tar_target(data_raw_lad18, here::here("data_raw", "LAD_(Dec_2018)_Names_and_Codes_in_the_United_Kingdom.csv"),
    format = "file"
  ),
  tar_target(df_raw_lad18, read_lad18(data_raw_lad18, here::here("data", "local_authority_districts_2018.csv"))),
  tar_target(data_raw_lad22, here::here("data_raw", "LAD_(Dec_2022)_Names_and_Codes_in_the_United_Kingdom.csv"),
    format = "file"
  ),
  tar_target(df_raw_lad22, read_lad22(data_raw_lad22, here::here("data", "local_authority_districts_2022.csv"))),
  tar_target(data_raw_lad23, here::here("data_raw", "LAD_(Apr_2023)_Names_and_Codes_in_the_United_Kingdom.csv"),
    format = "file"
  ),
  tar_target(df_raw_lad23, read_lad23(data_raw_lad23, here::here("data", "local_authority_districts_2023.csv"))),
  tar_target(data_raw_cty18, here::here("data_raw", "Local_Authority_District_to_County_(December_2018)_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(df_raw_cty18, read_cty18(data_raw_cty18, here::here("data", "lookup_lad2018_cty.csv"))),
  tar_target(data_raw_cty22, here::here("data_raw", "Local_Authority_District_to_County_(December_2022)_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(df_raw_cty22, read_cty22(data_raw_cty22, here::here("data", "lookup_lad2022_cty.csv"))),
  tar_target(data_raw_cty23, here::here("data_raw", "Local_Authority_District_to_County_(April_2023)_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(df_raw_cty23, read_cty23(data_raw_cty23, here::here("data", "lookup_lad2023_cty.csv"))),
  tar_target(df_retired_cty, get_retired_ctys(df_raw_cty18, df_raw_cty23, here::here("data", "retired_ctys_2018_2023.csv"))),
  tar_target(data_raw_icb23, here::here("data_raw", "LSOA_(2021)_to_Sub_ICB_Locations_to_Integrated_Care_Boards_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(df_icb23, mk_lookup_icb23(data_raw_icb23, here::here("data", "lookup_lad23_icb23.csv"))),
  tar_target(lookup_proj_id, mk_lookup_proj(here::here("data", "lookup_proj_id.csv"))),
  tar_target(lookup_lad18_lad23, mk_lookup_lad18_lad23(here::here("data", "lookup_lad18_lad23.csv"))),
  #############################################################################
  # assemble population mye series
  #############################################################################
  tar_target(df_mye_to90, mk_mye_to90(df_mye)),
  tar_target(df_mye_to100, mk_mye_to100(df_very_old, df_mye_to90)),
  tar_target(df_mye_series_to90, mk_mye_compl(df_mye_to90, df_raw_lad23, df_raw_cty23, df_icb23)),
  tar_target(df_mye_series_to100, mk_mye_compl(df_mye_to100, df_raw_lad23, df_raw_cty23, df_icb23)),
  #############################################################################
  # assemble population projection series
  #############################################################################
  tar_target(snpp_custom_vars, mk_custom_vars(df_npp, df_snpp)),
# branch over df grouped by area_code
  tarchetypes::tar_group_by(snpp_series_to90, mk_snpp_series(snpp_custom_vars, df_snpp, lookup_lad18_lad23, df_retired_cty, df_npp, df_icb23), area_code),
  tar_target(snpp_series_to90_grp, snpp_to_dirs(snpp_series_to90), pattern = map(snpp_series_to90)),
  tar_target(snpp_series_to100, make_snpp_100(df_npp, snpp_series_to90, lookup_proj_id)),
  #############################################################################
  # assemble activity data
  #############################################################################
  tar_target(data_raw_edc, here::here("data_raw", "edc_dat_20250120.csv"),
    format = "file"),
  tar_target(df_raw_edc, read_raw_edc(data_raw_edc)),
  # branch over df grouped by area_code
  tarchetypes::tar_group_by(df_prep_edc, prep_edc(df_raw_edc, lookup_lad18_lad23, df_icb23, df_raw_cty23, df_raw_lad23), area_code),
  tar_target(df_prep_edc_grp, edc_to_dirs(df_prep_edc), pattern = map(df_prep_edc)),
  tar_target(data_raw_apc, here::here("data_raw", "apc_dat_20250120.csv"),
    format = "file"),
  tar_target(df_raw_apc, read_raw_edc(data_raw_apc)),
  # branch over df grouped by area_code
  tarchetypes::tar_group_by(df_prep_apc, prep_apc(df_raw_apc, lookup_lad18_lad23, df_icb23, df_raw_cty23, df_raw_lad23), area_code),
  tar_target(df_prep_apc_grp, apc_to_dirs(df_prep_apc), pattern = map(df_prep_apc)),
  tar_target(data_raw_opc, here::here("data_raw", "opc_dat_20250120.csv"),
    format = "file"),
  tar_target(df_raw_opc, read_raw_opc(data_raw_opc)),
  # branch over df grouped by area_code
  tarchetypes::tar_group_by(df_prep_opc, prep_opc(df_raw_opc, lookup_lad18_lad23, df_icb23, df_raw_cty23, df_raw_lad23), area_code),
  tar_target(df_prep_opc_grp, opc_to_dirs(df_prep_opc), pattern = map(df_prep_opc)),
  #############################################################################
  # assemble app files (JSON)
  #############################################################################
  # POPULATION INPUTS ----
  # dynamic branching over row groups (area_code)
  tarchetypes::tar_group_by(df_pop_data, build_pop_data(df_mye_series_to100, snpp_series_to100), area_code),
  tar_target(dfpop, format_pop_data_json(df_pop_data), pattern = map(df_pop_data)),
  # ACTIVITY INPUTS ----
  tar_target(area_codes_csv, here::here("data", "app_input_files", "area_names_and_codes.csv"),
    format = "file"),
  tar_target(area_codes_all, read_area_codes(area_codes_csv)),
  # define modeling params as targets
  tar_target(area_codes, param_areas),
  tar_target(x, create_obs_rt_df_all_areas(area_codes, base_year = 2022)), # return something here?
  tar_target(y, run_gams_all_areas(area_codes, base_year = 2022)),
  tar_target(df_obs_rts, get_observed_profiles(area_codes, base_year = 2022)),
  tar_target(df_model_rts, get_modeled_profiles(area_codes, base_year = 2022)),
  # dynamic branching over row groups (area_code)
  tarchetypes::tar_group_by(df_rts, combine_profiles(df_obs_rts, df_model_rts), area_code),
  tar_target(act_input_files, format_profiles_json(df_rts), pattern = map(df_rts)),
  # RESULTS INPUTS ----
  # define modeling params as targets
  # param_areas defined above for activity inputs
  tar_target(base_year, param_by),
  tar_target(end_year, param_ey),
  tar_target(proj_id, param_vars),
  # run pure demographic models
  tar_target(pure_demo,
    get_demographic_chg(area_codes, base_year, end_year, proj_id),
    pattern = cross(area_codes, base_year, end_year, proj_id)
  ),
  # run hsa mode only models
  tar_target(model_runs, param_draws),
  tar_target(rng_state, param_rng),
  tar_target(
    hsa_mode,
      get_hsa_chg(area_codes, base_year, end_year, proj_id, model_runs, rng_state, method = "gams", mode = TRUE),
      pattern = cross(area_codes, base_year, end_year, proj_id, map(model_runs, rng_state))
  ),
  # run hsa monte carlo models
  tar_target(
    hsa_mc,
      get_hsa_chg(area_codes, base_year, end_year, proj_id, model_runs, rng_state, method = "gams", mode = FALSE),
      pattern = cross(area_codes, base_year, end_year, proj_id, map(model_runs, rng_state))
  ),
  # group-up results by sex
  tar_target(pure_demo_grp, nomc_grp_sex(pure_demo)),
  tar_target(hsa_mode_grp, nomc_grp_sex(hsa_mode)),
  tar_target(hsa_mc_grp, mc_grp_sex(hsa_mc)),
  # compute histogram binning
  tar_target(hsa_mc_grp_bins, compute_binning(hsa_mc_grp)),
  # collect results into a single df
  # dynamic branching over row groups (area_code)
  tarchetypes::tar_group_by(df_res, join_res_dfs(pure_demo_grp, hsa_mode_grp, hsa_mc_grp_bins), area_code),
  tar_target(j, format_results_json(df_res), pattern = map(df_res))
)
# nolint end: line_length_linter

# https://stackoverflow.com/questions/77947521/targets-does-not-recognize-other-targets-inside-values-of-tar-map
