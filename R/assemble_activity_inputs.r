# README
# assemble data files for activity profiles interactive viz (JSON format)

# functions ----
# create_obs_rt_df_all_areas
# run_gams_all_areas
# get_observed_profiles
# get_modeled_profiles
# combine_profiles
# format_profiles_json

# ***********************
# test or production ----
# ***********************
test <- TRUE

if (!rlang::is_logical(test)) {
  stop("test must be of type logical")
} else {
  area_codes <- test_areas
}

# create_obs_rt_df_all_areas() ----
create_obs_rt_df_all_areas <- function(area_codes, base_year) {
  purrr::map(
    area_codes, \(x) {
      create_obs_rt_df(x, base_year)
    }
  )
}

# run_gams_all_areas() ----
run_gams_all_areas <- function(area_codes, base_year) {
  purrr::map(
    area_codes, \(x) {
      run_area_gams(x, base_year)
    }
  )
}

# get_observed_profiles() ----
get_observed_profiles <- function(area_codes, base_year) {
  profiles_ls <- purrr::map(
    area_codes, \(x) {
      path_self <- path_closure(x, base_year)
      readr::read_csv(
        path_self("obs_rt_df.csv"),
        show_col_types = FALSE
      )
    }
  )

  dplyr::bind_rows(profiles_ls)
}

# get_modeled_profiles() ----
get_modeled_profiles <- function(area_codes, base_year) {
  profiles_ls <- purrr::map(
    area_codes, \(x) {
      path_self <- path_closure(x, base_year)
      readr::read_csv(
        path_self("model_rt_df.csv"),
        show_col_types = FALSE
      )
    }
  )

  dplyr::bind_rows(profiles_ls)
}

# combine_profiles() ----
combine_profiles <- function(obs_rt_df, model_rt_df) {
  obs_rt_df |>
    dplyr::left_join(
      model_rt_df |>
        dplyr::rename(s = gam_rt),
      dplyr::join_by(area_code, setting, hsagrp, sex, age)
    ) |>
    dplyr::left_join(
      lookup_hsagrp_label,
      dplyr::join_by(hsagrp)
    ) |>
    dplyr::select(area_code, setting, hsagrp, hsagrp_label, sex, age, urt, s) |>
    dplyr::rename(group = hsagrp, label = hsagrp_label)
}

# format_profiles_json() ----
format_profiles_json <- function(df_rts) {

  df_json <- df_rts |>
    tidyr::nest(
      .by = c(tidyselect::starts_with("area"), setting, group, label),
      .key = "data"
    ) |>
    dplyr::mutate(
      data = purrr::map(
        data, \(x) {
          x |>
            tidyr::pivot_longer(
              c(urt, s), names_to = "var", values_to = "rt"
            ) |>
            tidyr::pivot_wider(
              names_from = c(sex, var),
              names_glue = "{sex}{var}",
              values_from = rt
            ) |>
            dplyr::rename_with(
              \(x) {
                stringr::str_remove(x, "urt")
              },
              .cols = tidyselect::ends_with("urt")
            ) |>
            dplyr::select(age, f, m, fs, ms)
        }
      )
    )

  jsonlite::write_json(
    df_json,
    here::here(
      "data",
      "app_input_files",
      "activity",
      paste0(df_json$area_code[[1]], ".json")
    )
  )
}
