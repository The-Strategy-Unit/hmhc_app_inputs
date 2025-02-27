# Data files for the how much healthcare web application

Documentation and scripts for assembling the data input files used by the [How
much healthcare web application](https://github.com/The-Strategy-Unit/aging_pop_web_app).

The pipeline that assembles the input files is built and maintained using the
[`{targets}`](https://books.ropensci.org/targets/) package.

Package dependencies are managed using the [`{renv}`](https://rstudio.github.io/renv/index.html) package.

## Directory structure
`/data` secondary (processed) data  
`/data_raw` primary (unprocessed) data  
`/figures` plots  
`/R` custom functions   
`/renv` package dependencies   
`/sql` SQL scripts for querying healthcare activity datasets  
`_targets.r` configures and defines the analytical pipeline (target script)

## Data sources
Data is required for (a) past and expected future population, (b) current demand for different types of healthcare activity provided in hospitals, and (c) expectations about future changes in population health conditional on age (e.g., worsening or improving levels of illness at a given age, or changes in healthy life expectancy).

### Population data

* ONS mid-year population estimates (from [NOMIS](https://www.nomisweb.co.uk/))
* ONS estimates of the very old and centenarians
* ONS national population projections 2018-based
* ONS sub-national population projections 2018-based

### Healthcare activity

* SUS+ emergency care, inpatient, & outpatient datasets, 2023

### Expectations about future changes in population health

* the parameters of a statistical distribution encoding assumptions about expected future changes in healthy life expectancy (the primary output of an expert elicitation exercise held in October 2022)

### Other data

* geographic codelists and lookups (from [ONS Open Geography Portal](https://geoportal.statistics.gov.uk/))

## Population and healthcare activity
Publicly available ONS population data is used to assemble the following datasets:

* timeseries of population estimates for all local authority districts (LADs) for years 2000 to 2023, by sex, by single year of age for ages 0–100+
* timeseries of population projections for all LADs for years 2018 to 2043, by sex, by single year of age for ages 0-100+. Including a set of custom sub-national variant projections that mirror the full set of national variant projections
* timeseries as above, but for ages 0-90+

The emergency care, inpatient, & outpatient datasets in the SUS+ data warehouse are queried to return the following datasets:

* hospital activity data aggregated by sex, by single year of age for ages 18–90+, by local authority district (patient residence), and by point of delivery, for patients resident in England, for the calendar year 2022

This data is held in a secure de-identified environment administered by NHS England and is only accessible to NHS staff with the correct permissions.

### Approach

ONS population data, for all local areas in 2000, has an upper age group of 85+. We use the national (England) distribution for females/males age 85–90+ to apportion the 85+ population in local areas to single years of age 85–90+. Data on the very old (age 90+) is only available for England, and only from 2002 onward. We assume the age distribution of females/males age 90–100+ in 2000 and 2001 is the same as the national distribution in 2002. For 2002 onward, we assume the distribution of females/males age 90-100+ in local areas matches the national distribution.

ONS sub-national population projections data has an upper age group of 90+, whereas the national population projections are single year of age to 105+. We use the national distribution for females/males age 90–100+ to apportion the 90+ population in local areas to single years of age 90–100+.The ONS publish 17 variant projections (based on alternative assumptions of future fertility, mortality and migration,) alongside the principal national projection. The principal sub-national projection is accompanied by a much smaller set of 5 variant projections. For two cases, however, a sub-national variant does not have a mirrored national variant. There is no offical mapping of national variants to sub-national variants, so we must first select a national variant before applying its distribution of persons age 90+, in both cases it makes sense to use the principal projection.

* principal national projection mapped to sub-national *alternative internal migration* variant
* principal national projection mapped to sub-national *10-year migration trend* variant

To produce a set of custom sub-national variant projections that mirror the full set of national variant
projections we apply the percentage difference between national variants and the principal national by age and sex to the principal sub-national projection.

Information on the distribution of persons age 90–100+ is used to determine the length of the bars in the interactive population pyramid.

For all modeling, the upper age group is limited to 90+, to mitigate against excessive variation in activity rates caused by small numbers.

## Expectations about future changes in population health

## Modeling
All modeling is cell-based. Data is first aggregated to counts by sex and single year of age. Estimates of healthcare activity for future years are produced by applying multipliers to activity counts (in cells) from the baseline year.

$$ act_{y+n} = act_{y} \times Mx_{demo} \times Mx_{hsa} $$

Activity in some future year, $y+n$ is the product of activity in the base year $y$ and two multipliers: a demographic multiplier, $Mx_{demo}$, and a health status adjustment multiplier, $Mx_{hsa}$. 

Where:

$$ Mx_{demo} = population_{y+n} / population_{y}$$

And:

$$ Mx_{hsa} = \frac{rate_{y}^{adj,f}} {rate_{y}^{i,f}} $$


The denominator is the observed activity rate in the base year for chronological age = $i$ and sex = $f$. The numerator is a derived rate based on age adjusted for expected changes in population health status. For example, if we expect population health status to worsen then the adjusted age for a person whose chronological age is 75 might be 76. To obtain the adjusted rate, we first fit a model to the age-utilisation curve in the base year. This model can then be used to predict the activity rate for any age (including fractional ages).

The adjustment for future changes in population health status (hsa multiplier) is only applied to persons of age 55 years and over. For persons below this age only the demographic multiplier is used.

### Handling uncertainty
We explicitly model the uncertainty associated with assumptions about expected future changes in population health conditional on age using [Monte Carlo](https://en.wikipedia.org/wiki/Monte_Carlo_method) methods. We sample repeatedly from a statistical distribution encoding assumptions about expected future changes in healthy life expectancy. This allows us to draw many different sets of adjusted ages (weighted ...) and run our models many times eachh with a slightly different set of inputs.

## Geography

## Assembling the input files
The web application has three interactive data visualisations, each requires a set of 360 files. All files are supplied in the [JSON](https://en.wikipedia.org/wiki/JSON) format.

* England (N = 1)
* local authority districts (296)
* upper-tier local authorities (21)
* integrated care boards (42)
* **total above = 360**

### Population pyramid dataset
**area_code**, type: **string**, 9-char geographic identifier (ONS geocode)   
**variant**, type: **string**, 2-char identifier population projection variant   
**year**, type: **integer**, calendar year   
**totals**, type: **JSON object**, population totals by sex  
**data**, type: **JSON array of objects**, population by age/sex

### Age profiles line charts dataset  
**area_code**, type: **string**, 9-char geographic identifier (ONS geocode)  
**pod**, type: **string**, 3-char setting identifier  
**group**, type: **string**, point of delivery sub-group  
**label**, type: **string**, point of delivery sub-group label  
**data**, type: **JSON array of objects**, raw and smoothed activity rates by age/sex

### Model results 1D histograms dataset 
**area_code**, type: **string**, 9-char geographic identifier (ONS geocode)  
**end_year**: type: **integer**, model horizon  
**variant**, type: **string**, 2-char identifier population projection variant   
**pod**, type: **string**, 3-char setting identifier  
**group**, type: **string**, point of delivery sub-group  
**label**, type: **string**, point of delivery sub-group label  
**end_p_md**, type: **double**, modeled percent change in activity (mode, health status adjustment model)  
**end_p_nohsa**, type: **double**, modeled percent change in activity (pure demographic model)  
**data**, type: **JSON array of objects**, bin intervals and frequency counts for modeled percent change in activity from health status adjustment model simulations
