# README
# test validity of custom variant populations

# load custom functions
source(here::here("R", "read_pop_mye.r"))
source(here::here("R", "read_very_old.r"))
source(here::here("R", "make_mye_series.r"))
source(here::here("R", "read_npp_2018b.r"))
source(here::here("R", "read_snpp_2018b.r"))
source(here::here("R", "make_snpp_2018b_custom_vars.r"))
source(here::here("R", "helper_lookups.r"))

# a) test consistency of custom variant population total ranking v. npp rank by lad # nolint: line_length_linter.
# pick a year to test
rng_year <- sample(seq(2019, 2043), size = 1L)
test_yr <- as.character(rng_year)

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

# this has no principal projection
custom_rnk <- snpp_custom_vars |>
  dplyr::filter(year == test_yr) |>
  dplyr::group_by(area_code, area_name, id) |>
  dplyr::summarise(pop = sum(pop)) |>
  dplyr::arrange(pop, .by_group = TRUE) |>
  dplyr::mutate(cust_rnk = dplyr::row_number()) |>
  dplyr::ungroup()

# remove principal projection
npp_rnk <- df_npp |>
  # filter out principal projection
  dplyr::filter(year == test_yr, id != "ppp") |>
  dplyr::group_by(id) |>
  dplyr::summarise(pop = sum(pop)) |>
  dplyr::arrange(pop, .by_group = TRUE) |>
  dplyr::mutate(npp_rnk = dplyr::row_number()) |>
  dplyr::select(id, npp_rnk)

rnk_diff <- custom_rnk |>
  dplyr::left_join(npp_rnk, dplyr::join_by(id)) |>
  dplyr::mutate(rnk_diff = cust_rnk - npp_rnk) |>
  dplyr::arrange(rnk_diff)

testthat::test_that("test consistency of custom variant ranking v. npp rank by lad", { # nolint: line_length_linter.
  max_diff <- max(abs(rnk_diff$rnk_diff))
  testthat::expect_lte(max_diff, 3L)
})

# b) test difference between population totals for variants that are in both
# new custom variants set and original snpp set by lad
custom_vars <- snpp_custom_vars |>
  dplyr::filter(id %in% c("pph", "ppl")) |>
  dplyr::filter(year == test_yr) |>
  dplyr::group_by(area_code, area_name, id) |>
  dplyr::summarise(pop = sum(pop)) |>
  dplyr::ungroup()

snpp_vars <- df_snpp |>
  dplyr::filter(id %in% c(
    "var_proj_low_intl_migration",
    "var_proj_high_intl_migration"
  )) |>
  dplyr::filter(year == test_yr) |>
  dplyr::left_join(lookup_proj, dplyr::join_by(id == proj_id)) |>
  dplyr::group_by(id, proj_map, area_code, area_name) |>
  dplyr::summarise(pop = sum(pop)) |>
  dplyr::ungroup()

vars_diff <- custom_vars |>
  dplyr::left_join(
    snpp_vars,
    dplyr::join_by(id == proj_map, area_code, area_name)
  ) |>
  dplyr::mutate(diff = (pop.x / pop.y - 1) * 100) |>
  dplyr::arrange(diff) |>
  dplyr::select(-id.y)

# plot differences
p1 <- vars_diff |>
  dplyr::mutate(
    id = factor(id),
    area_name = tidytext::reorder_within(area_name, diff, within = id)
  ) |>
  ggplot2::ggplot() +
  ggplot2::geom_point(ggplot2::aes(x = area_name, y = diff, color = id)) +
  tidytext::scale_x_reordered() +
  ggplot2::facet_wrap(ggplot2::vars(id), scales = "free_x") +
  ggplot2::theme(
    axis.text.x = ggplot2::element_text(angle = 90)
  )

ggplot2::ggsave(here::here("figures", "test_snpp_2018b_custom_vars.png"), p1)

testthat::test_that("test difference between variants that are in both new
  custom variants set and original snpp set by lad", {
    mxdiff <- max(abs(vars_diff$diff))
    mndiff <- mean(abs(vars_diff$diff))
    testthat::expect_lte(mxdiff, 10)
    testthat::expect_lte(mndiff, 2)
  }
)
