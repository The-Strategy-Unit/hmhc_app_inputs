# README

read_pop_data <- list(
  tar_option_set(description = "read"),
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
  )
)
