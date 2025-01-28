# README
# assemble data files for model results interactive viz (JSON format)
# requires compiling results from 3 models
# a) pure demographic model (demo)
# b) hsa mode model (hsamd)
# c) hsa monte carlo model (hsamc)
# TODO
# make area names and codes part of pipeline
# hsamc results for omit hsagrps are NA can I remedy this
# what's shared with assemble activity and population scripts?
# include in pipeline
# log script?
# progress bars
# time - parallelise?

# dependencies ----
source(here::here("R", "hsa_get_results.r"))
source(here::here("R", "hsa_get_factors.r"))
source(here::here("R", "hsa_helper_fns.r"))

# functions ----
# pretty_fd
# demo_models_grp_sex
# hsamc_models_grp_sex
# comp_bins
# combine_results
# format_model_json

# keeping these here for now ----
# proj id to variant id
lookup_variant_id <- tibble::tribble(
  ~ "proj_id", ~ "variant_id",
  "principal_proj", "v1",
  "hpp", "v2",
  "lpp", "v3",
  "php", "v4",
  "plp", "v5",
  "var_proj_high_intl_migration", "v6",
  "var_proj_low_intl_migration", "v7",
  "hhh", "v8",
  "lll", "v9",
  "hlh", "v10",
  "lhl", "v11"
)

# proj id levels
proj_id_levels <- lookup_variant_id$proj_id

# hsa group levels
hsagrp_levels <- c(
  "walkin", # 1
  "amb", # 2
  "emer_n", # 3
  "emer_bds", # 4
  "daycase_n", # 5
  "ordelec_n", # 6
  "ordelec_bds", # 7
  "surg_proc", # 8
  "non-surg_proc", # 9
  "surg_first", # 10
  "non-surg_first", # 11
  "surg_fup", # 12
  "non-surg_fup" # 13
)

# hsa group labels
lookup_hsagrp_label <- tibble::tribble(
  ~ "hsagrp", ~ "hsagrp_label",
  "amb", "Ambulance arrivals", # 1
  "walkin", "Walk-in arrivals", # 2
  "daycase_n", "Daycases", # 3
  "emer_n", "Unplanned admissions", # 4
  "emer_bds", "Unplanned bed days", # 5
  "ordelec_n", "Elective admissions", # 6
  "ordelec_bds", "Elective bed days", # 7
  "non-surg_first", "First app. (non-surgical specialties)", # 8
  "non-surg_fup", "Follow-up app. (non-surgical specialties)", # 9
  "non-surg_proc", "Procedure (non-surgical specialties)", # 10
  "surg_first", "First app. (surgical specialties)", # 11
  "surg_fup", "Follow-up app. (surgical specialties)", # 12
  "surg_proc", "Procedure (surgical specialties)" # 13
)

# run models for these projection variants
app_variants <- c(
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

# keep models for these hsagrps
app_hsagrps <- c(
  "amb", # 1
  "walkin", # 2
  "daycase_n", # 3
  "emer_n", # 4
  "emer_bds", # 5
  "ordelec_n", # 6
  "ordelec_bds", # 7
  "non-surg_first", # 8
  "non-surg_fup", # 9
  "non-surg_proc", # 10
  "surg_first", # 11
  "surg_fup", # 12
  "surg_proc" #13
)

# for testing
test_areas <- c(
  "E08000026",
  "E07000235",
  "E09000030",
  "E92000001"
)

# compute histogram binning using pretty version of Freedman Diaconis rule ----
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

# group-up sex results ----
demo_models_grp_sex <- function(df) {
  df |>
    dplyr::group_by(area_code, id, end_year, setting, hsagrp) |>
    dplyr::summarise(dplyr::across(tidyselect::ends_with("n"), sum)) |>
    dplyr::ungroup() |>
    dplyr::mutate(end_p = end_n / base_n)
}

hsamc_models_grp_sex <- function(df) {
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

# compute binning ----
comp_bins <- function(df) {
  df |>
    dplyr::select(-end_n) |>
    dplyr::group_by(dplyr::across(-end_p)) |>
    dplyr::mutate(end_p = purrr::map(end_p, \(i) pretty_fd(i))) |>
    dplyr::ungroup()
}

# combine model results ----
combine_results <- function(x, y, z) {
  x |>
    dplyr::select(-tidyselect::ends_with("n")) |>
    dplyr::rename(demo_p = end_p) |>
    dplyr::left_join(
      y |>
        dplyr::select(-tidyselect::ends_with("n")) |>
        dplyr::rename(hsamd_p = end_p),
      dplyr::join_by(area_code, id, end_year, setting, hsagrp)
    ) |>
    dplyr::left_join(
      z |>
        dplyr::select(-tidyselect::ends_with("n")) |>
        dplyr::rename(hsamc_p = end_p),
      dplyr::join_by(area_code, id, end_year, setting, hsagrp)
    )
}

# format df ready to save as JSON
format_model_json <- function(df) {

  df_json <- df |>
    dplyr::filter(hsagrp %in% app_hsagrps) |>
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
      hsagrp = factor(hsagrp, levels = hsagrp_levels),
    ) |>
    dplyr::mutate(
      dplyr::across(
        c("demo_p", "hsamd_p"),
        ~ 100 * .x - 100
      )
    ) |>
    dplyr::rename(
      variant = variant_id,
      group = hsagrp,
      label = hsagrp_label,
      data = hsamc_p
    ) |>
    dplyr::select(
      area_code,
      variant, end_year, setting, group, label,
      demo_p, hsamd_p, data
    ) |>
    dplyr::arrange(group)

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

# run models for these areas ----
area_codes <- readr::read_csv(
  here::here("data", "app_input_files", "area_names_and_codes.csv")
) |>
  dplyr::pull(cd)

area_codes <- test_areas

# model parameters ----
# 360 areas x 11 variants x 4 horizons = 15,840 models
# plus 1000 simulations for each run of the full hsa model
model_params <- tidyr::expand_grid(app_variants, area_codes) |>
  dplyr::select(area_code = area_codes, proj_id = app_variants) |>
  dplyr::group_by(dplyr::across(tidyselect::everything())) |>
  tidyr::expand(base_year = 2022L, end_year = seq(2025L, 2040L, 5L)) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    model_runs = 1e3,
    rng_state = 014796
  ) |>
  dplyr::mutate(proj_id = factor(proj_id, levels = proj_id_levels)) |>
  dplyr::arrange(area_code, proj_id, base_year, end_year)

# a) pure demographic model ----
model_params_nomc  <- model_params |>
  dplyr::select(-model_runs, -rng_state)

demo_models <- purrr::pmap(
  model_params_nomc,
  get_demographic_chg,
  # add a progress bar
  .progress = list(
    clear = TRUE,
    format = "Pure demographic model: {cli::pb_bar} {cli::pb_percent} | ETA: {cli::pb_eta}", # nolint: line_length_linter.
    type = "iterator"
  )
)

# hsa mode model ----
hsamd_models <- purrr::pmap(
  model_params_nomc,
  get_hsa_chg,
  method = "interp",
  mode = TRUE,
  .progress = list(
    clear = TRUE,
    format = "HSA mode only model: {cli::pb_bar} {cli::pb_percent} | ETA: {cli::pb_eta}", # nolint: line_length_linter.
    type = "iterator"
  )
)

# hsa monte carlo model ----
hsamc_models <-  purrr::pmap(
  model_params,
  get_hsa_chg,
  method = "interp",
  mode = FALSE,
  .progress = list(
    clear = TRUE,
    format = "HSA full model: {cli::pb_bar} {cli::pb_percent} | ETA: {cli::pb_eta}", # nolint: line_length_linter.
    type = "iterator"
  )
)

# group by sex results
demo_models <- purrr::map(demo_models, demo_models_grp_sex)
hsamd_models <- purrr::map(hsamd_models, demo_models_grp_sex)
hsamc_models <- purrr::map(hsamc_models, hsamc_models_grp_sex)

# can we figure out how to remove this?
hsamc_models <- purrr::map(
  hsamc_models,
  \(x) {
    x |>
      dplyr::filter(hsagrp %in% app_hsagrps)
  }
)

# histogram bins
hsamc_models <- purrr::map(hsamc_models, \(x) comp_bins(x))

# combine models
res_ls <- purrr::pmap(
  list(demo_models, hsamd_models, hsamc_models),
  \(x, y, z) combine_results(x, y, z)
)

# row bind list elements for the same area
names(res_ls) <- tidyr::unite(
  model_params,
  params,
  tidyselect::everything(),
  sep = "-"
) |>
  dplyr::pull(params)

res_ls <- split(res_ls, stringr::str_extract(names(res_ls), "^E[0-9]{8}")) |>
  purrr::map(dplyr::bind_rows)

# save
purrr::map(res_ls, \(x) format_model_json(x))
