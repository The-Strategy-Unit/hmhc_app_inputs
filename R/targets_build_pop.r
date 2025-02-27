# README

# nolint start: line_length_linter
build_pop_series <- list(
  tar_option_set(description = "population"),
  # build population mye series ----
  tar_target(
    df_mye_to90,
    mk_mye_to90(df_mye)
  ),
  tar_target(
    df_mye_to100,
    mk_mye_to100(df_very_old, df_mye_to90)
  ),
  # dynamic branching over row groups (area_code)
  tarchetypes::tar_group_by(
    df_mye_series_to90,
    mk_mye_compl(df_mye_to90, df_raw_lad23, df_raw_cty23, df_icb23),
    area_code
  ),
  tar_target(
    df_mye_series_to90_grp,
    mye_to_dirs(df_mye_series_to90, dir_yyyy = 2023),
    pattern = map(df_mye_series_to90)
  ),
  tar_target(
    df_mye_series_to100,
    mk_mye_compl(df_mye_to100, df_raw_lad23, df_raw_cty23, df_icb23)
  ),
  # build population projections series ----
  tar_target(
    snpp_custom_vars,
    mk_custom_vars(df_npp, df_snpp)
  ),
  # dynamic branching over row groups (area_code)
  tarchetypes::tar_group_by(
    snpp_series_to90,
    mk_snpp_series(snpp_custom_vars, df_snpp, lookup_lad18_lad23, df_retired_cty, df_npp, df_icb23),
    area_code
  ),
  tar_target(
    snpp_series_to90_grp,
    snpp_to_dirs(snpp_series_to90, dir_yyyy = 2023),
    pattern = map(snpp_series_to90)
  ),
  tar_target(
    snpp_series_to100,
    make_snpp_100(df_npp, snpp_series_to90, lookup_proj_id)
  )
)
# nolint end: line_length_linter
