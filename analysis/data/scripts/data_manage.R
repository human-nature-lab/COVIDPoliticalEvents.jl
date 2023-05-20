# authors: Eric Feltham and Ben Snyder
# date: 03/03/2021

data_manage <- function(load_existing_covid = TRUE, 
                        load_existing_mb = TRUE, 
                        user = "", 
                        private_key = "", 
                        census_key = "",
                        weekly_data = TRUE, 
                        county_data = TRUE) {
  # construct three data frames: state, county, time
  # census_key is the output of the key input into tidycensus
  Pkg <- c(
    "tibble",
    "dplyr",
    "magrittr",
    "lubridate"
    )
  for (pkg in Pkg) require(pkg, character.only = TRUE)
  
  # state level data
  ## election date, lockdown, state of emergency, etc.

  sch <- readr::read_csv("data/primary_sched_update.csv")
  sch$fips <- usmap::fips(sch$state)
  sch %<>% filter(is.na(fips) == FALSE) %>% select(-state)
  
  stay <- readr::read_csv("data/stay-at-home-end.csv")
  stay$fips <- usmap::fips(stay$state)
  stay %<>% filter(is.na(fips) == FALSE) %>% select(-state, -abbr)

  stay_begin <- readr::read_csv("data/stay-at-home.csv")
  stay_begin$fips <- usmap::fips(stay_begin$State)
  stay_begin %<>% filter(is.na(fips) == FALSE) %>% select(-State)

  ste_df <- sch %>% 
    left_join(stay, by = "fips") %>%
    left_join(stay_begin, by = "fips")

  # county level dataload_existing_covid = TRUE
  ## all time-invariant county characteristics, county-level election data

  # if key provided, add key and overwrite old key
  # if no key provided and no key saved in system, prompt user for key
  if (census_key != "") {
    tidycensus::census_api_key(census_key, overwrite = TRUE, install = TRUE)
  } else if (Sys.getenv("CENSUS_API_KEY") == "") {
    census_key <- readline(prompt = "No API key detected. Enter Census API key: ")
    tidycensus::census_api_key(census_key, overwrite = TRUE, install = TRUE)
    readRenviron("~/.Renviron")
  }
  
  # load county census data from ACS and 2019 land survey
  source("scripts/load_county_char.R")
  X <- loadCountyChar() %>% 
    tibble()

  # BLS unemployment data [note unemployment also from ACS]
   bls <- readr::read_csv("data/bls_unemployment.csv") %>% 
    mutate(
      fips = as.character(stateFIPS*1000 + countyFIPS), 
      Urate = Urate / 100) %>% 
    select(fips, Urate)
   
   bls$fips[nchar(bls$fips) == 4] <- paste0("0", bls$fips[nchar(bls$fips) == 4])

  # NYT county-level mask survey data
  mask_nyt <- readr::read_csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/mask-use/mask-use-by-county.csv")
  colnames(mask_nyt) <- c(
    "fips",
    "mask_nev", "mask_rare",
    "mask_sotim", "mask_freq", "mask_alw")

  # census delinations (e.g. MSA area)
  cen_delin <- readr::read_csv("data/census_delineation.csv") %>%
    mutate(fips = paste0(fips_state, fips_county)) %>%
    select(-county, -state, -fips_state, -fips_county)

  # add turnout and polling data
  raw_to <- readr::read_csv('data/2020_presidential_primary_turnout.csv')

  raw_to %<>%
    select(fips, poll_places, voter_per_poll, tot_reg, date) %>%
    mutate(primary = date, date = NULL)

  # merge all county-level data
  cty_df <- X %>%
    left_join(bls, by = "fips") %>%
    left_join(mask_nyt, by = "fips") %>%
    left_join(cen_delin, by = "fips") %>%
    mutate(fips_n = as.integer(fips)) %>%
    left_join(raw_to, by = c("fips_n" = "fips")) %>%
    mutate(fips_n = NULL)

  # create turnout variables
  cty_df %<>%
    mutate(
      tot_reg = case_when(tot_reg < 0 ~ 0, TRUE ~ tot_reg),
      trn_rte = tot_reg / pop
      )

  # measurement level
  ## covid, social distancing data
  
  ## use NYT data for now
  source("scripts/get_NYT.R")
  if (load_existing_covid == TRUE) {
    if (weekly_data) {
      load("data/covid_data_weekly.Rdat")
    } else {
      load("data/covid_data_daily.Rdat")
    }
  } else {
    nyt <- get_NYT(county = county_data, weekly = weekly_data) %>% mutate(date = as.Date(date))
  }

  ## mobility data
  # start date: 2020-01-21
  # end date 2020-09-11

  if (load_existing_mb == FALSE) { ## This feature not implemented.

    cat(
      "Update mobility feature not yet available. Please update manually on Hector."
    )


  } else {
    MB <- readRDS("data/safegraph_all_us_pandemic.rds")
  }

  mb <- tibble(MB) %>%
    dplyr::rename(
       distance_traveled_from_home = mean_median_distance_travelled_from_home,
       median_home_dwell_time = mean_median_home_dwell_time,
       median_percentage_time_home = mean_median_percent_time_home,
       median_non_home_dwell_time = mean_non_home_dwell_time) %>%
    dplyr::mutate(
       fips = id,
       date = as.Date(date),
       week = as.integer(week(date))) %>%
    dplyr::select(-candidate_device_count, -id)
  
  # only missing data from mb is from US territories in week column 15151 entries and 2 entries from mean_median_distance
  # colSums(is.na(mb))
  # unique(mb$fips[is.na(mb$week)])
  # mb$fips[is.na(mb$distance_traveled_from_home)]
  
  if (weekly_data == TRUE) {
    # aggregate mobility by sum and mean at the week level
    mb_sum <- mb %>%
      dplyr::group_by(week, fips) %>%
      summarise_at(dplyr::vars(
        device_count, completely_home_device_count), sum)
    mb_mean <- mb %>%
      dplyr::group_by(week, fips) %>%
      summarise_at(dplyr::vars(
        median_home_dwell_time,
        median_non_home_dwell_time,
        distance_traveled_from_home, 
        edian_percentage_time_home,
        proportion_completely_home
        ),
        mean, na.rm = TRUE)
    
    # join sum and mean aggregates to have final mb with data by week for merging with NYT data
    mb <- mb_sum %>% dplyr::left_join(
      mb_mean, by = c("fips", "week"))

    time_df <- nyt %>%
    dplyr::full_join(mb, by = c("fips", "week"))
  } else {
    nyt <- nyt %>% mutate(date = as.Date(date)) %>%
    select(-week)
    time_df <- mb %>% dplyr::full_join(nyt, by = c("fips", "date"))
  }

  # formatting
  fips_key <- tidycensus::fips_codes %>%
  mutate(fips = as.integer(state_code) * 1000 + as.integer(county_code)) %>%
  select(state_name, fips, county) %>%
  tibble() %>%
  mutate(state = state_name) %>%
  select(-state_name)


  time_df %<>% mutate(fips = as.integer(fips)) %>% 
    tibble() %>% 
    select(-log_cases, -log_deaths, -log_deathsCum, -log_casesCum)
  cty_df %<>% mutate(fips = as.integer(fips)) %>%
    mutate(abbr = state) %>%
    select(-state) %>%
    left_join(select(fips_key, state, fips), by = "fips")
  ste_df %<>% 
    mutate(fips = as.integer(fips), primary_dte = date) %>%
    select(-date) %>%
    left_join(select(fips_key, state, fips), by = "fips")
  
  # standardize time_df state and county based on tidy_census
  time_df %<>% select(-state, -county) %>% left_join(fips_key, by = "fips")

  # newer variables
  ru <- readr::read_csv("data/ruralurbancodes2013.csv") %>%
  mutate(fips = as.integer(FIPS), ruc = as.character(RUCC_2013), rucDesc = Description) %>%
  select(fips, ruc, rucDesc)

  cty_df %<>% left_join(ru, by = "fips")

  # weather data
  weather <- readRDS("data/weather.rds")
  weather$fips <- as.integer(weather$county)
  weather$county <- NULL
  time_df %<>% left_join(weather, by = c("fips", "date"))
  
  # state interventions running variables
  interventions <- read.csv("data/oxford_interventions.csv")
  interventions$date <- as.Date(interventions$date)
  interventions$state_fips <- interventions$fips
  interventions %<>% select(-fips, -state, -X)
  time_df$state_fips <- as.integer(time_df$fips/1000)
  time_df %<>% left_join(interventions, by = c("state_fips", "date"))
  
  # standardize cty_df state and county based on tidy_census
  cty_df %<>% select(-state, -area_name) %>% left_join(fips_key, by = "fips")

  fips_state <- tibble(tidycensus::fips_codes) %>% 
    mutate(state_code = as.integer(state_code), state = state_name) %>% 
    select(-state_name, -county, -county_code) %>%
    unique()
  ste_df %<>% select(-state) %>% left_join(fips_state, by = c("fips" = "state_code"))

  dat <- list(
    ste_df = ste_df,
    cty_df = cty_df,
    time_df = time_df)

  save(
    dat,
    file = "data/covid_voting_data_daily_county.RData")

  return(list(
    ste_df = ste_df,
    cty_df = cty_df,
    time_df = time_df
  ))
}

covariate_mobility <- function() {
  Pkg <- c(
    "data.table",
    "dplyr",
    "magrittr",
    "ggplot2"
  )
  for (pkg in Pkg) library(pkg, character.only = TRUE)
  
  foot_traffic <- readRDS("data/patterns_2020-01-01_2021-02-28.rds")
  ft <- foot_traffic %>%
    filter(naics_code %in% c(722511, 813110, 722410, 445110, 445120, 445210, 445220, 445230, 445291, 445292, 445299)) %>%
    mutate(fips = as.integer(fips))
  
  rm(foot_traffic)
  
  fips <- unique(ft$fips)
  cov <- data.table(fips)
  
  if (file.exists("data/election_data.rds")) {
    prev <- readRDS("data/election_data.rds")
  } else {
    prev <- read.csv("https://dataverse.harvard.edu/api/access/datafile/:persistentId?persistentId=doi:10.7910/DVN/VOQCHQ/HEIJCQ", sep = "\t")
    prev %<>% filter(year == 2016)
    saveRDS(prev, "data/election_data.rds")
  }
  
  cov$trump_share <- NA
  for (i in 1:nrow(cov)) {
    ind <- which(prev$FIPS == cov$fips[i])
    if (length(ind) == 3) {
      cov$trump_share[i] <- prev$candidatevotes[ind[2]]/prev$totalvotes[ind[2]]
    }
  }
  
  ckey <- tidycensus::census_api_key("cce71ee05f76abac6fd8d781512c42160b0bf4f9")
  
  # to read and find variables, view v18
  # v18 <- load_variables(2018, "acs5", cache = TRUE)
  # DT::datatable(v18)
  # acs data dictionary: https://www.socialexplorer.com/data/ACS2016_5yr
  
  acs_raw <- tidycensus::get_acs(
    geography = "county",
    year = 2018,
    variables = c(
      #pop
      pop = "B01003_001",
      #econ
      median_inc = "B06011_001",
      #sex & age
      male_tot = "B01001_002",
      m65_66 = "B01001_020",
      m67_69 = "B01001_021",
      m70_74 = "B01001_022",
      m75_79 = "B01001_023",
      m80_84 = "B01001_024",
      m85_up = "B01001_025",
      female_tot = "B01001_026",
      f65_66 = "B01001_044",
      f67_69 = "B01001_045",
      f70_74 = "B01001_046",
      f75_79 = "B01001_047",
      f80_84 = "B01001_048",
      f85_up = "B01001_049"),
    survey = "acs5",
    cache_table = TRUE)
  
  # clean away margin of error and turn each variable into a column
  dem <- acs_raw %>% dplyr::select(-moe) %>% tidyr::pivot_wider(names_from = variable, values_from = estimate)
  
  dem <- dem %>%
    mutate(
      fips = as.integer(GEOID),
      perc_65_up = (m65_66 + m67_69 + m70_74 + m75_79 + m80_84 + m85_up + f65_66 + f67_69 + f70_74 + f75_79 + f80_84 + f85_up)/(male_tot + female_tot)
      ) %>%
    select(fips, pop, median_inc, perc_65_up)
  
  cov <- merge(cov, dem, all.x = TRUE) %>% filter(!is.na(fips))
  
  cov <- left_join(ft, cov, by = "fips")
  cov <- cov %>% mutate(visits = visits/pop) %>% select(-pop)
  
  rm(ft)
  
  saveRDS(cov, "covar_footTraffic.rds")
  
  sch <- readr::read_csv("data/primary_sched_update.csv")
  sch$fips <- usmap::fips(sch$state)
  sch %<>% filter(is.na(fips) == FALSE) %>% select(-state)
  
  cov$state_fips <- as.integer(cov$fips/1000)
  sch <- sch %>% mutate(
    state_fips = as.integer(fips),
    primary_date = date) %>%
    select(-fips, -date)
  cov <- left_join(cov, sch, by = "state_fips")
  
  # save covariate data.table before filtering
  cov$days_post_primary <- as.Date(cov$date) - cov$primary_date
  cov %<>% filter(days_post_primary >= -42, days_post_primary <= 42)
  
  grocery <- cov %>% filter(as.integer(naics_code/1000) == 445) %>%
    mutate(naics_code = 445)
  grocery <- grocery[, .(visits=sum(visits)), by = .(date, fips, naics_code, trump_share, median_inc, perc_65_up, state_fips, primary_date, days_post_primary)]
  
  cov %<>% filter(as.integer(naics_code/1000) != 445)
  cov <- rbind(cov, grocery)
  
  rm(grocery)
  
  saveRDS(cov, "covar_primary_footTraffic.rds")
  
  sum(is.na(cov$visits))
  sum(is.na(cov$trump_share))
  sum(is.na(cov$median_inc))
  sum(is.na(cov$perc_65_up))
  
  # save copy of cov in order to mess around with primary date filters
  cv <- cov
  #cov <- cv
  pds <- unique(cv$primary_date)
  cov %<>% filter(primary_date >= as.Date("2020-03-21"))
  
  cov %<>% mutate(trump_q = ntile(cov$trump_share, 4),
                  perc_65_q = ntile(cov$perc_65_up, 4),
                  inc_q = ntile(cov$median_inc, 4),
                  days_post_primary = as.integer(days_post_primary),
                  Business = NA)
  cov$Business[cov$naics_code == 445] <- "grocery stores"
  cov$Business[cov$naics_code == 813110] <- "religious orgs"
  cov$Business[cov$naics_code == 722410] <- "bars"
  cov$Business[cov$naics_code == 722511] <- "full-service restaurants"
  
  trump <- cov[, .(visits=mean(visits)), by = .(days_post_primary, Business, trump_q)]
  
  trump <- trump %>% filter(!is.na(trump_q)) %>%
    mutate(Trump_Vote_Quartile = as.factor(trump_q),
           Business = as.factor(Business))

  trump_plot <- trump %>% ggplot(aes(x=days_post_primary,
                                     y=visits,
                                     color = Trump_Vote_Quartile,
                                     shape = Business,
                                     group=interaction(Trump_Vote_Quartile, Business))) + 
    geom_point() + 
    geom_line() +
    labs(y = "Avg Visits/population", x = "Days after primary", title = "Avg Business Visits Around Primary Stratified by Trump Vote")
    
  trump_plot
  
  income <- cov[, .(visits=mean(visits)), by = .(days_post_primary, Business, inc_q)]
  
  income <- income %>% filter(!is.na(inc_q)) %>%
    mutate(Median_Income_Quartile = as.factor(inc_q),
           Business = as.factor(Business))
  
  income_plot <- income %>% ggplot(aes(x=days_post_primary,
                                     y=visits,
                                     color = Median_Income_Quartile,
                                     shape = Business,
                                     group=interaction(Median_Income_Quartile, Business))) + 
    geom_point() + 
    geom_line() +
    labs(y = "Avg Visits/population", x = "Days after primary", title = "Avg Business Visits Around Primary Stratified by Median Income")
  
  income_plot
  
  age <- cov[, .(visits=mean(visits)), by = .(days_post_primary, Business, perc_65_q)]
  
  age <- age %>% filter(!is.na(perc_65_q)) %>%
    mutate(Over_65_Quartile = as.factor(perc_65_q),
           Business = as.factor(Business))
  
  age_plot <- age %>% ggplot(aes(x=days_post_primary,
                                       y=visits,
                                       color = Over_65_Quartile,
                                       shape = Business,
                                       group=interaction(Over_65_Quartile, Business))) + 
    geom_point() + 
    geom_line() +
    labs(y = "Avg Visits/population", x = "Days after primary", title = "Avg Business Visits Around Primary Stratified by Percent Over 65")
  
  age_plot
  }
