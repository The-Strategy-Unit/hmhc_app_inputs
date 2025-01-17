# README
# make a set of area population projections (0-100+) for use by the app
# requires reconciling local government changes
# single-year-of-age assumptions:
# snpp 2018b stop at age 90+, npp 2018b stop at age 104 (105-109, 110+)
# we take the 90+ distribution from npp and apply it to snpp to create modeled
# snpp populations for ages 0-100+
# which npp variant should the 90+ distribution come from? Ideally, there exists
# a 1:1 mapping of npp variants to snpp variants. However no mapping exists,so
# we create our own.

# extend snpp to 100+ ----
extend_snpp_100 <- function(npp, snpp, lookup_proj) {

  # extract 90+ distribution from npp
  npp_90plus <- npp |>
    dplyr::filter(year <= 2043) |>
    dplyr::group_by(id) |>
    tidyr::nest() |>
    dplyr::ungroup() |>
    dplyr::mutate(
      npp_90p = purrr::map(data, \(x) {
        x |>
          dplyr::filter(age >= 90) |>
          dplyr::mutate(age = dplyr::case_when(
            age > 100 ~ 100L,
            TRUE ~ as.integer(age)
          )) |>
          dplyr::group_by(dplyr::across(-c(pop))) |>
          dplyr::summarise(pop = sum(pop)) |>
          dplyr::group_by(dplyr::across(-c(age, pop))) |>
          dplyr::mutate(pop_pct = pop / sum(pop)) |>
          dplyr::ungroup() |>
          dplyr::select(year, sex, age, pop_pct)
      })
    ) |>
    dplyr::select(-data)

  # apply npp 90+ distribution to snpp
  snpp |>
    dplyr::group_by(id) |>
    tidyr::nest() |>
    dplyr::mutate(
      snpp_90p = purrr::map(data, \(x) {
        x |>
          dplyr::filter(age == 90L) |>
          dplyr::group_by(area_code, area_name, sex, year) |>
          tidyr::complete(age = 90:100)
      })
    ) |>
    dplyr::left_join(lookup_proj, dplyr::join_by("id" == "proj_id")) |>
    dplyr::left_join(npp_90plus, dplyr::join_by("proj_map" == "id")) |>
    dplyr::mutate(
      snpp_90p = purrr::map2(snpp_90p, npp_90p, \(x, y) {
        x |>
          dplyr::left_join(y, dplyr::join_by("year", "sex", "age")) |>
          dplyr::group_by(area_code, area_name, sex, year) |>
          dplyr::mutate(pop = pop_pct * sum(pop, na.rm = TRUE)) |>
          dplyr::ungroup() |>
          dplyr::select(-pop_pct)
      })
    ) |>
    dplyr::select(-npp_90p, -tidyselect::starts_with("proj"), -ex_id) |>
    dplyr::ungroup() |>
    dplyr::mutate(
      data = purrr::map(data, \(x) {
        x |>
          dplyr::filter(age != 90)
      })
    ) |>
    dplyr::mutate(
      data = purrr::map2(data, snpp_90p, \(x, y) dplyr::bind_rows(x, y))
    ) |>
    dplyr::select(-snpp_90p) |>
    tidyr::unnest(c(data))

  # run some tests
  # source() code is evaluated in the global environment by default
  # set local = TRUE to evaluate the code in the calling environment
  # source(here("R/tests", "test_build_pop_100_inputs.R"), local = TRUE) # nolint: commented_code_linter, line_length_linter.
}
