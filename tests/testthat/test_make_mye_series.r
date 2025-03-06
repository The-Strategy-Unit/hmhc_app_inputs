# README
# test apportionment of local area 85+ and 90+ populations to 0-100+

# load custom functions
source("R/read_pop_mye.r")
source("R/read_very_old.r")
source("R/make_mye_series.r")

# a) test that modeled 90-100+ estimates match original 90+ totals
data_raw_mye <- read_mye(
  here::here(
    "data_raw",
    "nomis_mye_lad_1991to2023_20250116.csv"
  )
)

data_raw_vo  <- read_very_old(
  here::here(
    "data_raw",
    "englandevo2023.csv"
  )
)

mye_plus90 <- data_raw_mye |>
  # omit England
  dplyr::filter(age == "90+", year > 2000L, area_code != "E92000001") |>
  dplyr::group_by(area_code, year, sex) |>
  dplyr::summarise(pop = sum(pop)) |>
  dplyr::pull(pop)

very_old <- prep_very_old(data_raw_vo)
mye_to90 <- mk_mye_to90(data_raw_mye)
mye_to100 <- mk_mye_to100(very_old, mye_to90)

new_plus90 <- mye_to100 |>
  dplyr::filter(age > 89, year > 2000L) |>
  dplyr::group_by(area_code, year, sex) |>
  dplyr::summarise(pop = sum(pop)) |>
  dplyr::pull(pop)

testthat::test_that("modeled 90-100+ estimates match original 90+ totals", {
  testthat::expect_equal(
    var(mye_plus90 - new_plus90),
    0
  )
})

# b) test that modeled 85-90+ estimates match original 85+ totals
mye_plus85 <- data_raw_mye |>
  # omit England
  dplyr::filter(age == "85+", year == 2000L, area_code != "E92000001") |>
  dplyr::group_by(area_code, year, sex) |>
  dplyr::summarise(pop = sum(pop)) |>
  dplyr::pull(pop)

new_plus85 <- mye_to100 |>
  dplyr::filter(age > 84, year == 2000L) |>
  dplyr::group_by(area_code, year, sex) |>
  dplyr::summarise(pop = sum(pop)) |>
  dplyr::pull(pop)

testthat::test_that("modeled 85-90+ estimates match original 85+ totals", {
  testthat::expect_equal(
    var(new_plus85 - mye_plus85),
    0
  )
})
