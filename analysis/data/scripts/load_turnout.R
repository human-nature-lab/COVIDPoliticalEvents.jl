# author: Ben Snyder
# date: 10/22/2020

# Reads AL presidential primary election data from downloaded individual county csv files
# Adds AL data to turnout csv which must already contain data structure including county names for AL
# Writes result to a csv 'al_turnout.csv' which should be reviewed by coder before replacing original
readAL <- function() {
  pkgs <- c(
    "dplyr",
    "tibble",
    "magrittr"
  )
  
  for (pkg in pkgs) library(pkg, character.only = TRUE)
  
  t <- read.csv("data/2020_presidential_primary_turnout.csv")
  al <- t$county[t$state == "AL"]
  
  # count up regular, provisional, and absentee ballots
  for (c in al) {
    c1 <- gsub(" ", "", c, fixed = TRUE)
    
    p <- paste("data/2020_presidential_primary_raw/al_turnout/2020-Primary-", c1, ".csv", sep="")
    ip <- read.csv(p)
    
    abs <- ip$ABSENTEE[2]
    prov <- ip$PROVISIONAL[2]
    
    vals <- setdiff(setdiff(which(!is.na(ip[2,])), which(colnames(ip) == "PROVISIONAL")), which(colnames(ip) == "ABSENTEE"))
    l <- length(vals)
    vals <- vals[4:l]
    inp <- sum(ip[2,vals])
    
    ind <- intersect(which(t$county == c), which(t$state == "AL"))
    t$tot_reg[ind] <- inp
    t$tot_abs[ind] <- abs
    t$tot_prov[ind] <- prov
  }
  
  # count up num of polling places
  for (c in al) {
    c1 <- gsub(" ", "", c, fixed = TRUE)
    
    p <- paste("data/2020_presidential_primary_raw/al_turnout/2020-Primary-", c1, ".csv", sep="")
    ip <- read.csv(p)
    
    # clean out unnecessary columns
    ip[,which(is.na(ip[2,]))] <- NULL
    ip[1:3] <- NULL
    
    # filter out provisional and absentee counts from polling places
    poll <- colnames(ip)
    poll <- poll[poll != "ABSENTEE"]
    poll <- poll[poll != "PROVISIONAL"]
    
    # save result
    bama <- t %>% filter(state == "AL")
    fips <- bama$fips[bama$county == c]
    t$poll_places[t$fips == fips] <- length(poll)
  }
  
  write.csv(t, file = "data/al_turnout.csv")
}

# Reads AR presidential primary election data from downloaded party results csv files
# Writes result to a csv 'ar_turnout.csv' which should be reviewed by coder and copied into main turnout csv
readAR <- function() {
  pkgs <- c(
    "dplyr",
    "tibble",
    "readr",
    "stringr"
  )
  
  for (pkg in pkgs) library(pkg, character.only = TRUE)
  
  path <- "data/2020_presidential_primary_raw/ar_turnout/AKDEM.csv"
  t <- read.csv(path, as.is=TRUE)
  
  t$Dem_in_person <- NA
  t$Dem_abs <- NA
  t$Dem_early <- NA
  t$Dem_prov <- NA
  
  
  t$state <- "AR"
  le <- length(t[,1]) - 1
  cans <- seq(from=3, to=89, by=5)
  
  for (i in 3:le) {
    t$Dem_in_person[i] <- sum(as.numeric(t[i,cans]))
    t$Dem_early[i] <- sum(as.numeric(t[i,cans+1]))
    t$Dem_abs[i] <- sum(as.numeric(t[i,cans+2]))
    t$Dem_prov[i] <- sum(as.numeric(t[i,cans+3]))
    
  }
  
  path <- "data/2020_presidential_primary_raw/ar_turnout/AKREP.csv"
  tr <- read.csv(path)
  
  t$Rep_in_person <- NA
  t$Rep_abs <- NA
  t$Rep_early <- NA
  t$Rep_prov <- NA
  
  cans <- seq(from=3, to=14, by=5)
  
  for (i in 3:le) {
    t$Rep_in_person[i] <- sum(as.numeric(tr[i,cans]))
    t$Rep_early[i] <- sum(as.numeric(tr[i,cans+1]))
    t$Rep_abs[i] <- sum(as.numeric(tr[i,cans+2]))
    t$Rep_prov[i] <- sum(as.numeric(tr[i,cans+3]))
    
  }
  
  t$tot_reg <- t$Rep_in_person + t$Dem_in_person
  t$tot_early <- t$Rep_early + t$Dem_early
  t$tot_abs <- t$Rep_abs + t$Dem_abs
  t$tot_prov <- t$Rep_prov + t$Dem_prov
  
  t <- t[3:nrow(t),] %>%
    mutate(county = U.S..President...DEM..Vote.For.1.) %>%
    select(county, tot_reg, tot_early, tot_abs, tot_prov)
  
  write.csv(t, "data/ar_turnout.csv")
}

# counts absentee ballot applications accepted in Maine in order to 
# get a lower bound on in person turnout
readME <- function() {
  pkgs <- c(
    "dplyr",
    "tibble",
    "readr",
    "stringr",
    "lubridate"
  )
  
  for (pkg in pkgs) library(pkg, character.only = TRUE)
  
  path <- "data/2020_presidential_primary_raw/ME_abs.txt"
  t <- read.table(path, sep='|', header = TRUE)
  muns <- unique(t$MUNICIPALITY)
  counts <- rep_len(NA, length(muns))
  for (m in 1:length(muns)) {
    counts[m] <- length(setdiff(which(t$MUNICIPALITY == muns[m]), which(t$ACC.OR.REJ != "ACC")))
  }
  
  tbl <- tibble(muns, counts)
  tbl$cty <- NA
  
  path <- "data/2020_presidential_primary_raw/ME_in.csv"
  ctys <- read.csv(path)
  
  for (i in 1:length(tbl$muns)) {
    if (length(which(ctys$mun == tbl$muns[i])) >= 1) {
      tbl$cty[i] <- ctys$cty[ctys$mun == tbl$muns[i]] 
    }
  }
  
  write.csv(tbl, "data/me_turnout.csv")
}

# reads data on IL precinct numbers
readILPrec <- function() {
  pkgs <- c(
    "dplyr"
    )
  
  for (pkg in pkgs) library(pkg, character.only = TRUE)
  
  d <- read.csv("https://www.elections.il.gov/Downloads/ElectionOperations/ElectionResults/ByOffice/56/56-120-PRESIDENT-2020GP.csv")
  df<- d %>% filter(EISCandidateID == 170)
  
  precincts <- table(df$JurisName)
  munis <- names(precincts)
  prec <- tibble(munis, precincts)

  names(precincts)
  
  write.csv(prec, "data/il_precincts.csv")
}

# 
read_nj_abs <- function() {
  require(data.table)
  
  abs <- fread("data/2020_presidential_primary_raw/nj_turnout/nj_abs_raw.csv")
  
  # ballot must be accepted
  accepted <- abs[ballot_status == "Accepted",]
  
  ctys <- accepted[, .N, by=.(ballot_county)]
  ctys <- `colnames<-`(ctys, c("county","abs"))
  
  write.csv(ctys, file = "data/2020_presidential_primary_raw/nj_turnout/nj_abs.csv")
}

read_nc <- function() {
  require(magrittr)
  require(dplyr)
  
  turnout <- read.csv("data/2020_presidential_primary_raw/nc_turnout.txt", sep = "\t")
  
  # filter down to presidential primary
  turnout %<>% filter(substr(Contest.Name, 1, 12) == "PRESIDENTIAL")
  
  # aggregate to county
  counts <- turnout %>% select(County, Election.Day, One.Stop, Absentee.by.Mail, Provisional) %>% 
    group_by(County) %>% summarize(tot_reg = sum(Election.Day), one_stop = sum(One.Stop), tot_abs = sum(Absentee.by.Mail),
                                   tot_prov = sum(Provisional))
  
  # write csv of turnout
  write.csv(counts, file="data/2020_presidential_primary_raw/nc_turnout/nc_county_turnout.csv")
}
