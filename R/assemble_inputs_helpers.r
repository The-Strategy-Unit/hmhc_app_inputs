# README
# list and lookups to help with assembly of data files for the app

# areas used in app ----
# area_codes <- readr::read_csv(
#   here::here(
#     "data", "app_input_files",
#     "area_names_and_codes.csv"
#   )
# ) |>
#   dplyr::pull(cd)

# variants used in app ----
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

# hsagrps used in app ----
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

# hsa group levels ----
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

# hsa group labels ----
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

# lookup proj_id to variant_id
lookup_variant_id <- tibble::tribble(
  ~ "proj_id", ~ "variant_id",
  # historic population estimates, "v0"
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

# proj_id levels ----
proj_id_levels <- lookup_variant_id$proj_id

# variant_id levels ----
# historic population estimates take level v0
variant_id_levels <- c(paste0("v", 0:11))
