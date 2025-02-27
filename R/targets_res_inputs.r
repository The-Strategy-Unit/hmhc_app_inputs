# README

build_res_inputs <- list(
  tar_option_set(description = "results"),
  # define modeling params as targets
  tar_target(
    area_codes_res,
    param_areas
  ),
  tar_target(
    base_year,
    param_by
  ),
  tar_target(
    end_year,
    param_ey
  ),
  tar_target(
    proj_id,
    param_vars
  ),
  # run pure demographic models
  tar_target(
    pure_demo,
    get_demographic_chg(area_codes_res, base_year, end_year, proj_id),
    pattern = cross(area_codes_res, base_year, end_year, proj_id)
  ),
  # define modeling params as targets
  tar_target(
    model_runs,
    param_draws
  ),
  tar_target(
    rng_state,
    param_rng
  ),
  # run hsa mode only models
  tar_target(
    hsa_mode,
    get_hsa_chg(
      area_codes_res, base_year, end_year, proj_id, model_runs, rng_state,
      method = "interp", mode = TRUE
    ),
    pattern = cross(
      area_codes_res, base_year, end_year, proj_id,
      map(model_runs, rng_state)
    )
  ),
  # run hsa monte carlo models
  tar_target(
    hsa_mc,
    get_hsa_chg(
      area_codes_res, base_year, end_year, proj_id, model_runs, rng_state,
      method = "interp", mode = FALSE
    ),
    pattern = cross(
      area_codes_res, base_year, end_year, proj_id,
      map(model_runs, rng_state)
    )
  ),
  # group f/m split to persons
  tar_target(
    pure_demo_grp,
    nomc_grp_sex(pure_demo)
  ),
  tar_target(
    hsa_mode_grp,
    nomc_grp_sex(hsa_mode)
  ),
  tar_target(
    hsa_mc_grp,
    mc_grp_sex(hsa_mc)
  ),
  # compute histogram binning
  tar_target(
    hsa_mc_grp_bins,
    compute_binning(hsa_mc_grp)
  ),
  # collect results into a single df
  # dynamic branching over row groups (area_code)
  tarchetypes::tar_group_by(
    df_res,
    join_res_dfs(pure_demo_grp, hsa_mode_grp, hsa_mc_grp_bins),
    area_code
  ),
  tar_target(
    res_json,
    format_results_json(df_res),
    pattern = map(df_res)
  )
)
