# README
# assemble data files for population pyramid interactive viz (JSON format)

# functions ----
# build_pop_data
# format_pop_data_json

# keeping these here for now ----
# projection variants for app
app_vars <- c(
  "hpp", # 1
  "lpp", # 2
  "php", # 3
  "plp", # 4
  "hhh", # 5
  "lll", # 6
  "lhl", # 7
  "hlh", # 8
  "principal_proj", # 9
  "var_proj_high_intl_migration", # 10
  "var_proj_low_intl_migration" # 11
)

# lookup id to identify variant in the app
lookup_variant_id <- tibble::tribble(
  ~"proj_id", ~"vars_id",
  "principal_proj", "v1", # 1
  "hpp", "v2", # 2
  "lpp", "v3", # 3
  "php", "v4", # 4
  "plp", "v5", # 4
  "var_proj_high_intl_migration", "v6", # 6
  "var_proj_low_intl_migration", "v7", # 7
  "hhh", "v8", # 8
  "lll", "v9", # 9
  "hlh", "v10", # 10
  "lhl", "v11" # 11
)

# historic population estimates take level = v0
levels_variant_id <- c(paste0("v", 0:11))

# build_pop_data() ----
build_pop_data <- function(mye, snpp, first_proj_yr = 2023) {

  # mid-year estimates
  pop_est <- mye |>
    dplyr::rename(mf = sex) |>
    dplyr::mutate(
      variant = factor("v0", levels = levels_variant_id),
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
      id %in% app_vars
    ) |>
    dplyr::left_join(lookup_variant_id, dplyr::join_by(id == proj_id)) |>
    dplyr::rename(mf = sex, variant = vars_id) |>
    dplyr::mutate(
      variant = factor(variant, levels = levels_variant_id),
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
    dplyr::select(-area_name)

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
