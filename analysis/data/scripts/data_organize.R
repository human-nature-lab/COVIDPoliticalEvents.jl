# setup for imai analysis (and plotting)

# use PanelMatch
# redo with ALL data
# include data from whole time period,
# mark primary range for each state
library("lubridate")
library("tibble")
library("ggplot2")
library("dplyr")
library("magrittr")

# change to covid-19-data
setwd("..")

source("scripts/data_manage.R")
source("../covid-19-voting/changes-in-changes/imai_functions.R")

ckey <- tidycensus::census_api_key("cce71ee05f76abac6fd8d781512c42160b0bf4f9")

fips_key <- tidycensus::fips_codes %>%
  mutate(fips = as.integer(state_code) * 1000 + as.integer(county_code)) %>%
  select(state_name, fips, county) %>%
  tibble()

# grab the data
dat <- data_manage(
  load_existing_covid = FALSE,
  load_existing_mb = TRUE,
  user = "",
  private_key = "",
  census_key = ckey,
  weekly_data = FALSE,
  county_data = TRUE)

# load the data
# load("../data/covid_voting_data_daily_county.Rdat")
df <- dat$time_df
s_df <- dat$ste_df
cty_df <- dat$cty_df

# incubation period and onset-to-death distribution
# incub : 5.1,0.86; death : 17.8, 0.45
death_time_p_tiles <- 
  EnvStats::qgammaAlt(
    c(.2, 0.5, 0.8), 5.1, cv = 0.86, lower.tail = TRUE, log.p = FALSE) +
  EnvStats::qgammaAlt(
    c(.2, 0.5, 0.8), 17.8, cv = 0.45, lower.tail = TRUE, log.p = FALSE)

death_window <- round(death_time_p_tiles, 0)

# for ease, remove negative counts
# we need to trace down the corrections
df$deaths[df$deaths < 0] <- 0

# remove irrelevant places
nix <- c(
  "Puerto Rico", "Northern Mariana Islands", "Virgin Islands",
  "American Samoa", "U.S. Virgin Islands", "Guam")

df %<>% filter(state %in% setdiff(unique(df$state), nix))
cty_df %<>% filter(state %in% setdiff(unique(df$state), nix))
s_df %<>% filter(state %in% setdiff(unique(df$state), nix))

# primary indicator variables
# excludes mail-in-only states
mail_only <- c(
    "Colorado", "Washington", "Hawaii", 
    "Wyoming", "Kansas", "Ohio", 
    "Alaska", "Oregon", "Utah")

# exclude before-COVID states
other_exclude <- c(
  "Iowa", "New Hampshire",
  "South Carolina", "Nevada")

exclude <- c(mail_only, other_exclude)

# we need to translate each rel s_df col into a time-running
# indicator in df, matching the actual days

df <- indicator_mk(
  s_df,
  df,
  delay = 10, # primary_period
  window_open = 13,
  window_close = 32,
  exclude)

# set origin date in data
orig <- as.Date("2020-03-01")
df$running <- as.integer(df$date - orig)

df <- other_indicators(df, orig)

# bring in county level characteristics
sel_char <- cty_df %>%
  select(-county, -state)

df <- df %>% left_join(sel_char, by = "fips")

# apply filtering, calculate rates

dF <- df %>%
  mutate(
    median_inc_ln = log(median_inc),
    pop_ln = log(pop))
  # filter(
  #   date >= "2020-03-01",
  #   date <= "2020-10-01")
dF <- dF %>% tidyr::drop_na(deaths) # this seems to change the matches?

# put the rate scale on deaths per 1000 people
# for visual clarity and interpretability
scale_mult <- 1000

dFr <- dF %>%
  mutate(
    death_rte = (deaths / pop) * scale_mult,
    case_rte = (cases / pop) * scale_mult,
    cum_death_rte = (deathsCum / pop) * scale_mult,
    cum_case_rte = (casesCum / pop) * scale_mult)

# # turnout quantiles
# trn_quant <- quantile(cty_df$trn_rte, na.rm = TRUE)

# # ruc quant
# ruc_quant <- quantile(as.integer(cty_df$ruc), na.rm = TRUE)

# # pop density quant
# pop_density_quant <- quantile(cty_df$pop_density, na.rm = TRUE)

# cty_quant <- list(
#   trn = trn_quant,
#   ruc = ruc_quant,
#   pop_density = pop_density_quant)

# manual changes
dFr <- filter(dFr, state != "Alaska", state != "Hawaii")

dFr %>% select(
  cum_death_rte, first_case,
  pop_density, black, hispanic, trump_share_2016,
  bacc, perc_65_up, Urate, median_inc_ln) %>%
  mutate_all(is.na) %>%
  colSums()

tmiss <- unique(dFr$fips[is.na(dFr$trump_share_2016)])
# SD County Oglala Lakota Co. 41602 -> 0.083
dFr$trump_share_2016[dFr$fips == tmiss] <- 0.083

mmiss <- unique(dFr$fips[is.na(dFr$median_inc_ln)])
# Rio Arriba Co, NM (from st. louis fed) 35039 -> log(41511)
# Dagget Co, Utah 49009 -> log(81250)
dFr$median_inc_ln[dFr$fips == mmiss[1]] <- log(41511)
dFr$median_inc_ln[dFr$fips == mmiss[2]] <- log(81250)

# add other datasets

# census delineation
# better to actually work with this in the context
# cendel <- readr::read_csv("data/census_delineation.csv")

# trump rallies
rally <- readr::read_csv("data/trump_rallies.csv")
rally <- select(rally, -speakers, -state)
rally$rallyday <- 1

dFr <- left_join(dFr, rally, by = c("date", "fips"))
dFr$rallyday[is.na(dFr$rallyday)] <- 0

load("data/poi_data.RData") # p3
p3$date <- as.Date(p3$date)

p3$running <- as.integer(p3$date - orig)
# the data currently ranges from 2020-01-01 to 2020-11-30
# THIS NEEDS TO BE UPDATED

dFr <- dFr %>% left_join(p3, on = c("fips", "running"))

save(
  dFr,
  # df,
  # cty_df,
  # s_df,
  # mail_only,
  # other_exclude,
  # death_time_p_tiles,
  # death_window,
  # cty_quant,
  file = "data/setup_data.RData")

readr::write_csv(dFr, file = "data/setup_data.csv")