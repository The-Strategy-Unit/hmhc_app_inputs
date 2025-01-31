# README
# assemble data files for activity profiles interactive viz (JSON format)

# TODO
# think about base_year argument in observed profiles
# think about area_codes argument in format_profiles_json
# incorporate code for generating review plots into pipeline
source(here::here("R", "hsa_helper_fns.r")) # path_closure()
source(here::here("R", "hsa_create_gams.r")) # run_area_gams()

# functions ----
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

# run_gams_all_areas ----
run_gams_all_areas <- function(area_codes, base_year) {
  purrr::map(
    area_codes, \(x) {
      run_area_gams(x, base_year)
    }
  )
}
# run_gams_all_areas(area_codes, 2022)

# get_observed_profiles ----
get_observed_profiles <- function(
  df_mye_series_to90, df_prep_edc, df_prep_apc, df_prep_opc, base_year = 2022
) {

  pop_df <- df_mye_series_to90 |>
    dplyr::filter(year == base_year)

  act_df <- dplyr::bind_rows(df_prep_edc, df_prep_apc, df_prep_opc)

  act_df |>
    dplyr::select(-tar_group) |>
    dplyr::filter(hsagrp %in% app_hsagrps) |>
    dplyr::left_join(
      pop_df,
      dplyr::join_by(area_code, area_name, sex, age)
    ) |>
    dplyr::mutate(urt = n / pop) |>
    dplyr::left_join(
      hsagrp_labels,
      dplyr::join_by(hsagrp)
    ) |>
    dplyr::mutate(hsagrp = factor(hsagrp, levels = hsagrp_levels)) |>
    dplyr::arrange(area_code, area_name, hsagrp)
}

# get_modeled_profiles ----
get_modeled_profiles <- function(area_codes, base_year) {
  profiles_ls <- purrr::map(
    area_codes, \(x) {
      path_self <- path_closure(x, base_year)
      readr::read_csv(
        path_self("model_rt_tbl.csv"),
        show_col_types = FALSE
      )
    }
  )

  dplyr::bind_rows(profiles_ls)
}

combine_profiles <- function(df_obs_rt, df_model_rt) {
  df_obs_rt |>
    dplyr::left_join(
      df_model_rt |>
        dplyr::rename(s = gam_rt),
      dplyr::join_by(area_code, setting, hsagrp, sex, age)
    ) |>
    dplyr::select(area_code, setting, hsagrp, hsagrp_lab, sex, age, urt, s) |>
    dplyr::rename(group = hsagrp, label = hsagrp_lab)
}

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

# review plots ----
# compare local observed rates with England rates
# plot_urts <- function(eng_urt, area_urt) {
#   ggplot2::ggplot() +
#     ggplot2::geom_line(
#       ggplot2::aes(x = age, y = urt, group = sex),
#       color = "#a9adb0",
#       data = eng_urt
#     ) +
#     ggplot2::geom_line(
#       ggplot2::aes(x = age, y = urt, group = sex, color = sex),
#       show.legend = FALSE,
#       data = area_urt
#     ) +
#     ggplot2::facet_wrap(ggplot2::vars(hsagrp), scales = "free_y") +
#     ggplot2::scale_color_manual(values = c("#fd484e", "#2c74b5"))
# }

# area_codes <- area_codes[!area_codes == "E92000001"]

# plot_ls <- purrr::map2("E92000001", area_codes,
#   \(x, y) {
#     i <- urt_dat |> dplyr::filter(area_code == x)
#     j <- urt_dat |> dplyr::filter(area_code == y)
#     plot_urts(i, j)
#   }
# )

# names(plot_ls) <- area_codes

# walk2(
#   plot_ls, names(plot_ls),
#   \(x, y) {
#     ggplot2::ggsave(
#       here::here("data", "2022", y, paste0(y, "_review_urt.png")),
#       x,
#       width = 400,
#       height = 300,
#       units = "mm"
#     )
#   }
# )
