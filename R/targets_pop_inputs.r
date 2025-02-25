# README

build_pop_inputs <- list(
  # dynamic branching over row groups (area_code)
  tarchetypes::tar_group_by(
    df_pop_data,
    build_pop_data(
      df_mye_series_to100,
      snpp_series_to100,
      first_proj_yr = 2024
    ),
    area_code
  ),
  tar_target(
    dfpop,
    format_pop_data_json(df_pop_data),
    pattern = map(df_pop_data)
  )
)
