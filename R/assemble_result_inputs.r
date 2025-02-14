# README
# assemble data files for model results interactive viz (JSON format)
# requires compiling results from 3 types of model
# a) pure demographic model
# b) hsa mode only model
# c) hsa monte carlo model

# functions ----
# pretty_fd
# compute_binning
# nomc_grp_sex
# mc_grp_sex
# join_res_dfs
# format_results_json

# pretty_fd() ----
# helper fn for breaks using pretty version of Freedman Diaconis rule
# param: x, type:
# returns: df,
# rtype: df
pretty_fd <- function(x) {

  if (max(x) - min(x) < .1) {

    brks <- pretty(range(x), n = 20, min.n = 1)
    ints <- cut(x, breaks = brks, right = FALSE)

  } else {

    brks <- pretty(
      range(x),
      n = grDevices::nclass.FD(x, digits = 5),
      min.n = 1
    )

    ints <- cut(x, breaks = brks, right = FALSE)
  }

  df <- tibble::tibble(
    x0 = head(brks, -1),
    x1 = tail(brks, -1),
    freq = summary(ints, maxsum = 200)
  )

  return(df)
}

# compute_binning() ----
# compute histogram binning
# param: df, type: df
# returns: df,
# rtype: df
compute_binning <- function(df) {
  df |>
    dplyr::select(-end_n) |>
    dplyr::mutate(end_p = purrr::map(end_p, \(x) 100 * x - 100)) |>
    dplyr::group_by(dplyr::across(-end_p)) |>
    dplyr::mutate(end_p = purrr::map(end_p, \(i) pretty_fd(i))) |>
    dplyr::ungroup()
}

# nomc_grp_sex() ----
# group f/m split to persons, models without monte carlo
# param: df, type: df, model results by sex
# returns: a dataframe of model results by area code, projection variant, end
# year, setting, and hsa group
# rtype: df
nomc_grp_sex <- function(df) {
  df |>
    dplyr::group_by(area_code, id, end_year, setting, hsagrp) |>
    dplyr::summarise(dplyr::across(tidyselect::ends_with("n"), sum)) |>
    dplyr::ungroup() |>
    dplyr::mutate(end_p = end_n / base_n)
}

# mc_grp_sex() ----
# group f/m split to persons, monte carlo models
# param: df, type: df, model results by sex
# returns: a dataframe of model results by area code, projection variant, end
# year, setting, and hsa group
# rtype: df
mc_grp_sex <- function(df) {
  df |>
    dplyr::group_by(area_code, id, end_year, setting, hsagrp) |>
    dplyr::group_modify(
      ~ {
        .x |>
          dplyr::summarise(
            base_n = sum(base_n),
            end_n = list(rowSums(sapply(end_n, unlist)))
          )
      }
    ) |>
    dplyr::ungroup() |>
    dplyr::mutate(end_p = purrr::map2(base_n, end_n, \(x, y) y / x))
}

# join_res_dfs() ----
# combine results from 3 model types into a single dataframe
# param: pure_demo, type: df, results from pure demographic models
# param: hsa_mode, type: df, results from hsa mode models
# param: hsa_mc, type: df, results from hsa monte carlo models
# returns: a dataframe with results from all 3 model types
# rtype: df
join_res_dfs <- function(pure_demo, hsa_mode, hsa_mc) {
  pure_demo |>
    dplyr::select(-tidyselect::ends_with("n")) |>
    dplyr::rename(demo_p = end_p) |>
    dplyr::left_join(
      hsa_mode |>
        dplyr::select(-tidyselect::ends_with("n")) |>
        dplyr::rename(hsamd_p = end_p),
      dplyr::join_by(area_code, id, end_year, setting, hsagrp)
    ) |>
    dplyr::left_join(
      hsa_mc |>
        dplyr::select(-tidyselect::ends_with("n")) |>
        dplyr::rename(hsamc_p = end_p),
      dplyr::join_by(area_code, id, end_year, setting, hsagrp)
    )
}

# format_results_json() ----
# create data files for model results dataviz
# param: df, type: df, results from all 3 model types
# returns:
# saves: a JSON file for each area code with model results formatted for the app
# stype: JSON
format_results_json <- function(df) {

  df_json <- df |>
    dplyr::filter(
      id %in% app_variants,
      hsagrp %in% app_hsagrps
    ) |>
    dplyr::left_join(
      lookup_hsagrp_label,
      dplyr::join_by(hsagrp)
    ) |>
    dplyr::left_join(
      lookup_variant_id,
      dplyr::join_by(id == proj_id)
    ) |>
    dplyr::select(-id) |>
    dplyr::mutate(
      variant_id = factor(variant_id, levels = variant_id_levels),
      hsagrp = factor(hsagrp, levels = hsagrp_levels)
    ) |>
    dplyr::mutate(
      dplyr::across(
        c(demo_p, hsamd_p),
        ~ 100 * .x - 100
      )
    ) |>
    dplyr::rename(
      variant = variant_id,
      pod = setting,
      group = hsagrp,
      label = hsagrp_label,
      data = hsamc_p
    ) |>
    dplyr::select(
      area_code,
      variant, end_year, pod, group, label,
      demo_p, hsamd_p, data
    ) |>
    dplyr::arrange(group, end_year, variant)

  jsonlite::write_json(
    df_json,
    here::here(
      "data",
      "app_input_files",
      "results",
      paste0(df_json$area_code[[1]], ".json")
    )
  )
}
