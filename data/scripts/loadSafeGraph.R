# author: Ben Snyder
# date: 04/01/2021
# version 1.6

loadPlaces <- function(core_place_dir = "Core_Places_US") {
  library(data.table)

  dir1 <- paste0(core_place_dir, "/2020/")
  dir2 <- paste0(core_place_dir, "/2021/")
  months_2020 <- system2("ls", args = dir1, stdout = TRUE)
  months_2021 <- system2("ls", args = dir2, stdout = TRUE)

  years <- c(
    rep("2020/", length(months_2020)), rep("2021/", length(months_2021))
  )
  months <- c(months_2020, months_2021)

  vintages <- paste0(years, months)

  places <- rbindlist(lapply(vintages, loadPlaceMonth))
  setkey(places, safegraph_place_id)
  places <- unique(places)

  return(places)
}

loadPlaceMonth <- function(vintage, core_place_dir = "Core_Places_US") {
  path <- paste0(core_place_dir, "/", vintage, "/combined_places.rds")

if(file.exists(path)) {
  places <- readRDS(path)

  } else {

    files <- system2(
      "ls", args = paste0(core_place_dir ,"", vintage, "/core*.csv"),
      stdout = TRUE
    )

    places <- NULL

    for (file in files) {
      piece_raw <- fread(
        file, sep = ",", header = TRUE, stringsAsFactors = FALSE,
        showProgress = FALSE, integer64 = "character"
      )

      piece <- piece_raw[,.(safegraph_place_id,
        parent_safegraph_place_id,
        location_name,
        top_category,
        sub_category,
        naics_code,
        latitude,
        longitude)]

      piece$placekey <- NA
      piece$parent_placekey <- NA

      #if("placekey" %in% colnames(piece_raw)) {
      # piece$placekey <- piece_raw$placekey
      #} else {
      # piece$placekey <- NA
      #}

      #if("parent_placekey" %in% colnames(piece_raw)) {
      # piece$parent_placekey <- piece_raw$parent_placekey
      #} else {
      # piece$parent_placekey <- NA
      #}

      if(is.null(places)) {
        places <- piece
        } else {
          places <- rbindlist(list(places, piece), fill = TRUE)
      } 

  }

  saveRDS(places, paste0(core_place_dir, "/", vintage, "/combined_places.rds"))
}

return(places)
}

loadPatterns <- function(places = NULL) {
    library(data.table)

    months_2020 <- system2("ls", args = "Monthly_Places_Patterns/2020/", stdout = TRUE)
    months_2021 <- system2("ls", args = "Monthly_Places_Patterns/2021/", stdout = TRUE)

    years <- c(rep("2020/", length(months_2020)), rep("2021/", length(months_2021)))
    months <- c(months_2020, months_2021)

    vintages <- paste0(years, months)

    visits <- rbindlist(lapply(vintages, loadPatternMonth, places))
}

loadPatternMonth <- function(vintage, places) {
    files <- system2("ls", args = paste0("Monthly_Places_Patterns/", vintage, "/*.csv"), stdout = TRUE)

    patterns <- NULL

    for (file in files) {
        piece <- fread(file, sep = ",", header = TRUE, stringsAsFactors = FALSE, showProgress = FALSE, colClasses = list(character="poi_cbg"))

        piece <- piece[,c("safegraph_place_id", "date_range_start", "visits_by_day", "poi_cbg")]

        if (is.null(patterns)) {
            patterns <- piece
        } else {
            patterns <- rbind(patterns, piece, fill = TRUE)
        }
    }

    range <- seq(as.Date(substr(patterns$date_range_start[1], 1, 10)), by = "month", length.out = 2)
    range_len <- range[2] - range[1]

    days <- as.character(seq(range[1], by = "day", length.out = as.integer(range_len)))

    if (is.null(places)) {
        if (vintage == "2020/02") {
            place_month <- "2020/03"
        } else {
            place_month <- vintage
        }

        places <- loadPlaceMonth(place_month)
    }

    naics <- places[, .(safegraph_place_id, naics_code)]
    setkey(naics, safegraph_place_id)
    setkey(patterns, safegraph_place_id)
    parents <- unique(places$parent_safegraph_place_id)

    patterns <- patterns[!(parents)]

    patterns <- merge(patterns, naics, x.all = TRUE)

    visits <- substr(
      patterns$visits_by_day, 2, (nchar(patterns$visits_by_day) - 1)
    )
    visits <- as.integer(unlist(strsplit(visits, ",")))

    date <- rep(days, nrow(patterns))
    fips <- rep(substr(patterns$poi_cbg, 1, 5), each = range_len)
    naics_code <- rep(patterns$naics, each = range_len)

    daily_visits <- data.table(date, visits, fips, naics_code)

    daily_visits <- daily_visits[, .(visits=sum(visits)), by = .(date, fips, naics_code)]

return(daily_visits)
}

# updateMobility updates an existing R object of SafeGraph data up to a new, later end date
# regions   vector of regions strings, either state abbreviations or state or county fips codes. Mixing types is not supported. 
#           "all" will get all available counties.
# end       string with date of last desired data entry, maximum "2020-06-13"
# aggCounty if true, aggregates each day's data before combining and returns data aggregated to county level. Saves memory for
#           large datasets compared to doing the two operations separately.
# prevfile  path to the previous dataset as RDS file which new data will be appended to
updateMobility <- function(regions, end, aggCounty = TRUE, prevFile) {
  prev <- readRDS(prevFile)

  if (aggCounty) {
    prevEnd <- max(as.Date(prev$date))
    } else {
      prevEnd <- max(as.Date(prev$date_range_start))
  }
  start <- as.character(prevEnd + 1)

  new <- loadMobility(regions = regions, start = start, end = end, aggCounty = aggCounty)

  df <- rbindlist(list(prev, new), fill = TRUE)

  return(df)
}

# loadMobility loads SafeGraph social distancing data for the census tracts within specified regions (counties or states)
# level     DEPRECATED, WILL BE REMOVED
# regions   vector of regions strings, either state abbreviations or state or county fips codes. Mixing types is not supported. 
#           "all" will get all available counties.
# start     string with date of first desired data entry, minimum based on SafeGraph is "2019-01-01"
# end       string with date of last desired data entry, maximum "2020-06-13"
# aggCounty if true, aggregates each day's data before combining and returns data aggregated to county level. Saves memory for
#           large datasets compared to doing the two operations separately.
loadMobility <- function (level, regions = "WI", start="2020-03-01", end="2020-03-01", aggCounty = FALSE) {
  # load necessary packages
  pkgs <- c(
    "dplyr",
    "magrittr",
    "data.table"
    )
  
  for (pkg in pkgs) library(pkg, character.only = TRUE)
  
  # create range of dates to gather data for
  range <- seq(as.Date(start), by = "day", length.out = as.Date(end)-as.Date(start)+1)
  
  # load in data for the whole range all at once
  if (aggCounty) {
    df <- rbindlist(lapply(range, aggLoadDay, regions), fill = TRUE)
    } else {
      df <- rbindlist(lapply(range, loadDay, regions), fill = TRUE)
  }

  return(df)
}

fips <- function (abbr) {
    code <- c(
      "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "GU", "HI", "ID", "IL", "IN", "IA",
      "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY",
      "NC", "ND", "OH", "OK", "OR", "PA", "PR", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV",
      "WI", "WY")
    state <- c("alabama", "alaska", "arizona", "arkansas", "california", "colorado", "connecticut", 
      "delaware", "district of columbia", "florida", "georgia", "guam", "hawaii", "idaho", "illinois",
      "indiana", "iowa", "kansas", "kentucky", "louisiana", "maine", "maryland", "massachusetts",
      "michigan", "minnesota", "mississippi", "missouri", "montana", "nebraska", "nevada", "new hampshire",
      "new jersey", "new mexico", "new york", "north carolina", "north dakota", "ohio", "oklahoma", "oregon",
      "pennsylvania", "puerto rico", "rhode island", "south carolina", "south dakota", "tennessee", "texas",
      "utah", "vermont", "virginia", "washington", "west virginia", "wisconsin", "wyoming")
    fips <- c(
      "01", "02", "04", "05", "06", "08", "09", "10", "11", "12", "13", "66", "15", "17", "18", "19", "20",
      "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37",
      "38", "39", "40", "41", "42", "72", "44", "45", "46", "47", "48", "49", "50", "50", "51", "53", "54",
      "55", "56"
      )

    if (nchar(abbr) == 2) {
      return(fips[which(code == abbr)])
      } else {
        return(fips[which(state == tolower(abbr))])
    }
}

# loadDay returns one day of SafeGraph social distancing data filtered to specified regions and aggregated to the county
# level. Requires decompressed csv's in original SafeGraph filing system (as on Hector).
# d       string of date desired, between "2019-01-01" and "2020-06-13"
# regions vector of regions strings, either state abbreviations or state or county fips codes. "all" will get all 
#         available counties.
aggLoadDay <- function(d, regions) {
  df <- loadDay(d, regions)

  return(aggregateMobility(df))
}

# loadDay returns one day of SafeGraph social distancing data filtered to specified regions. Requires decompressed csv's 
# in original SafeGraph filing system (as on Hector).
# d       string of date desired, between "2019-01-01" and "2020-06-13"
# regions vector of regions strings, either state abbreviations or state or county fips codes
loadDay <- function(d, regions) {
  mon <- substr(d, 6, 7)
  day <- substr(d, 9, 10)
  p <- paste0("Social_Distancing_Metrics_v2.1/2020", "/", mon, "/", day, "/2020-", mon, "-", day, "-social-distancing.csv")
  
  df <- data.table::fread(p, sep = ",", header = TRUE, stringsAsFactors = FALSE, colClasses = list(character="origin_census_block_group"), showProgress = FALSE)
  
  # add leading zeroes where needed
  missing <- which(nchar(df$origin_census_block_group) == 11)
  df$origin_census_block_group[missing] <- paste0("0", df$origin_census_block_group[missing])
  
  # add columns for county and state fips
  df$county_fips <- substr(df$origin_census_block_group, 1, 5)
  df$state_fips <- substr(df$county_fips, 1, 2)
  
  # filter down to desired states or counties
  if (regions == "all") {
    return(df)
}
st <- NULL
if (nchar(regions[1]) <= 2) {
    if (is.na(as.numeric(regions)[1])) {
      st <- df[state_fips %in% fips(regions),]
      } else {
        st <- df[state_fips %in% regions]
    }
    } else {
        st <- df[county_fips %in% regions]
    }

    return(st)
}

# aggregateMobility returns social distancing metrics aggregated (usually by weighted average) at the county or state level
# depending on inputs
# df    a data table as returned by loadMobility
# level a string indicating level at which to aggregate, either "county" or "state"
aggregateMobility <- function(df, level = "county") {
  # create unique id combining date and county/state fips at which to aggregate
  df[, date := substr(date_range_start, 1, 10)]
  if (level == "county") {
    df$id <- df$county_fips
    } else if (level == "state") {
      df$id <- df$state_fips
      } else {
        cat("Invalid level input")
        return()
    }

  # using data.table take sums and means of social distancing metrics, aggregating by id
  mob <- df[, .(device_count=sum(device_count),
    candidate_device_count=sum(candidate_device_count),
    completely_home_device_count=sum(completely_home_device_count),
    mean_median_home_dwell_time=weighted.mean(median_home_dwell_time, device_count, na.rm = TRUE),
    mean_non_home_dwell_time=weighted.mean(median_non_home_dwell_time, device_count, na.rm = TRUE),
    mean_median_distance_travelled_from_home=weighted.mean(distance_traveled_from_home, device_count, na.rm = TRUE),
    mean_median_percent_time_home=weighted.mean(median_percentage_time_home, device_count, na.rm = TRUE)), by=.(date, id)]
  mob[, proportion_completely_home := completely_home_device_count/device_count]
  
  return(mob)
}

# applyToID returns a vector of the specified operation applied across data points matching ID code to all columns specified 
# code   id code to filter dataset as a string
# dfs    data frame containing column at position id_col of ID codes including the value in code
# cols   non-empty vector of numerics indicating columns to average within ID code
# id_col numeric specifying which column of dfs contains ID codes
# func   function to apply to specified columns of dfs
# ...    extra arguments passed to func
applyToID <- function(code, dfs, cols, id_col, func, ...) {
  dfs <- dfs[dfs[,id_col] == code,]
  
  return(append(code, lapply(dfs[, cols], func, ...)))
}

# finds weights from dfs based on matching id from id_col to code and returns weighted mean of specified columns.
# Intended for use with aggregateMobility.
# code       id code to filter dataset as a string
# dfs        data frame containing column at position id_col of ID codes including the value in code
# cols       non-empty vector of numerics indicating columns to average within ID code
# id_col     numeric specifying which column of dfs contains ID codes
# weight_col column of dfs in which to find weights
# ...        extra arguments passed to func
deviceWeightMean <- function(code, dfs, cols, id_col, weight_col, ...) {
  dfs <- dfs[dfs[,id_col] == code,]
  
  return(append(code, lapply(dfs[,cols], weighted.mean, dfs[,weight_col], ...)))
}
