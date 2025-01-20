# README
# create area code directories

# fetch lists of area codes ----
df_lad23 <- targets::tar_read(df_raw_lad23)
df_cty23 <- targets::tar_read(df_raw_cty23)
df_icb23 <- targets::tar_read(df_icb23)

lad23 <- unique(df_lad23$lad23cd)
cty23 <- unique(df_cty23$cty23cd)
icb23 <- unique(df_icb23$icb23cd)
eng <- "E92000001"

dirs <- c(lad23, cty23, icb23, eng)

# only run once
purrr::map(dirs, \(x) dir.create(here::here("data", "2022", x)))
