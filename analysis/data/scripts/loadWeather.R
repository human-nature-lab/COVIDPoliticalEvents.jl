# WARNING: This code is essentially non-functional at this time
# author: Ben Snyder
# date: 10/22/2020

load_weather <- function() {
  library(data.table)
  #library(httr)
  library(sf)
  library(R.utils)
  
  if (!file.exists("data/2020.csv")) {
    download.file("https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/by_year/2020.csv.gz", "data/2020.csv.gz")
    R.utils::gunzip("data/2020.csv.gz", remove=FALSE) 
  }
  
  # load daily weather summary and stations metadata so as to match each daily observation to a geo location
  # daily weather data from GHCND daily summaries data by year at https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/by_year/
  # station metadata from GHCND daily summaries main file at https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/
  daily_weather <- fread("data/2020.csv", colClasses = list(character=2))
  stations <- readtext::readtext("https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/ghcnd-stations.txt")
  
  # process stations metadata which is in a non-standard text format with dedicated ASCII columns
  # save stations data as a data.table
  stations <- strsplit(stations$text, "\n")
  stations <- as.data.table(stations)
  stations[, ':='(id = substr(V1, 1, 11),
           lat = as.numeric(substr(V1, 13, 20)),
           lon = as.numeric(substr(V1, 22, 30)),
           elevation = as.numeric(substr(V1, 32, 37)),
           name = substr(V1, 42, 71),
           gns_network = substr(V1, 73, 75),
           hcn_crn_network = substr(V1, 77, 79),
           wmo_id = substr(V1, 81, 85),
           state = substr(V1, 39, 40),
           country = substr(V1, 1, 2))]
  stations$V1 <- NULL
  
  # restrict stations to those with coutnry codes corresposnding to US and US territories
  allowed_countries <- c("AQ", "CQ", "GQ", "JQ", "LQ", "MQ", "RQ", "VQ", "WQ", "US")
  stations <- stations[country %in% allowed_countries,]
  
  # add descriptive column names and filter to stations in stations dataset. Convert date column to readable date format.
  daily_weather <- `colnames<-`(daily_weather, c("id", "date", "obs_type", "obs", "measurement_flag", "quality_flag", "source_flag", "obs_time"))
  daily_weather <- daily_weather[id %in% stations$id,]
  daily_weather[, date := as.Date(date, format="%Y%m%d")]
  
  # read in GeoJSON file with county borders from https://eric.clst.org/tech/usgeojson/ attribution: US Census Bureau
  us_counties <- st_read("https://eric.clst.org/assets/wiki/uploads/Stuff/gz_2010_us_050_00_500k.json") 
  us_counties$fips <- paste0(us_counties$STATE, us_counties$COUNTY)
  
  # get counties for each station through coordinates and us county shapefile
  station_coords <- stations[,.(lon, lat)]
  stations[,county := lon_lat_to_county(station_coords, us_counties)]
  
  # merge station data with weather observations
  daily_weather <- merge(daily_weather, stations, by.x = "id", by.y = "id", all = TRUE)
  daily_weather <- daily_weather[!is.na(date) & !is.na(county),]
  
  # aggregate data at date, county, and observation type as mean of observations
  county_weather <- daily_weather[, list(means = mean(obs, na.rm = TRUE)), by = list(obs_type, date, county)]
  
  # widen data so each observation type has its own column
  county_weather <- county_weather[obs_type %in% c("PRCP","TMAX", "TMIN", "TAVG"),]
  county_weather <- dcast(county_weather, county + date ~ obs_type, value.var = 'means', drop = FALSE, fill = NA)
  
  saveRDS(county_weather, "data/weather.rds")
}

# based on a map of US county borders, locates each of a set of lon & lat coordinates in its corresponding county
# coords     data.frame containing lon coordinates in the first column and lat in the second
# county_map sf of US county borders with county fips in column fips
lon_lat_to_county <- function (lon_lat, county_map) {
  # convert lon_lat data.frame to an sf POINTS object
  map_pts <- st_as_sf(lon_lat, coords = 1:2, crs = 4326)
  
  # transform spatial data to some planar coordinate system (e.g. Web Mercator) for geometric operations
  county_map <- st_transform(county_map, crs = 3857)
  map_pts <- st_transform(map_pts, crs = 3857)
  
  # find fips of county intersected by each point
  counties <- county_map$fips
  ii <- as.integer(st_intersects(map_pts, county_map))
  counties[ii]
}

