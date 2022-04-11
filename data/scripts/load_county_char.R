# authors: Ben Snyder
# date: 03/03/2021
#
# creates data frame of county-level characterustucs from a collection of spreasheets and online US census data as 
# well as tidycensus R package. Requires API key input.
# detail  false default removes detailed age and sex breakdowns
# rates   true adds denominators for all categories and converts all counts to rates when combined with detail = FALSE
# api_key string with US Census API key, overwrites current key if supplied. By default
loadCountyChar <- function(detail = FALSE, rates = TRUE, api_key = "") {
  # load necessary packages
  pkgs <- c(
    "dplyr",
    "magrittr",
    "tidycensus"
  )
  
  for (pkg in pkgs) library(pkg, character.only = TRUE)
  
  # overwrites census API key if argument provided, prompts key if none is cached
  if (api_key != "") {
    tidycensus::census_api_key(api_key, overwrite = TRUE, install = TRUE)
  } else if (Sys.getenv("CENSUS_API_KEY") == "") {
    api_key <- readline(prompt = "No API key detected. Enter Census API key: ")
    tidycensus::census_api_key(api_key, overwrite = TRUE, install = TRUE)
    readRenviron("~/.Renviron")
  }
  
  # to read and find variables, view v18
  # v18 <- load_variables(2018, "acs5", cache = TRUE)
  # DT::datatable(v18)
  # acs data dictionary: https://www.socialexplorer.com/data/ACS2016_5yr
  
  acs_raw <- tidycensus::get_acs(
    geography = "county",
    year = 2018,
    variables = c(
      #population
      pop = "B01003_001",
      sample_pop = "B00001_001",
      #education
      no_high_school = "B06009_002",
      high_school_only = "B06009_003",
      some_college = "B06009_004",
      bacc = "B06009_005",
      post_bacc = "B06009_006",
      educ_denom = "B06009_001",
      #econ
      median_inc = "B06011_001",
      pov_last_year = "B17005_002",
      pov_denom = "B17005_001",
      unemployment = "B23025_005",
      unemployment_denom = "B23025_003",
      #sex & age
      male_tot = "B01001_002",
      m0_4 = "B01001_003",
      m5_9 = "B01001_004",
      m10_14 = "B01001_005",
      m15_17 = "B01001_006",
      m18_19 = "B01001_007",
      m20 = "B01001_008",
      m21 = "B01001_009",
      m22_24 = "B01001_010",
      m25_29 = "B01001_011",
      m30_34 = "B01001_012",
      m35_39 = "B01001_013",
      m40_44 = "B01001_014",
      m45_49 = "B01001_015",
      m50_54 = "B01001_016",
      m55_59 = "B01001_017",
      m60_61 = "B01001_018",
      m62_64 = "B01001_019",
      m65_66 = "B01001_020",
      m67_69 = "B01001_021",
      m70_74 = "B01001_022",
      m75_79 = "B01001_023",
      m80_84 = "B01001_024",
      m85_up = "B01001_025",
      female_tot = "B01001_026",
      f0_4 = "B01001_027",
      f5_9 = "B01001_028",
      f10_14 = "B01001_029",
      f15_17 = "B01001_030",
      f18_19 = "B01001_031",
      f20 = "B01001_032",
      f21 = "B01001_033",
      f22_24 = "B01001_034",
      f25_29 = "B01001_035",
      f30_34 = "B01001_036",
      f35_39 = "B01001_037",
      f40_44 = "B01001_038",
      f45_49 = "B01001_039",
      f50_54 = "B01001_040",
      f55_59 = "B01001_041",
      f60_61 = "B01001_042",
      f62_64 = "B01001_043",
      f65_66 = "B01001_044",
      f67_69 = "B01001_045",
      f70_74 = "B01001_046",
      f75_79 = "B01001_047",
      f80_84 = "B01001_048",
      f85_up = "B01001_049",
      #race
      white_m = "B01001A_002",
      white_f = "B01001A_017",
      black_m = "B01001B_002",
      black_f = "B01001B_017",
      native_m = "B01001C_002",
      native_f = "B01001C_017",
      asian_m = "B01001D_002",
      asian_f = "B01001D_017",
      pacific_m = "B01001E_002",
      pacific_f = "B01001E_017",
      other_m = "B01001F_002",
      other_f = "B01001F_017",
      multi_m = "B01001G_002",
      multi_f = "B01001G_017",
      #ethinicity
      hisp_m = "B01001I_002",
      hisp_f = "B01001I_017",
      non_hisp_tot = "B03002_002"),
    survey = "acs5",
    cache_table = TRUE)
  
  # clean away margin of error and turn each variable into a column
  dem <- acs_raw %>% dplyr::select(-moe) %>% tidyr::pivot_wider(names_from = variable, values_from = estimate)
  
  # download and unzip file with county area data from US Census Bureau 2019 if not already done
  # documentation: https://www.census.gov/programs-surveys/geography/technical-documentation/records-layout/gaz-record-layouts.html
  dest_file <- "data/2019_census_county_areas.zip"
  unzipped_file <- "data/2019_Gaz_counties_national.txt"
  if (!file.exists(unzipped_file)) {
    if (!file.exists(dest_file)) {
      url <- "https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2019_Gazetteer/2019_Gaz_counties_national.zip"
      download.file(url, dest_file, method = "auto")
    }
    
    unzip(dest_file)
  }
  
  # read data into R with tab delimited specification
  geo <- read.csv(unzipped_file, sep = "\t", colClasses = c("GEOID"="character"))
  
  # select desired data and GEOID as key in preparation to merge with dem 
  geo %<>% dplyr::select(GEOID, ALAND_SQMI, USPS)
  
  # merge dem and geo to add land area column
  dem <- merge(dem, geo, by.x = "GEOID", by.y = "GEOID", all = TRUE)
  
  # rename columns for backwards compatibility and consistency
  dem %<>% dplyr::rename(
    land_area = ALAND_SQMI,
    fips = GEOID,
    area_name = NAME,
    state = USPS
  )
  
  # add population density from existing columns
  dem %<>% dplyr::mutate(
    pop_density = pop/land_area
  )

  # if rates are desired, add necessary denominators and calculate education rates
  if (rates) {
    dem %<>% dplyr::mutate(
      poverty_rate = pov_last_year/pov_denom,
      unemployment = unemployment/unemployment_denom,
      no_high_school = no_high_school/educ_denom,
      high_school_only = high_school_only/educ_denom,
      some_college = some_college/educ_denom,
      bacc = bacc/educ_denom,
      post_bacc = post_bacc/educ_denom,
      race_denom = (white_m + white_f + black_m + black_f + native_m + native_f + asian_m + asian_f
                    + pacific_m + pacific_f + other_m + other_f + multi_m + multi_f),
      ethn_denom = (hisp_m + hisp_f + non_hisp_tot),
      female_tot = female_tot/(female_tot+male_tot)
    )
  }
  
  # simplify columns by combining them if less detail is desired (like the previous version)
  if (!detail) {
    dem %<>% dplyr::mutate(
      num_0_17 = (m0_4 + m5_9 + m10_14 + m15_17 + f0_4 + f5_9 + f10_14 + f15_17),
      num_18_64 = (m18_19 + m20 + m21 + m22_24 + m25_29 + m30_34 + m35_39 + m40_44 + m45_49 + m50_54 + m55_59 + m60_61 + m62_64 + 
                     f18_19 + f20 + f21 + f22_24 + f25_29 + f30_34 + f35_39 + f40_44 + f45_49 + f50_54 + f55_59 + f60_61 + f62_64),
      num_65_up = (m65_66 + m67_69 + m70_74 + m75_79 + m80_84 + m85_up + f65_66 + f67_69 + f70_74 + f75_79 + f80_84 + f85_up),
      white = (white_m + white_f),
      black = (black_m + black_f),
      native = (native_m + native_f),
      asian = (asian_m + asian_f),
      pacific = (pacific_m + pacific_f),
      other = (other_m + other_f),
      multi = (multi_m + multi_f),
      hispanic = (hisp_m + hisp_f)
    )
    
    # turn all simplified columns into rates to adjust for population if rates TRUE
    if (rates) {
      dem %<>% dplyr::mutate(
        perc_0_17 = num_0_17/(num_0_17+num_18_64+num_65_up),
        perc_18_64 = num_18_64/(num_0_17+num_18_64+num_65_up),
        perc_65_up = num_65_up/(num_0_17+num_18_64+num_65_up),
        white = white/race_denom,
        black = black/race_denom,
        native = native/race_denom,
        asian = asian/race_denom,
        pacific = pacific/race_denom,
        other = other/race_denom,
        multi = multi/race_denom,
        hispanic = hispanic/race_denom
      )
      
      # select only simplified columns
      dem %<>% select(fips, area_name, state, pop, sample_pop, land_area, pop_density, no_high_school, high_school_only, some_college,
                      bacc, post_bacc, poverty_rate, unemployment, median_inc, female_tot, perc_0_17, perc_18_64, perc_65_up, white, black,
                      native, asian, pacific, other, multi, hispanic)
    } else {
      # select only simplified columns without rates
      dem %<>% select(fips, area_name, state, pop, sample_pop, land_area, pop_density, no_high_school, high_school_only, some_college,
                      bacc, post_bacc, pov_last_year, pov_denom, unemployment, unemployment_denom, median_inc, female_tot, male_tot, num_0_17, 
                      num_18_64, num_65_up, white, black, native, asian, pacific, other, multi, hispanic)
    }
  }
  
  # Election turnout data & dates
  # turnout <- read.csv("data/2020_presidential_primary_turnout.csv")
  # turnout %<>% filter(!is.na(county))
  # dem$poll_places <- NA
  # dem$in_person_voters <- NA
  # dem$tot_voters <- NA
  # dem$primary <- NA
  # for (i in 1:length(turnout$fips)) {
  #   ind <- which(as.numeric(dem$fips) == turnout$fips[i])
  #   if (length(ind) == 1) {
  #     dem$poll_places[ind] <- turnout$poll_places[i]
  #     dem$in_person_voters[ind] <- turnout$tot_reg[i]
  #     dem$tot_voters[ind] <- turnout$tot[i]
  #     dem$primary[ind] <- turnout$date[i]
  #   }
  # }
  # dem$primary <- as.Date(dem$primary)
  
  # handle turnout data
  # not entirely sure how it is handled above
  # tot_reg = # in person votes


  # previous election data
  prev <- read.csv("https://dataverse.harvard.edu/api/access/datafile/:persistentId?persistentId=doi:10.7910/DVN/VOQCHQ/HEIJCQ", sep = "\t")
  prev %<>% filter(year == 2016)
  dem$trump_share_2016 <- NA
  for (i in 1:length(dem$fips)) {
    ind <- which(prev$FIPS == as.numeric(dem$fips[i]))
    if (length(ind) == 3) {
      dem$trump_share_2016[i] <- prev$candidatevotes[ind[2]]/prev$totalvotes[ind[2]]
    }
  }
  
  return(dem)
}

# loads and cleans state-level public health measures interventions data from Oxford Covid-19 Government Response Tracking Project
# then returns saves the result as a csv file called "oxford_interventions.csv"
# update_data overwrites current raw data file with latest from GitHub
load_interventions <- function(update_data = FALSE) {
  
  # update to latest data if desired
  if (update_data) {
    download.file("https://raw.githubusercontent.com/OxCGRT/covid-policy-tracker/master/data/OxCGRT_latest.csv", destfile = "data/oxford_interventions_raw.csv")
    
    # alternate data source (with more difficult but information rich format) listed below
    # download.file("https://raw.githubusercontent.com/COVID19StatePolicy/SocialDistancing/master/data/USstatesCov19distancingpolicy.csv", destfile = "data/uwash_interventions.csv")
  }
  
  require(magrittr)
  require(dplyr)
  require(usmap)
  
  # see documentation at https://github.com/OxCGRT/covid-policy-tracker/blob/master/documentation/codebook.md
  oxf_raw <- read.csv("data/oxford_interventions_raw.csv")
  
  # filter to US states
  oxf <- oxf_raw %>% filter(CountryCode == "USA", RegionCode != "")
  
  # add FIPS codes, reformat dates, add renamed columns for variables of interest
  oxf <- oxf %>% mutate(
    date = as.Date(as.character(Date), format="%Y%m%d"),
    state = RegionName,
    fips = fips(RegionName),
    school_closed = C1_School.closing,
    work_closed = C2_Workplace.closing,
    gatherings_restricted = C4_Restrictions.on.gatherings,
    stay_home = C6_Stay.at.home.requirements,
    test_policy = H2_Testing.policy
  ) %>% filter(!is.na(fips))
  
  # find where NA's begin in public health data then remove data from that date and beyond
  end <- min(oxf$date[is.na(oxf$school_closed)])
  if (!is.na(end)) {
    oxf %<>% filter(date < end)
  }
  
  # check that no NA values remain for key variables
  if (sum(is.na(oxf[1:nrow(oxf),(ncol(oxf)-6):ncol(oxf)])) != 0) {
    cat("NA values remain after cleaning. Manual adjustments required.")
  }
  
  # restrict to key columns
  oxf %<>% select(date, state, fips, school_closed, work_closed, gatherings_restricted, stay_home, test_policy)

  # reduce intervention stringency to a trinary
  # Trinary: 0 => no restrictions; 1 => recommended restrictions; 2 => at least some required restrictions
  oxf$school_closed[oxf$school_closed > 2] <- 2
  oxf$work_closed[oxf$work_closed > 2] <- 2
  oxf$stay_home[oxf$stay_home > 2] <- 2
  
  # split gathering restrictions and testing policy into individual dummies
  oxf$gatherings_limited_above1000 <- as.numeric(oxf$gatherings_restricted >= 1)
  oxf$gatherings_limited_1000below <- as.numeric(oxf$gatherings_restricted >= 2)
  oxf$gatherings_limited_100below <- as.numeric(oxf$gatherings_restricted >= 3)
  oxf$gatherings_limited_10below <- as.numeric(oxf$gatherings_restricted == 4)
  
  oxf$limited_symptomatic_testing <- as.numeric(oxf$test_policy >= 1)
  oxf$symptomatic_testing <- as.numeric(oxf$test_policy >= 2)
  oxf$open_testing <- as.numeric(oxf$test_policy == 3)
  
  # remove now-reduntant columns
  oxf %<>% select(-gatherings_restricted, -test_policy)

  # save result to csv
  write.csv(oxf, "data/oxford_interventions.csv")
}
