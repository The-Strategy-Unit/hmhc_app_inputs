# README
# Read-in life tables from 2018-based national population projections
# x2 variant life tables were published alongside the principal

# process ----
process_life_tables <- function(lt_path) {
  
  id <- stringr::str_extract(lt_path, "[a-z]{3}(?=18ex)")

  lt_sheets <- readxl::excel_sheets(lt_path) |>
    stringr::str_subset(pattern = "period|cohort")
      
  # iterate over sheets
  purrr::map(lt_sheets, \(x) {
    readxl::read_xls(lt_path, x, skip = 9) |>
      dplyr::filter(!dplyr::row_number() == 1L) |>
      dplyr::rename_with(.cols = 1, ~"age") |>
      dplyr::mutate(base = "2018b") |>
      tidyr::pivot_longer(
        cols = `1981`:`2068`,
        names_to = "year",
        values_to = "ex"
      ) |>
      dplyr::mutate(
        sex = tolower(stringr::str_extract(x, "Female|Male")),
        type = stringr::str_extract(x, "period|cohort"),
        year = as.integer(year)
      )
  }) |>
    # combine sheets
    dplyr::bind_rows() |>
    dplyr::mutate(var = id)
}
