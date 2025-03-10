# README

# nolint start: line_length_linter
read_geo_data <- list(
  tar_option_set(description = "read"),
  tar_target(
    data_raw_lad18,
    here::here("data_raw", "LAD_(Dec_2018)_Names_and_Codes_in_the_United_Kingdom.csv"),
    format = "file"
  ),
  tar_target(
    df_raw_lad18,
    read_lad18(data_raw_lad18)
  ),
  tar_target(
    csv_lad18,
    lad18_csv(df_raw_lad18),
    format = "file"
  ),
  tar_target(
    data_raw_lad22,
    here::here("data_raw", "LAD_(Dec_2022)_Names_and_Codes_in_the_United_Kingdom.csv"),
    format = "file"
  ),
  tar_target(
    df_raw_lad22,
    read_lad22(data_raw_lad22)
  ),
    tar_target(
    csv_lad22,
    lad22_csv(df_raw_lad22),
    format = "file"
  ),
  tar_target(
    data_raw_lad23,
    here::here("data_raw", "LAD_(Apr_2023)_Names_and_Codes_in_the_United_Kingdom.csv"),
    format = "file"
  ),
  tar_target(
    df_raw_lad23,
    read_lad23(data_raw_lad23)
  ),
  tar_target(
    csv_lad23,
    lad23_csv(df_raw_lad23),
    format = "file"
  ),
  tar_target(
    data_raw_cty18,
    here::here("data_raw", "Local_Authority_District_to_County_(December_2018)_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(
    df_raw_cty18,
    read_cty18(data_raw_cty18)
  ),
  tar_target(
    csv_cty18,
    cty18_csv(df_raw_cty18),
    format = "file"
  ),
  tar_target(
    data_raw_cty22,
    here::here("data_raw", "Local_Authority_District_to_County_(December_2022)_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(
    df_raw_cty22,
    read_cty22(data_raw_cty22)
  ),
  tar_target(
    csv_cty22,
    cty22_csv(df_raw_cty22),
    format = "file"
  ),
  tar_target(
    data_raw_cty23,
    here::here("data_raw", "Local_Authority_District_to_County_(April_2023)_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(
    df_raw_cty23,
    read_cty23(data_raw_cty23)
  ),
  tar_target(
    csv_cty23,
    cty23_csv(df_raw_cty23),
    format = "file"
  ),
  tar_target(
    df_retired_cty,
    get_retired_ctys(df_raw_cty18, df_raw_cty23)
  ),
  tar_target(
    csv_retired_ctys,
    retired_ctys_csv(df_retired_cty),
    format = "file"
  ),
  tar_target(
    data_raw_icb23,
    here::here("data_raw", "LSOA_(2021)_to_Sub_ICB_Locations_to_Integrated_Care_Boards_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(
    df_icb23,
    mk_lookup_icb23(data_raw_icb23)
  ),
  tar_target(
    csv_lookup_icb23,
    lookup_icb23_csv(df_icb23),
    format = "file"
  ),
  tar_target(
    lookup_proj_id,
    mk_lookup_proj()
  ),
  tar_target(
    csv_lookup_proj_id,
    lookup_proj_csv(lookup_proj_id),
    format = "file"
  ),
  tar_target(
    lookup_lad18_lad23,
    mk_lookup_lad18_lad23()
  ),
  tar_target(
    csv_lad18_lad23,
    lookup_lad18_lad23_csv(lookup_lad18_lad23),
    format = "file"
  )
)
# nolint end: line_length_linter
