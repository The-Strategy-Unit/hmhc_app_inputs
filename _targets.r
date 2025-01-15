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
    here::here("R", "read_npp_2018b.r")
  )
)

# target list ----
list(
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
  tar_target(df_npp_codes, process_npp_codes(data_raw_npp_codes, "npp_2018b_codes.csv"))
)
