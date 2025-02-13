# README
# create area code directories

# area codes ----
# areas_path <- here::here("data", "app_input_files", "area_names_and_codes.csv") # nolint: line_length_linter.

# dirs <- readr::read_csv(areas_path) |>
#   dplyr::pull(cd)

# only run once
# check 'year' folder exists
# purrr::map(dirs, \(x) dir.create(here::here("data", "2022", x)))
