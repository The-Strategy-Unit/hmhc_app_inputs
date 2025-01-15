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
  tar_target(data_raw_very_old, here::here("data_raw", "englandevo2023.csv"),
    format = "file"
  ),
  tar_target(df_raw_very_old, read_very_old(data_raw_very_old)),
  tar_target(df_very_old, process_very_old(df_raw_very_old))
)
