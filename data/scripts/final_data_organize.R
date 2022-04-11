# R-side data preprocessing
# authors: ben snyder and eric martin feltham

pkgs <- c("dplyr", "magrittr", "tibble", "lubridate", "ggplot2")
for (pkg in pkgs) require(pkg, character.only = TRUE)

source("scripts/load_county_char.R")

preprocess <- function(
  scale_mult = 10000,
    # put the rate scale on deaths per 10000 people
    # for visual clarity and interpretability
  origindate = "2020-03-01",
  ckey, # census api key
  spth = "data/setup_data.csv",
  blsdata = "data/bls_unemployment.csv",
  delindata = "data/census_delineation.csv",
  rucdata = "data/ruralurbancodes2013.csv",
  primary_turnout_data = "data/2020_presidential_primary_turnout.csv",
  rally_data = "data/trump_rallies.csv",
  jhu_output_path = "data/cvdata.csv",
  jhu_rejects_path = "data/cvrejects.csv",
  protest_data = "data/final_protest_data.csv"
) {

  fips_key <- tidycensus::fips_codes %>%
    mutate(fips = as.integer(state_code) * 1000 + as.integer(county_code)) %>%
    select(state_name, fips, county) %>%
    tibble()
  colnames(fips_key)[1] <- "state"

  cvdat <- getjhu(
    output_path = jhu_output_path,
    rejects_path = jhu_rejects_path,
    origindate = origindate
  )

  # or, load from a file:
  # cvdat <- readr::read_csv(jhudata)

  # adapted from data_manage
  X <- loadCountyChar() %>%
    tibble()

  # BLS unemployment data [note unemployment also from ACS]
  bls <- readr::read_csv(blsdata) %>%
    mutate(
        fips = as.character(stateFIPS * 1000 + countyFIPS),
        Urate = Urate / 100) %>%
    select(fips, Urate)

  bls$fips[nchar(bls$fips) == 4] <- paste0("0", bls$fips[nchar(bls$fips) == 4])

  cen_delin <- readr::read_csv(delindata) %>%
      mutate(fips = paste0(fips_state, fips_county)) %>%
      select(-county, -state, -fips_state, -fips_county)

  # rural urban code
  ru <- readr::read_csv(rucdata) %>%
    mutate(
      fips = FIPS, ruc = as.character(RUCC_2013), rucDesc = Description
    ) %>%
    select(fips, ruc, rucDesc)

  # add turnout and polling data
  raw_to <- readr::read_csv(primary_turnout_data)

  raw_to %<>%
    select(fips, poll_places, voter_per_poll, tot_reg, date) %>%
    mutate(primary = date, date = NULL)

  # merge all county-level data
  cty_df <- X %>%
    left_join(bls, by = "fips") %>%
    left_join(cen_delin, by = "fips") %>%
    mutate(fips_n = as.integer(fips)) %>%
    left_join(raw_to, by = c("fips_n" = "fips")) %>%
    mutate(fips_n = NULL) %>%
    left_join(ru, by = "fips")

  # create turnout variables
  colnames(cty_df)[c(1, 3)] <- c("fipschar", "abbr")
  ctydat <- cty_df %>%
    mutate(
      tot_reg = case_when(tot_reg < 0 ~ 0, TRUE ~ tot_reg),
      trn_rte = tot_reg / pop
      ) %>%
    select(-area_name) %>%
    mutate(fips = as.integer(fipschar)) %>%
    left_join(fips_key, by = "fips")

  # incubation period and onset-to-death distribution
  # incub : 5.1,0.86; death : 17.8, 0.45
  death_time_p_tiles <- 
    EnvStats::qgammaAlt(
      c(.2, 0.5, 0.8), 5.1, cv = 0.86, lower.tail = TRUE, log.p = FALSE) +
    EnvStats::qgammaAlt(
      c(.2, 0.5, 0.8), 17.8, cv = 0.45, lower.tail = TRUE, log.p = FALSE)
  death_window <- round(death_time_p_tiles, 0)

  # remove irrelevant places
  # nix <- c(
  #   "Puerto Rico", "Northern Mariana Islands", "Virgin Islands",
  #   "American Samoa", "U.S. Virgin Islands", "Guam")

  # excludes mail-in-only states
  mail_only <- c(
      "Colorado", "Washington", "Hawaii", 
      "Wyoming", "Kansas", "Ohio", 
      "Alaska", "Oregon", "Utah"
  )

  # exclude before-COVID states
  other_exclude <- c(
    "Iowa", "New Hampshire",
    "South Carolina", "Nevada")

  exclude <- c(mail_only, other_exclude)

  ctydat$validprimary <- !is.na(ctydat$primary) * 1
  ctydat$validprimary[ctydat$state %in% exclude] <- FALSE

  ctydat %<>%
    mutate(median_inc_ln = log(median_inc), pop_ln = log(pop))

  ctydat <- filter(
    ctydat, state != "Alaska", state != "Hawaii", state != "Puerto Rico")

  # manual changes
  ctydat %>% select(
    pop_density, black, hispanic, trump_share_2016,
    bacc, perc_65_up, Urate, median_inc_ln) %>%
    mutate_all(is.na) %>%
    colSums()

  tmiss <- unique(ctydat$fips[is.na(ctydat$trump_share_2016)])
  # SD County Oglala Lakota Co. 41602 -> 0.083
  ctydat$trump_share_2016[ctydat$fips == tmiss] <- 0.083

  mmiss <- unique(ctydat$fips[is.na(ctydat$median_inc_ln)])
  # Rio Arriba Co, NM (from st. louis fed) 35039 -> log(41511)
  # Dagget Co, Utah 49009 -> log(81250)
  ctydat$median_inc_ln[ctydat$fips == mmiss[1]] <- log(41511)
  ctydat$median_inc_ln[ctydat$fips == mmiss[2]] <- log(81250)

  # set origin date in data
  orig <- as.Date(origindate)
  cvdat$running <- as.integer(cvdat$date - orig)

  # primary treatment variable
  cvdat$primary <- 0

  fc <- cvdat %>%
    filter(cases > 0) %>%
      group_by(fips) %>%
      slice(which.min(running)) %>%
      select(fips, running) %>%
      rename(firstcase = running)
  fd <- cvdat %>%
    filter(deaths > 0) %>%
    group_by(fips) %>%
    slice(which.min(running)) %>%
    select(fips, running) %>%
    rename(firstdeath = running)

  for (i in 1:nrow(ctydat)) {
    pdate <- ctydat$primary[i]
    fps <- ctydat$fipschar[i]
    validp <- ctydat$validprimary[i]
    cvdat$primary[cvdat$date == pdate & cvdat$fips == fps & validp] <- 1
  }

  cvdat <- cvdat %>%
    left_join(select(ctydat, -primary), by = c("fips" = "fipschar")) %>%
    left_join(fc, by = "fips") %>%
    left_join(fd, by = "fips") %>%
    mutate(fipschar = fips, fips = as.integer(fips))

  # apply filtering, calculate rates

  cvdat <- cvdat %>%
    mutate(
      death_rte = (deaths / pop) * scale_mult,
      case_rte = (cases / pop) * scale_mult,
      cum_death_rte = (deathscum / pop) * scale_mult,
      cum_case_rte = (casescum / pop) * scale_mult
    )

  cvdat <- filter(
    cvdat, state != "Alaska", state != "Hawaii", state != "Puerto Rico")

  # add other datasets

  # trump rallies
  rally <- readr::read_csv(rally_data)
  rally <- select(rally, -speakers, -state)
  rally$rallyday <- 1

  cvdat <- left_join(cvdat, rally, by = c("date", "fips"))
  cvdat$rallyday[is.na(cvdat$rallyday)] <- 0
  cvdat <- cvdat[order(cvdat$fips, cvdat$date), ]

  ##### protest data analysis
  pdat <- readr::read_csv(protest_data)

  pdat %<>%
    rename(
      prdate = EVENT_DATE, prcount = event_count, prsize = size
    )

  cvdat <- cvdat %>%
    left_join(pdat, by = c("fips", "date" = "prdate"))

  cvdat$prcount[is.na(cvdat$prcount)] <- 0
  cvdat$prsize[is.na(cvdat$prsize)] <- 0

  cvdat$protest <- 0
  cvdat$protest[cvdat$prcount > 0] <- 1

  readr::write_csv(cvdat, file = spth)

  return(cvdat)
}
