

read_area_codes <- function(path) {
  readr::read_csv(path) |>
    dplyr::slice_head(n = 10) |>
    dplyr::pull(cd)
}
