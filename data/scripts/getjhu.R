# adapted from covidestim

#!/usr/bin/env Rscript
library(dplyr,     warn.conflicts = FALSE)
library(readr,     warn.conflicts = FALSE)
library(docopt,    warn.conflicts = FALSE)
library(magrittr,  warn.conflicts = FALSE)
library(cli,       warn.conflicts = FALSE)
library(stringr,   warn.conflicts = FALSE)

getjhu <- function(
    output_path = "data/cvdata.csv",
    rejects_path = "data/cvrejects.csv",
    origindate = "2020-03-01"
) {

    # paths to online JHU date
    cases_path = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv";

    deaths_path = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv";

    cols(
    FIPS = col_character()
    ) -> col_types.jhuCases

    cols(
    FIPS = col_character()
    ) -> col_types.jhuDeaths


    cases <- read_csv(cases_path, col_types = col_types.jhuCases)

    deaths <- read_csv(deaths_path, col_types = col_types.jhuDeaths)

    date_regex <- '\\d+/\\d+/\\d{2}'

    reformat <- function(df, data_type = 'cases') {

    # Pivot just the columns that are dates. Name the 'value' key either 'cases'
    # or 'deaths'
    tidyr::pivot_longer(df, matches(date_regex),
                        names_to = 'date', values_to = data_type) %>%

    # Get rid of unneeded columns. The I() construct forces `data_type` to be
    # evaluated as a string, rather than being quoted
    select(date, fips = FIPS, I(data_type)) %>%

    # FIPS is unfortunately specified as a decimal number in the CSV. This hack
    # fixes that.
    mutate(fips = fips %>% as.numeric %>% as.character %>%
            str_pad(., ifelse(str_length(.) > 2, 5, 2), pad = '0')) %>%

    # Reformat the date to be consistent with other `data-products` .csv's.
    mutate_at('date', as.Date, '%m/%d/%y')
    }

    # Compute the diff to go from cumulative cases/deaths to incident cases/deaths.
    # But, don't allow for any days to have negative case/death counts.
    nonzeroDiff <- function(vec) pmax(0, vec - lag(vec, default = 0))

    filterStateFips <- function(df)
    filter(df,
            !is.na(fips),                      # No invalid fips codes
            str_length(fips) == 5)             # No states or territories

    filterBannedFips <- function(df)
    filter(df,
            !str_detect(fips, "^800[0-5]\\d"), # The "Out of [statename]" tracts
            !str_detect(fips, "^900[0-5]\\d"), # The "Unassigned" tracts
            !str_detect(fips, "^60\\d{3}"),    # AS
            !str_detect(fips, "^66\\d{3}"),    # MP, GU
            !str_detect(fips, "^69\\d{3}"),    # MP
            !str_detect(fips, "^72\\d{3}"),    # PR
            !str_detect(fips, "^78\\d{3}"),    # VI
            !str_detect(fips, "^72999$"),      # "Unassigned" Puerto Rico
            !str_detect(fips, "^72888$"),      # "Out of" Puerto Rico
            !str_detect(fips, "^88888$"),      # Diamond Princess
            !str_detect(fips, "^99999$"))      # Grand Princess


    rcases  <- reformat(cases, 'cases')
    rdeaths <- reformat(deaths, 'deaths')

    startingFIPS = unique(rcases$fips)
    rcases <- rcases %>% filterBannedFips
    rdeaths <- rdeaths %>% filterBannedFips
    endingFIPS = unique(rcases$fips)
    rejects <- tibble(
    fips = setdiff(startingFIPS, endingFIPS),
    code = 'EXCLUDE_LIST',
    reason = "On the list of excluded counties"
    )

    startingFIPS = unique(rcases$fips)
    rcases <- rcases %>% filterStateFips
    rdeaths <- rdeaths %>% filterStateFips
    endingFIPS = unique(rcases$fips)
    rejects <- bind_rows(rejects, tibble(
    fips = setdiff(startingFIPS, endingFIPS),
    code = 'STATE',
    reason = "Was a state or territory"
    ))

    joined <- full_join(rcases, rdeaths, by = c('fips', 'date'))

    # remove counties with less than 60 obs
    diffed <- group_by(joined, fips) %>% arrange(date) %>%
    filter(cases > 0 | deaths > 0) %>%
    mutate_at(c('cases', 'deaths'), nonzeroDiff) %>%
    ungroup %>%
    arrange(fips)

    startingFIPS <- unique(diffed$fips)

    diffed <- group_by(diffed, fips) %>% filter(n() > 60) %>% ungroup

    endingFIPS <- unique(diffed$fips)
    rejects <- bind_rows(
    rejects,
    tibble(
        fips = setdiff(startingFIPS, endingFIPS),
        code = 'UNDER60',
        reason = "Fewer than 60 days of data"
    )
    )

    diffed <- diffed[order(diffed$fips, diffed$date), ]

    diffed %<>%
    group_by(fips) %>%
    mutate(
        deathscum = cumsum(deaths),
        casescum = cumsum(cases))

    origin <- as.Date(origindate)

    fipsdmin <- diffed %>%
    group_by(fips) %>%
    summarize(firstdate = min(date)) %>%
    filter(firstdate > origin)

    chk <- diffed %>%
    group_by(fips) %>%
    mutate(tdif = date - lag(date)) %>% ungroup()

    chk2 <- chk %>% filter(tdif > 1)

    diffed <- diffed[order(diffed$fips, diffed$date), ]

    for (i in 1:nrow(chk2)) {
    entry <- chk2[i, ]
    fr <- diffed[
        diffed$fips == entry$fips & (diffed$date == entry$date - entry$tdif | diffed$date == entry$date), ]
    if (fr$deathscum[1] == fr$deathscum[2]) {
        ds <- seq.Date(from = entry$date - entry$tdif + 1, to = entry$date - 1, by = 1)
        tb <- tibble(
        date = ds,
        fips = entry$fips,
        cases = fr$cases[2],
        deaths = fr$deaths[2],
        deathscum = fr$deathscum[2],
        casescum = fr$casescum[2])

        diffed <- rbind(diffed, tb)
    }
    }

    diffed <- diffed[order(diffed$fips, diffed$date), ]

    # filter(chkii, fips == chk2$fips[6]) %>% print(n = 252)
    # filter(deaths, FIPS == "53023.0") %>% print(n = 252)

    # add 0s for pre-recording
    # this takes like 5 minutes
    for (i in 1:nrow(fipsdmin)) {
    fd <- fipsdmin$firstdate[i]
    id <- fipsdmin$fips[i]
    ds <- seq.Date(from = as.Date(origin), to = fd - 1, by = 1)
    new <- tibble(
        date = ds, fips = id, cases = 0, deaths = 0, deathscum = 0, casescum = 0)
    diffed <- rbind(diffed, new)
    }

    diffed <- diffed[order(diffed$fips, diffed$date), ]

    # chkii <- diffed %>%
    #   group_by(fips) %>%
    #   mutate(tdif = date - lag(date))


    # filter(diffed, fips == 31071) %>%
    #   mutate(tdif = date - lag(date)) %>%
    #   print(n = 382)

    # chkii2 <- chkii %>% filter(tdif > 1)

    write_csv(diffed, output_path)
    write_csv(rejects, rejects_path)

    warnings()

    return(diffed)
}