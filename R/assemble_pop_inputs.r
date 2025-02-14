# README
# assemble data files for population pyramid interactive viz (JSON format)

# functions ----
# build_pop_data
# format_pop_data_json

# build_pop_data() ----
build_pop_data <- function(mye, snpp, first_proj_yr = 2023) {

  # mid-year estimates
  pop_est <- mye |>
    dplyr::rename(mf = sex) |>
    dplyr::mutate(
      variant = factor("v0", levels = variant_id_levels),
      # round population to integer
      pop = round(pop)
    ) |>
    dplyr::arrange(area_code, area_name, variant, year, age)

  # projections
  pop_proj <- snpp |>
    # important!
    dplyr::select(-tar_group) |>
    dplyr::filter(
      # important! pre-2023 will be replaced by mye
      year >= first_proj_yr,
      id %in% app_variants
    ) |>
    dplyr::left_join(lookup_variant_id, dplyr::join_by(id == proj_id)) |>
    dplyr::rename(mf = sex, variant = variant_id) |>
    dplyr::mutate(
      variant = factor(variant, levels = variant_id_levels),
      # round population to integer
      pop = round(pop)
    ) |>
    dplyr::select(-id) |>
    dplyr::relocate(area_name, .after = area_code) |>
    dplyr::arrange(area_code, area_name, variant, year, age)

  dplyr::bind_rows(pop_est, pop_proj)
}

# format_pop_data_json() ----
format_pop_data_json <- function(df) {

  df_json <- df |>
    # important!
    dplyr::select(-tar_group) |>
    tidyr::nest(
      .by = c(tidyselect::starts_with("area"), variant, year),
      .key = "data"
    ) |>
    dplyr::mutate(
      data = purrr::map(
        data, \(x) {
          x |>
            tidyr::pivot_wider(names_from = mf, values_from = pop)
        }
      )
    ) |>
    # add totals
    dplyr::mutate(
      totals = purrr::map(
        data, \(x) {
          x |>
            dplyr::select(-age) |>
            dplyr::summarise(dplyr::across(c(f, m), \(y) sum(y))) |>
            jsonlite::unbox()
        }
      )
    ) |>
    dplyr::relocate(data, .after = totals) |>
    dplyr::select(-area_name) |>
    dplyr::arrange(variant, year)

  jsonlite::write_json(
    df_json,
    here::here(
      "data",
      "app_input_files",
      "pyramid",
      paste0(df_json$area_code[[1]], ".json")
    )
  )
}
