# hmhc_app_inputs
https://docs.ropensci.org/targets/reference/tar_repository_cas.html
https://stackoverflow.com/questions/15170399/change-r-default-library-path-using-libpaths-in-rprofile-site-fails-to-work
https://github.com/rstudio/renv/issues/1129
https://books.ropensci.org/targets/dynamic.html


### Population module
Tasks:
* Build a timeseries of population estimates for all areas (LADs, Countys, and ICBs),
for years 2000 to 2023, by single year of age, for ages 0-100+.
* Build a timeseries of population projections for all areas (LADs,
Countys, and ICBs), for years 2018 to 2043, by single year of age, for ages 0-100+. Create a set of custom sub-national variant projections that mirror the complete set of national variant projections.

Data sources:
* ONS mid-year population estimates (NOMIS)
* ONS estimates of the very old and centenarians
* ONS sub-national population projections 2018b
* ONS national population projections 2018b
* Geographic codelists and lookups (ONS Open Geography Portal)

Scripts:
read_area_lookups
read_icb_lookups
helper_lookups

read_npp_2018b
read_snpp_2018b
read_pop_very_old
read_pop_mye

build_mye
build_custom_vars
build_pop90
build_pop100
# We use the distribution for ages 90-100+ for England to approximate the
# distribution in local areas. The only place this is used is to determine the
# length of bars in the population pyramid. For modeling, the upper age group is
# 90+, any higher and the variation in activity rates becomes excessive.
# used as input to activity rates element in the app
# "app_pop_90_inputs"

# used as input to the model
# app_vars_all |>
#   pivot_wider(names_from = "year", values_from = "pop") |>
#   group_by(area_code, area_name) |>
#   group_walk(\(x, y) {
#     write_rds(x, here("data", "2022", y$area_code, "pop_dat.rds"))
#   })


## Activity data inputs
Fetch activity data for the three main acute hospital settings (ED, APC and OPC)
from SUS tables in NCDR. Aggregate data by sex, single year of age, local authority
and point of delivery—POD groups are referred to as 'hsagrps'. Data is for a single
calendar year, for patients aged 18+ resident in England. Upper age group is set to 90+.

areas and review plots ...

`/sql`  
`apc/edc/opc_read_fns.r`  
`apc/edc/opc_prep_fns.r`  


## Population data inputs
Mid-year population estimates, national population projections (NPP) and sub-national population projections (SNPP)
Also, life tables published alongside the NPP and estimates of the very old and centernarians 

`read_life_tables_2018b.r`
`read_npp_2018b.r`
`read_pop_mye.r`
`read_snpp_2018b.r`
`read_very_old.r`


## Other inputs
Administrative geographies change maintain list of local authority districts, ICBS, countys

`read_geog_codes.r`
`read_icb_lookup.r`

## Health Status adjustment inputs
`data/split_normal_parameters.csv`
derived from notebook

## 90+ in pyramid
## sub-national variants

## Modeling
* for each hsagrp/sex  in each area:
* baseline and horizon
* pick projection variant
* Model the relationship between age and activity by sex, by 'hsagrp' in each area.
Generalised additive models (GAMs) are created to smooth/generalise the relationship
in baseline year - act rates
* Health status adjusted ages derived from exercise for ages 55-90 so each combination
of age/sex has a chroniclaoal age and a HSA age uncertainty associated with estimate of
HSA which is generated from a distribution in horizon year - we run the model n times
sampling a different value from distribution each time
* gnerate new activity rate for hsa by using gams to predict or interpolating (immaterial for speed)
* compare new predicted rate with basline rates (assumed to be from gam remove random fluctation might be good year predict bettter)
ratio is taken as a multiplier
* calculate demo multiplier - chnage in projected population
* multipley hsa multiplier by demo multiplier then multiply activity in basleine to get estimate of activity in horizon year (x100 mdoel runs)
* calcy % change in activity this is shown in app

# uncetraity

# outputs
sending to app 2 sets of files for all areas JSON format in single zipped data file
`assemble_activity_inputs.r`
`assemble_pop_inputs.r`
`assemble_model_inputs.r`

# Folder structure
data/2022/...


`hsa_factors.r`
`hsa_helper_fns.r`
`hsa_make_gams.r`
`hsa_results.r`
`hsa_review_gams.r`




`make_mye_series.r`
`make_snpp_2018b_custom_vars.r`
`make_snpp_series_age100.r`
`make_snpp_series.r`


## renv dependencies

## targets pipeline