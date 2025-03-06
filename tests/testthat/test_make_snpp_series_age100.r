# README
# Test modeled snpp series 90+ equals npp 90+ by variant

# load custom functions
source("R/read_pop_mye.r")
source("R/read_very_old.r")
source("R/make_mye_series.r")
source("R/read_npp_2018b.r")
source("R/read_snpp_2018b.r")
source("R/make_snpp_2018b_custom_vars.r")
source("R/helper_lookups.r")
source("R/make_snpp_series_age100.r")

snpp_paths <- fs::dir_ls(
  here::here("data_raw"), regexp = "2018 SNPP.*(females|males).*(.csv$)",
  recurse = TRUE
)

df_snpp <- purrr::map(snpp_paths, \(x) prep_snpp(x)) |>
  dplyr::bind_rows()

npp_paths <- fs::dir_ls(
  here::here("data_raw"), regexp = "2018(.xls)$",
  recurse = TRUE
)

df_npp <-  purrr::map(npp_paths, \(x) prep_npp(x)) |>
  dplyr::bind_rows()

snpp_custom_vars <- mk_custom_vars(df_npp, df_snpp)

lookup_proj <- mk_lookup_proj()

snpp_series_to100 <- make_snpp_100(df_npp, df_snpp, lookup_proj)

new_plus90 <- snpp_series_to100 |>
  dplyr::filter(stringr::str_detect(area_code, "^E0[6789]"), age >= 90) |>
  dplyr::group_by(id, year) |>
  dplyr::summarise(pop = sum(pop)) |>
  dplyr::ungroup()

npp_plus90 <- df_npp |>
  dplyr::filter(year <= 2043, age >= 90) |>
  dplyr::group_by(id, year) |>
  dplyr::summarise(pop = sum(pop)) |>
  dplyr::ungroup()

diff_90 <- new_plus90 |>
  dplyr::left_join(lookup_proj, dplyr::join_by(id == proj_id)) |>
  dplyr::left_join(npp_plus90, dplyr::join_by(proj_map == id, year)) |>
  dplyr::mutate(diff = pop.x - pop.y)

testthat::test_that("modeled snpp all areas total 90+ matches original npp 90+ by variant", { # nolint: line_length_linter.
  diff_90 <- max(abs(diff_90 |> dplyr::pull(diff)))
  testthat::expect_lt(diff_90, 1)
})
