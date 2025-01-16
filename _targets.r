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
    here::here("R", "read_area_lookups.r"),
    here::here("R", "read_icb_lookup.r")
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
  tar_target(df_very_old, process_very_old(df_raw_very_old)),
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
  tar_target(df_lifetbl, process_life_tables(lt_paths), pattern = map(lt_paths)),
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
  tar_target(df_snpp, process_snpp(snpp_paths), pattern = map(snpp_paths)),
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
  tar_target(df_npp, process_npp(npp_paths), pattern = map(npp_paths)),
  tar_target(data_raw_npp_codes, here::here("data_raw", "npp_2018b", "NPP codes.txt"),
    format = "file"
  ),
  tar_target(df_npp_codes, process_npp_codes(data_raw_npp_codes, "npp_2018b_codes.csv")),
  tar_target(data_raw_mye_lad, here::here("data_raw", "nomis_mye_lad_1991to2023_20250116.csv"),
    format = "file"
  ),
  tar_target(df_mye_lad, process_mye_lad(data_raw_mye_lad)),
  #############################################################################
  # read-in area lookups
  #############################################################################
  tar_target(data_raw_lad18, here::here("data_raw", "LAD_(Dec_2018)_Names_and_Codes_in_the_United_Kingdom.csv"),
    format = "file"
  ),
  tar_target(df_raw_lad18, read_lad18(data_raw_lad18, "local_authority_districts_2018.csv")),
  tar_target(data_raw_lad22, here::here("data_raw", "LAD_(Dec_2022)_Names_and_Codes_in_the_United_Kingdom.csv"),
    format = "file"
  ),
  tar_target(df_raw_lad22, read_lad22(data_raw_lad22, "local_authority_districts_2022.csv")),
  tar_target(data_raw_lad23, here::here("data_raw", "LAD_(Apr_2023)_Names_and_Codes_in_the_United_Kingdom.csv"),
    format = "file"
  ),
  tar_target(df_raw_lad23, read_lad23(data_raw_lad23, "local_authority_districts_2023.csv")),
  tar_target(data_raw_cty18, here::here("data_raw", "Local_Authority_District_to_County_(December_2018)_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(df_raw_cty18, read_cty18(data_raw_cty18, "lookup_lad2018_cty.csv")),
  tar_target(data_raw_cty22, here::here("data_raw", "Local_Authority_District_to_County_(December_2022)_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(df_raw_cty22, read_cty22(data_raw_cty22, "lookup_lad2022_cty.csv")),
  tar_target(data_raw_cty23, here::here("data_raw", "Local_Authority_District_to_County_(April_2023)_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(df_raw_cty23, read_cty23(data_raw_cty23, "lookup_lad2023_cty.csv")),
  tar_target(df_retired_cty, get_retired_ctys(df_raw_cty18, df_raw_cty23, "retired_ctys_2018_2023.csv")),
  tar_target(data_raw_icb23, here::here("data_raw", "LSOA_(2021)_to_Sub_ICB_Locations_to_Integrated_Care_Boards_Lookup_in_England.csv"),
    format = "file"
  ),
  tar_target(df_icb23, read_icb23(data_raw_icb23, "lookup_lad2023_icb.csv"))
)
# nolint end: line_length_linter