# README
# Created by use_targets()

# packages required to define the pipeline ----
library("targets")
library("tarchetypes")

# set target options ----
tar_option_set(
  packages = c(
    "tibble"
  )
)

# run scripts ----
tar_source(
  c(
    here::here("R", "read_very_old.r"),
    here::here("R", "read_life_tables_2018b.r"),
    here::here("R", "read_snpp_2018b.r"),
    here::here("R", "read_npp_2018b.r"),
    here::here("R", "read_pop_mye.r"),
    here::here("R", "read_geog_codes.r"),
    here::here("R", "read_icb_lookup.r"),
    here::here("R", "helper_lookups.r"),
    here::here("R", "make_mye_series.r"),
    here::here("R", "make_snpp_2018b_custom_vars.r"),
    here::here("R", "make_snpp_series.r"),
    here::here("R", "make_snpp_series_age100.r"),
    here::here("R", "edc_read_functions.r"),
    here::here("R", "edc_prep_functions.r"),
    here::here("R", "apc_read_functions.r"),
    here::here("R", "apc_prep_functions.r"),
    here::here("R", "opc_read_functions.r"),
    here::here("R", "opc_prep_functions.r")
  )
)

# nolint start: line_length_linter
# target list ----
list(
  #############################################################################
  # read-in population data
  #############################################################################
  tar_target(data_raw_very_old, here::here("data_raw", "englandevo2023.csv"),
    format = "file"
  ),
  tar_target(df_raw_very_old, read_very_old(data_raw_very_old)),
  tar_target(df_very_old, prep_very_old(df_raw_very_old)),
  # branch over life table files
  tar_files(
    lt_paths,
    list.files(
      here::here("data_raw"),
      "18ex(.xls)$",
      recursive = TRUE,
      full.names = TRUE
    ),
  ),
  tar_target(df_lifetbl, prep_life_tbl(lt_paths), pattern = map(lt_paths)),
  # branch over snpp variants
  tar_files(
    snpp_paths,
    list.files(
      here::here("data_raw"),
      "^(2018 SNPP).*(females|males).*(.csv$)",
      recursive = TRUE,
      full.names = TRUE
    ),
  ),
  tar_target(df_snpp, prep_snpp(snpp_paths), pattern = map(snpp_paths)),
  # branch over npp variants
  tar_files(
    npp_paths,
    list.files(
      here::here("data_raw"),
      "2018(.xls)$",
      recursive = TRUE,
      full.names = TRUE
    ),
  ),
  tar_target(df_npp, prep_npp(npp_paths), pattern = map(npp_paths)),
  tar_target(data_raw_npp_codes, here::here("data_raw", "npp_2018b", "NPP codes.txt"),
    format = "file"
  ),
  tar_target(df_npp_codes, prep_npp_codes(data_raw_npp_codes, here::here("data", "npp_2018b_codes.csv"))),
  tar_target(data_raw_mye, here::here("data_raw", "nomis_mye_lad_1991to2023_20250116.csv"),
    format = "file"
  ),
  tar_target(df_mye, read_mye(data_raw_mye)),
  #############################################################################
  # read-in area lookups
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
  # build population mye series
  #############################################################################
  tar_target(df_mye_to90, mk_mye_to90(df_mye)),
  tar_target(df_mye_to100, mk_mye_to100(df_very_old, df_mye_to90)),
  tar_target(df_mye_series, mk_mye_compl(df_mye_to100, df_raw_lad23, df_raw_cty23, df_icb23)),
  #############################################################################
  # build population projection series
  #############################################################################
  tar_target(snpp_custom_vars, mk_custom_vars(df_npp, df_snpp)),
  tar_target(snpp_series_to90, mk_snpp_series(snpp_custom_vars, df_snpp, lookup_lad18_lad23, df_retired_cty, df_npp, df_icb23)),
  tar_target(snpp_series_to100, make_snpp_100(df_npp, snpp_series_to90, lookup_proj_id)),
  #############################################################################
  # prep activity data
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
  tar_target(df_prep_opc_grp, opc_to_dirs(df_prep_opc), pattern = map(df_prep_opc))
)
# nolint end: line_length_linter
