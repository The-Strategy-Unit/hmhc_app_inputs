

read_area_codes <- function(path) {
  readr::read_csv(path) |>
    dplyr::pull(cd)
}
