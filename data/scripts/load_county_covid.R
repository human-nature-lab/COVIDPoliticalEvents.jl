# authors: Ben Snyder
# date: 10/22/2020

# load covid data for all counties from NYT with added new_deaths and new_cases columns
loadCountyCovid <- function() {
  pkgs <- c(
    "dplyr",
    "magrittr",
    "data.table"
  )
  
  for (pkg in pkgs) library(pkg, character.only = TRUE)
  
  # THIS DATA NO LONGER IN USE
  # county-level infection time series
  # inf <- read_csv("https://raw.githubusercontent.com/JieYingWu/COVID-19_US_County-level_Summaries/master/data/infections_timeseries.csv")
  # county-level deaths time series
  # dth <- read_csv("https://raw.githubusercontent.com/JieYingWu/COVID-19_US_County-level_Summaries/master/data/deaths_timeseries.csv")
  
  
  # NYT county-level cases and deaths
  covid <- fread("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv", colClasses = list(character=1:4), stringsAsFactors = FALSE)
  
  # add new deaths and new cases columns to covid timeseries data
  covid[order(fips)]
  
  # remove unknown or improper county (city names)
  covid <- covid[fips!=""]
  
  # sort by fips and then split the data set by fips
  covid <- covid[order(fips)]
  ctys <- split(covid, covid$fips)
  
  # find previous cumulative cases for each day in each county to make finding new cases easy
  prev_cases <- rep_len(NA, length(covid$fips))
  prev_deaths <- rep_len(NA, length(covid$fips))
  i <- 1
  for (f in 1:length(ctys)) {
    p1 <- shiftCol(ctys[[f]]$cases, 1, "d", 0)
    p2 <- shiftCol(ctys[[f]]$deaths, 1, "d", 0)
    
    prev_cases[i:(i+length(p1)-1)] <- p1
    prev_deaths[i:(i+length(p2)-1)] <- p2
    i <- i + length(p1)
  }
  
  covid[, ':='(new_cases = cases - prev_cases,
          new_deaths = deaths - prev_deaths)]
  
  return(covid)
}

# dir "d" to shift column down replacing first n values in x with val or "u" to shift up
# and replace last n values of x with val
shiftCol <- function(x, n, dir, val) {
  if (length(x) == 1) {
    return(c(val))
  }
  if (dir == "d") {
    return(c(rep(val, n), x[seq(1:(length(x)-n))]))
  } else if (dir == "u") {
    return(c(x[-(seq(n))], rep(val, n)))
  } else {
    cat("Invalid dir")
    return()
  }
}

loadFLCovid <- function() {
  pkgs <- c(
    "dplyr",
    "tibble",
    "readr",
    "stringr",
    "lubridate"
  )
  
  for (pkg in pkgs) library(pkg, character.only = TRUE)
  
  case <- read_csv("https://opendata.arcgis.com/datasets/37abda537d17458bae6677b8ab75fcb9_0.csv")
  case$ChartDate <- as.Date(str_sub(case$ChartDate, 1, 10), format = '%Y/%m/%d')
  case <- arrange(case, case$ChartDate)
  
  dat <- read.csv("https://opendata.arcgis.com/datasets/a7887f1940b34bf5a02c6f7f27a5cb2c_0.csv")
  
  cty <- unique(case$County)
  
  tot <- NA
  cvd <- NA
  
  for (c in cty) {
    ptr <- 1
    
    case_county <- case[case$County == c,]
    cvd$pos_new <- length(case_county$ChartDate)
    dates <- unique(case_county$ChartDate)
    
    county <- rep_len(NA, length(dates))
    cvd <- tibble(county)
    cvd$county[ptr] <- c
    cvd$date <- dates
    cvd$pos_new <- 0
    cvd$new_0to17 <- 0
    cvd$new_18to64 <- 0
    cvd$new_65plus <- 0
    cvd$new_age_unk <- 0
    
    for (d in dates) {
      subs <- case_county[which(case_county$ChartDate == d),]
      
      cvd$county[ptr] <- c
      cvd$pos_new[ptr] <- length(which(subs$Case_ == "Yes"))
      cvd$new_age_unk[ptr] <- length(which(is.na(subs$Age)))
      cvd$new_0to17[ptr] <- length(which(subs$Age < 18))
      cvd$new_65plus[ptr] <- length(which(subs$Age >= 65))
      cvd$new_18to64[ptr] <- length(which(subs$Age >= 18)) - cvd$new_65plus[ptr]
      
      ptr <- ptr + 1
    }
    
    if (is.na(tot)) {
      tot <- cvd
    } else {
      tot <- rbind(tot, cvd)
    }
  }
  
}

loadWICovid <- function() {
  pkgs <- c(
    "dplyr",
    "tibble",
    "readr",
    "stringr",
    "lubridate"
  )
  
  for (pkg in pkgs) library(pkg, character.only = TRUE)
  
  col <- cols(OBJECTID = "d", GEOID = "d", GEO = "c", NAME = "c", LoadDttm = "c", NEGATIVE = "d", POSITIVE = "d", HOSP_YES = "d", HOSP_NO = "d", HOSP_UNK = "d", POS_FEM = "d", POS_MALE = "d", POS_OTH = "d", POS_0_9 = "d", POS_10_19 = "d", POS_20_29 = "d", POS_30_39 = "d", POS_40_49 = "d", POS_50_59 = "d", POS_60_69 = "d", POS_70_79 = "d", POS_80_89 = "d", POS_90 = "d", DEATHS = "d", DTHS_FEM = "d", DTHS_OTH = "d", DTHS_MALE = "d", DTHS_0_9 = "d", DTHS_10_19 = "d", DTHS_20_29 = "d", DTHS_30_39 = "d", DTHS_40_49 = "d", DTHS_50_59 = "d", DTHS_60_69 = "d", DTHS_70_79 = "d", DTHS_80_89 = "d", DTHS_90 = "d", IP_Y_0_9 = "d", IP_Y_10_19 = "d", IP_Y_20_29 = "d", IP_Y_30_39 = "d", IP_Y_40_49 = "d", IP_Y_50_59 = "d", IP_Y_60_69 = "d", IP_Y_70_79 = "d", IP_Y_80_89 = "d", IP_Y_90 = "d", IP_N_0_9 = "d", IP_N_10_19 = "d", IP_N_20_29 = "d", IP_N_30_39 = "d", IP_N_40_49 = "d", IP_N_50_59 = "d", IP_N_60_69 = "d", IP_N_70_79 = "d", IP_N_80_89 = "d", IP_N_90 = "d", IP_U_0_9 = "d", IP_U_10_19 = "d", IP_U_20_29 = "d", IP_U_30_39 = "d", IP_U_40_49 = "d", IP_U_50_59 = "d", IP_U_60_69 = "d", IP_U_70_79 = "d", IP_U_80_89 = "d", IP_U_90 = "d", IC_YES = "d", IC_Y_0_9 = "d", IC_Y_10_19 = "d", IC_Y_20_29 = "d", IC_Y_30_39 = "d", IC_Y_40_49 = "d", IC_Y_50_59 = "d", IC_Y_60_69 = "d", IC_Y_70_79 = "d", IC_Y_80_89 = "d", IC_Y_90 = "d", POS_AIAN = "d", POS_ASN = "d", POS_BLK = "d", POS_WHT = "d", POS_MLTOTH = "d", POS_UNK = "d", POS_E_HSP = "d", POS_E_NHSP = "d", POS_E_UNK = "d", DTH_AIAN = "d", DTH_ASN = "d", DTH_BLK = "d", DTH_WHT = "d", DTH_MLTOTH = "d", DTH_UNK = "d", DTH_E_HSP = "d", DTH_E_NHSP = "d", DTH_E_UNK = "d", POS_HC_Y = "d", POS_HC_N = "d", POS_HC_UNK = "d", DTH_NEW = "d", POS_NEW = "d", NEG_NEW = "d", TEST_NEW = "d")
  
  # WI public health county-level tests and deaths
  covid <- read_csv("https://opendata.arcgis.com/datasets/b913e9591eae4912b33dc5b4e88646c5_10.csv", col_types = col)
  covid <- covid[covid$GEO != "Census tract",] # remove census tract data--we only care about the county level right now
  
  cvd <- tibble(fips = covid$GEOID, geo = covid$GEO, name = covid$NAME)
  cvd$date <- as.Date(str_sub(covid$LoadDttm, 1, 10), format = '%Y/%m/%d') # get date of each entry
  
  cvd$pos <- covid$POSITIVE
  cvd$neg <- covid$NEGATIVE
  cvd$pos_new <- covid$POS_NEW
  cvd$neg_new <- covid$NEG_NEW
  cvd$test_new <- covid$TEST_NEW
  
  cvd$death <- covid$DEATHS
  cvd$death_new <- covid$DTH_NEW
  
  cvd$hosp_yes <- covid$HOSP_YES
  cvd$hosp_no <- covid$HOSP_NO
  cvd$hosp_unk <- covid$HOSP_UNK
  
  cvd$pos_0to9 <- covid$POS_0_9
  cvd$pos_10to19 <- covid$POS_10_19
  cvd$pos_20to29 <- covid$POS_20_29
  cvd$pos_30to39 <- covid$POS_30_39
  cvd$pos_40to49 <- covid$POS_40_49
  cvd$pos_50to59 <- covid$POS_50_59
  cvd$pos_60to69 <- covid$POS_60_69
  cvd$pos_70to79 <- covid$POS_70_79
  cvd$pos_80to89 <- covid$POS_80_89
  cvd$pos_90plus <- covid$POS_90
  
  return(cvd) 
}
