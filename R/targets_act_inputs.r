# README

build_act_inputs <- list(
  # define modeling params as targets
  tar_target(
    area_codes,
    param_areas
  ),
  tar_target(
    obs_rt_path,
    create_obs_rt_df_all_areas(area_codes, base_year = 2022)
  ),
  tar_target(
    model_rt_path,
    run_gams_all_areas(area_codes, base_year = 2022)
  ),
  tar_target(
    df_obs_rts,
    {
      # ensure files are created/saved for each area before this target
      force(obs_rt_path)
      # now compile files across areas
      get_observed_profiles(area_codes, base_year = 2022)
    }
  ),
  tar_target(
    df_model_rts,
    {
      # ensure files are created/saved for each area before this target
      force(model_rt_path)
      # now compile files across areas
      get_modeled_profiles(area_codes, base_year = 2022)
    }
  ),
  # dynamic branching over row groups (area_code)
  tarchetypes::tar_group_by(
    df_rts,
    combine_profiles(df_obs_rts, df_model_rts),
    area_code
  ),
  tar_target(
    act_input_files,
    format_profiles_json(df_rts),
    pattern = map(df_rts)
  )
)
