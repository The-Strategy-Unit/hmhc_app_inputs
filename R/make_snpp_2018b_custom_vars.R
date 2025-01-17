# README
# make a set of x17 custom snpp variants
# x4 variant projections were published for snpp 2018b
# x17 variant projections were published for npp 2018b
# custom snpp variants are created by applying the % difference between npp
# variants and the npp principal (by age/sex/year) to the snpp principal

# make custom variants ----
mk_custom_vars <- function(npp, snpp) {

  ref <- npp |>
    # snpp end at 2043
    dplyr::filter(year %in% 2018:2043) |>
    dplyr::mutate(
      age = dplyr::case_when(
        age > 90 ~ 90L,
        TRUE ~ as.integer(age)
      )
    ) |>
    # re-sum by age
    dplyr::group_by(dplyr::across(c(-area, -pop))) |>
    dplyr::summarise(pop = sum(pop)) |>
    dplyr::ungroup()

  mx <- ref |>
    dplyr::left_join(
      ref |>
        dplyr::filter(id == "ppp") |>
        dplyr::rename(ppp = pop) |>
        dplyr::select(-id),
      dplyr::join_by("year", "sex", "age")
    ) |>
    dplyr::mutate(mx = pop / ppp) |>
    dplyr::ungroup() |>
    dplyr::filter(id != "ppp") |>
    dplyr::select(-ppp, -pop)

  purrr::map(mx |> dplyr::group_split(id), \(x) {
    x |>
      dplyr::left_join(
        snpp |>
          dplyr::filter(id == "principal_proj") |>
          dplyr::select(-id),
        dplyr::join_by("year", "sex", "age"), multiple = "all"
      ) |>
      dplyr::mutate(new_pop = mx * pop, .before = pop) |>
      dplyr::select(-pop, -mx) |>
      dplyr::rename(pop = new_pop)
  }) |>
    purrr::list_rbind()

  # run some tests
  # source(here("R/tests", "test_build_snpp_2018b_custom_variants.R"), local = TRUE) # nolint: line_length_linter, commented_code_linter.
}
