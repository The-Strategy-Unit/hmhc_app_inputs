# README
# Create a mapping from local authority districts to integrated care boards
# Methods:
# icb23 |> distinct(icb23nm) # 42 icbs
# icb23 |> distinct(lad23cd, lad23nm) # 296 lads
# Allocate LADs exclusively to ICBs based on number of LSOAs in an LAD
# i.e., if more than 50% of the LSOAs in LAD A are associated with ICB A then
# LAD A is mapped to ICB A
# Most LADs are completely or predominantly associated with a single ICB (284/296) # nolint: line_length_linter.
# East Suffolk, Waverley, Hart, and Westmorland and Furness are potential
# problems, but all other LADs have more than 84% of their LSOAs associated with
# a single ICB. North Yorkshire is split 3 ways, all other splits are 2 way.
# icb23 |>
#   group_by(icb23nm, lad23nm) |>
#   summarise(n = n()) |>
#   group_by(lad23nm) |>
#   mutate(freq = n / sum(n)) |>
#   filter(freq < 1) |>
#   arrange(lad23nm) |>
#   print(n = 25)

# read ICBs 2023 ----
read_icb23 <- function(filenm, filenm_out) {
  readr::read_csv(filenm) |>
    dplyr::group_by(ICB23CD, ICB23NM, LAD23CD, LAD23NM) |>
    dplyr::summarise(n = dplyr::n()) |>
    dplyr::group_by(LAD23NM) |>
    dplyr::mutate(freq = n / sum(n)) |>
    dplyr::filter(freq == max(freq)) |>
    dplyr::ungroup() |>
    dplyr::rename_with(tolower, .cols = everything()) |>
    dplyr::select(lad23cd, lad23nm, icb23cd, icb23nm) |>
    readr::write_csv(here::here("data", filenm_out))
}
