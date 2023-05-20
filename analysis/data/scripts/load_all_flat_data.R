# With the updated data management system, this file is no longer needed
#
# authors: Ben Snyder
# date: 10/22/2020
#
# loads all data including county-level covid data, county-level demographic characteristics, and county-level social distancing data
# runs from start of pandemic on 2020-02-01 to most recent SafeGraph date

loadAllData <- function(end_date) {
  library("data.table")
  library("dplyr")
  
  source("scripts/data_management/load_county_char.R")
  source("scripts/data_management/load_county_covid.R")
  source("scripts/data_management/loadSafeGraph.R")
  
  dem <- loadCountyChar()
  cov <- loadCountyCovid()
  mob <- readRDS("data/safegraph_all_us_pandemic.rds")
  
  start <- "2020-01-21"
  end <- "2020-07-17"
  
  # standardize fips format
  dem$fips <- as.character(dem$fips)
  dem$fips[nchar(dem$fips) == 4] <- paste0("0",dem$fips[nchar(dem$fips) == 4])
  
  # number of counties and number of dates
  counties <- unique(c(mob$id, cov$fips, dem$fips))
  
  nc <- length(counties)
  nd <- as.numeric(as.Date(end)-as.Date(start)+1)
  
  date_range <- as.character(seq(as.Date(start), by = "day", length.out = as.Date(end)-as.Date(start)+1))
  date <- rep(date_range, times=nc)
  fips <- rep(counties, each=nd)
  
  DT <- setDT(tibble(fips, date))
  DT <- merge(DT, cov, by.x = c("fips", "date"), by.y = c("fips", "date"), all=TRUE)
  DT[,':='(state = NULL, county = NULL)]
  DT <- merge(DT, dem, by.x = c("fips"), by.y = c("fips"), all=TRUE)
  DT <- merge(DT, mob, by.x = c("fips", "date"), by.y = c("id", "date"), all=TRUE)
  
  write.csv(DT, "data/all_county_day.csv")
  
  return(DT)
}
