# README

build_act_inputs <- list(
  tar_option_set(description = "activity"),
  # define modeling params as targets
  tar_target(
    area_codes,
    param_areas
  ),
  tar_target(
    obs_rt_path,
    {
      # ensure activity data is loaded/prepped before this target
      force(df_prep_edc_grp)
      force(df_prep_apc_grp)
      force(df_prep_opc_grp)
      create_obs_rt_df(area_codes, base_year = 2023)
    },
    pattern = map(area_codes)
  ),
  tar_target(
    model_rt_path,
    {
      # ensure activity data is loaded/prepped before this target
      force(df_prep_edc_grp)
      force(df_prep_apc_grp)
      force(df_prep_opc_grp)
      run_area_gams(area_codes, base_year = 2023)
    },
    pattern = map(area_codes)
  ),
  tar_target(
    review_obs_rates,
    {
      # ensure files are created/saved for each area before this target
      force(obs_rt_path)
      review_area_obs_rates(area_codes, base_year = 2023)
    },
    pattern = map(area_codes)
  ),
  tar_target(
    review_gams,
    {
      # ensure files are created/saved for each area before this target
      force(model_rt_path)
      review_area_gams(area_codes, base_year = 2023)
    },
    pattern = map(area_codes)
  ),
  tar_target(
    df_obs_rts,
    {
      # ensure files are created/saved for each area before this target
      force(obs_rt_path)
      # now compile files across areas
      get_observed_profiles(area_codes, base_year = 2023)
    }
  ),
  tar_target(
    df_model_rts,
    {
      # ensure files are created/saved for each area before this target
      force(model_rt_path)
      # now compile files across areas
      get_modeled_profiles(area_codes, base_year = 2023)
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
