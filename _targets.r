# README
# Created by use_targets()


# packages required to define the pipeline ----
library("targets")
# library(tarchetypes) # nolint: commented_code_linter.

# set target options ----
tar_option_set(
  packages = c(
    "tibble"
  )
)

# run scripts ----
tar_source(
  here::here("R", "read_very_old.r")
)

# target list ----
list(
  tar_target(
    data_raw_very_old,
    here::here("data_raw", "englandevo2023.csv"),
    format = "file",
    description = "population estimates of the very old"
  ),
  tar_target(
    df_raw_very_old,
    read_very_old(data_raw_very_old),
    description = "raw timeseries estimates of the very old"
  ),
  tar_target(
    df_clean_very_old,
    clean_very_old(df_raw_very_old),
    description = "clean timeseries estimates of the very old"
  ),
  tar_target(
    df_impute_very_old,
    impute_very_old(df_clean_very_old),
    description = "imputed timeseries estimates of the very old"
  )
)
