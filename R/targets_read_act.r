# README

# nolint start: line_length_linter
read_act_data <- list(
  tar_option_set(description = "activity"),
  tar_target(
    data_raw_edc,
    here::here("data_raw", "edc_dat_2023_20250219.csv"),
    format = "file"
  ),
  tar_target(
    df_raw_edc,
    read_raw_edc(data_raw_edc)
  ),
  tar_target(
    rw_raw_edc,
    review_raw_edc(df_raw_edc)
  ),
  # dynamic branching over row groups (area_code)
  tarchetypes::tar_group_by(
    df_prep_edc,
    prep_edc(df_raw_edc, lookup_lad18_lad23, df_icb23, df_raw_cty23, df_raw_lad23),
    area_code
  ),
  tar_target(
    df_prep_edc_grp,
    edc_to_dirs(df_prep_edc, dir_yyyy = 2023),
    pattern = map(df_prep_edc)
  ),
  tar_target(
    data_raw_apc,
    here::here("data_raw", "apc_dat_2023_20250219.csv"),
    format = "file"
  ),
  tar_target(
    df_raw_apc,
    read_raw_edc(data_raw_apc)
  ),
  tar_target(
    rw_raw_apc,
    review_raw_apc(df_raw_apc)
  ),
  # dynamic branching over row groups (area_code)
  tarchetypes::tar_group_by(
    df_prep_apc,
    prep_apc(df_raw_apc, lookup_lad18_lad23, df_icb23, df_raw_cty23, df_raw_lad23),
    area_code
  ),
  tar_target(
    df_prep_apc_grp,
    apc_to_dirs(df_prep_apc, dir_yyyy = 2023),
    pattern = map(df_prep_apc)
  ),
  tar_target(
    data_raw_opc,
    here::here("data_raw", "opc_dat_2023_20250219.csv"),
    format = "file"
  ),
  tar_target(
    df_raw_opc,
    read_raw_opc(data_raw_opc)
  ),
  # dynamic branching over row groups (area_code)
  tarchetypes::tar_group_by(
    df_prep_opc,
    prep_opc(df_raw_opc, lookup_lad18_lad23, df_icb23, df_raw_cty23, df_raw_lad23),
    area_code
  ),
  tar_target(
    df_prep_opc_grp,
    opc_to_dirs(df_prep_opc, dir_yyyy = 2023),
    pattern = map(df_prep_opc)
  )
)
# nolint end: line_length_linter
