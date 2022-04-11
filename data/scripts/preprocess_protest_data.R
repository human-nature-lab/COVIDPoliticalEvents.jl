# clean the protest data

source("scripts/handle_protest_data.R")

protest_rawpth <- "data/USA_2020_Oct10update.csv"
protest_pthclean <- "data/clean_protest_data.csv"
protest_spthprocessed <- "data/processed_protest_data.csv"

pkgs <- c("dplyr", "magrittr", "tibble", "lubridate", "ggplot2")
for (pkg in pkgs) require(pkg, character.only = TRUE)

# protests
# assume that the data is already clean (function to do this
# appears in same file)
pdat <- organize_protest_data(
    rawpth = protest_rawpth,
    spthclean = protest_pthclean,
    spthprocessed = protest_spthprocessed
)

pdat %<>% select(
    fips, EVENT_DATE, event_count, size
)

readr::write_csv(pdat, file = "data/final_protest_data.csv")
