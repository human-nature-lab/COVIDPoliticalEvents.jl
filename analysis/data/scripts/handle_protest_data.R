# handle_protest_data.R
# raw data source:
# https://acleddata.com/special-projects/us-crisis-monitor/

clean_protest_data <- function(
    rawpth = "data/USA_2020_Oct10update.csv",
    spth = "data/clean_protest_data.csv"
) {

    # read in most recent update
    # Oct 10 is most recent date
    adf <- readr::read_csv(rawpth)

    # format date variable
    adf$EVENT_DATE <- as.Date(adf$EVENT_DATE, format = "%d-%B-%Y")

    # create dataset of full county fips codes and names to merge 
    # into theprotest data on the basis of county names
    fips_codes <- tibble(tidycensus::fips_codes)
    fips_codes$fips <- as.integer(
        fips_codes$state_code
        ) * 1000 + as.integer(
            fips_codes$county_code
            )

    # Format protest data to merge with fips dataset

    # deal with Garfield County, CO mixup
    loc <- (adf$ADMIN2 == "Carbondale" & adf$LOCATION == "Garfield")
    adf$LOCATION[loc] <- "Carbondale"
    adf$ADMIN2[loc] <- "Garfield"

    # deal with typo in Bergen County, NJ
    adf$ADMIN2[adf$ADMIN2 == "Begen" & adf$ADMIN1 == "New Jersey"] <- "Bergen"

    # append "County" to ADMIN2 for merging with fips_codes
    adf$County <- paste0(adf$ADMIN2, " County")

    # replace County City with City
    prob <- adf$ADMIN2[grepl("City", adf$ADMIN2)]
    adf$County[grepl("City", adf$ADMIN2)] <- paste0(substr(prob, 1, nchar(prob) - 4), "city")

    # replace County with parish in LA
    # need to do Bossier Parish by hand
    adf$County[adf$ADMIN1 == "Louisiana"] <- paste0(adf$ADMIN2[adf$ADMIN1 == "Louisiana"], " Parish")
    adf$County[adf$ADMIN2 == "Bossier Parish"] <- "Bossier Parish"

    # replace Saint with st
    prob <- adf$County[grepl("Saint ", adf$County)]
    adf$County[grepl("Saint ", adf$County)] <- paste0("St.", substr(prob, 6, nchar(prob)))

    # remove "County" from Washington DC
    adf$County[adf$ADMIN1 == "District of Columbia"] <- "District of Columbia"

    # deal with each Alaska county
    adf$County[adf$ADMIN1 == "Alaska"] <- adf$ADMIN2[adf$ADMIN1 == "Alaska"]
    adf$County[adf$County == "Anchorage"] <- "Anchorage Municipality"
    adf$County[adf$County == "Bethel"] <- "Bethel Census Area"
    adf$County[adf$County == "Dillingham"] <- "Dillingham Census Area"
    adf$County[adf$County == "Fairbanks North Star"] <- "Fairbanks North Star Borough"
    adf$County[adf$County == "Haines"] <- "Haines Borough"
    adf$County[adf$County == "Juneau"] <- "Juneau City and Borough"
    adf$County[adf$County == "Kenai Peninsula"] <- "Kenai Peninsula Borough"
    adf$County[adf$County == "Ketchikan Gateway"] <- "Ketchikan Gateway Borough"
    adf$County[adf$County == "Kodiak Island"] <- "Kodiak Island Borough"
    adf$County[adf$County == "Matanuska-Susitna"] <- "Matanuska-Susitna Borough"
    adf$County[adf$County == "Nome"] <- "Nome Census Area"
    adf$County[adf$County == "North Slope"] <- "North Slope Borough"
    adf$County[adf$County == "Northwest Arctic"] <- "Northwest Arctic Borough"
    adf$County[adf$County == "Petersburg"] <- "Petersburg Census Area"
    adf$County[adf$County == "Sitka"] <- "Sitka City and Borough"
    adf$County[adf$County == "Skagway"] <- "Skagway Municipality"
    adf$County[adf$County == "Valdez-Cordova"] <- "Valdez-Cordova Census Area"

    # take care of the various lakes, based on google search of
    # the location in question
    adf$County[adf$ADMIN1 == "Alabama" & adf$LOCATION == "Lake Martin"] <- "Tallapoosa County"
    adf$County[adf$ADMIN1 == "Mississippi" & adf$LOCATION == "Ross R Barnett Reservoir"] <- "Madison County"
    adf$County[adf$ADMIN1 == "Texas" & adf$LOCATION == "Lake Palestine"] <- "Henderson County"

    # deal with Sainte Genevieve County, MO
    adf$County[adf$ADMIN2 == "Sainte Genevieve"] <- "Ste. Genevieve County"

    # take care of case differences
    adf$County <- tolower(adf$County)
    fips_codes$county <- tolower(fips_codes$county)

    # merge in the fips data to fill in protest data fips codes
    adf <- adf %>%
    left_join(
        fips_codes,
        by = c("County" = "county", "ADMIN1" = "state_name")
        )

    # add replace "county" with "city" if fips still NA
    adf$County[is.na(adf$fips)] <- tolower(paste0(adf$ADMIN2[is.na(adf$fips)], " city"))

    # delete columns and re-merge to get all fips codes
    adf %<>% select(-fips, -state, -state_code, -county_code)
    adf <- adf %>%
    left_join(
        fips_codes,
        by = c("County" = "county", "ADMIN1" = "state_name")
    )

    # With these edits this test code shows 0 NA values remaining
    # sum(is.na(adf$fips))
    # unique(adf$ADMIN1[is.na(adf$fips)])

    # Manually fixed:
    # all of Alaska
    # Lake Martin, AL; Ross R Barnnet Reservoir, MI; Lake Palestine, TX
    # Garfield County, CO which is mistakenly labeled "Carbondale" in ADMIN2
    # Bossier Parish, Louisiana
    # Sainte Genevieve County, MI
    # Bergen County, NJ which is mistakenly labeled "Begen" in ADMIN2
    # Many cities in Virginia which do not have "city" in ADMIN2

    # need to summarize to day and fips:
    # - one "event" per day per fips
    # - more detailed analysis will need to
    #   combine the size estimates
    # - remove "Strategic developments"
    # - consider removing other categories

    adf <- adf %>%
        filter(EVENT_TYPE != "Strategic developments")
    adf$event_count <- 1

    # extract text describing protest size which is in brackets
    size_txt <- stringr::str_extract(
    string = adf$NOTES,
    pattern = "(?<=\\[).*(?=\\])")
    # this will not capture the variations in spacing (e.g. "size = ")
    # which ARE present for a few entries
    adf$size_txt <- stringr::str_remove(size_txt, pattern = "size=")
    # there are 1389 unique character entries here

    # remove white space for consistency
    adf$size_txt <- trimws(adf$size_txt)

    # fix double bracket entries #
    # some NOTES values have [size=xyz][]
    # need to properly extract this to size_text

    db_ind <- which(stringr::str_detect(adf$size_txt, "\\]\\[") == TRUE)

    d_bracket <- adf$NOTES[db_ind] %>%
    stringr::str_extract(., "(?<=\\[).*(?=\\])") %>%
    stringr::str_split(., "\\]\\[")

    d_bracket2 <- rep(NA, length(d_bracket))
    for (i in seq_along(d_bracket)) d_bracket2[i] <- d_bracket[[i]][1]

    d_bracket2 <- trimws(stringr::str_remove(d_bracket2, "size="))

    adf$size_txt[db_ind] <- d_bracket2

    db_ind_space <- which(stringr::str_detect(adf$size_txt, "\\] \\[") == TRUE)

    d_bracket <- adf$NOTES[db_ind_space] %>%
    stringr::str_extract(., "(?<=\\[).*(?=\\])") %>%
    stringr::str_split(., "\\] \\[")

    d_bracket2 <- rep(NA, length(d_bracket))
    for (i in seq_along(d_bracket)) d_bracket2[i] <- d_bracket[[i]][1]

    d_bracket2 <- trimws(stringr::str_remove(d_bracket2, "size="))

    adf$size_txt[db_ind_space] <- d_bracket2

    # end fix double bracket entries #

    # a few entries are missing an end bracket and get NA as a result
    na_ind <- which(is.na(adf$size_txt))

    s_bracket <- adf$NOTES[na_ind] %>%
    stringr::str_extract(., "(\\[?=).*")
    s_bracket <- substr(s_bracket, 2, nchar(s_bracket))

    adf$size_txt[na_ind] <- s_bracket

    # remove not reported sizes
    # - filter out 39 NA sizes
    # - filter out 6K "no report" values
    adf %<>%
    tidyr::drop_na(size_txt) %>%
    filter(
        size_txt != "no report",
        size_txt != "unreported")

    # remove vehicles only events
    adf <- adf[!stringr::str_detect(adf$size_txt, "vehicles"), ]
    adf <- adf[!stringr::str_detect(adf$size_txt, "cars"), ]

    # remove small groups
    sm_ind <- !stringr::str_detect(adf$size_txt, "small group")
    adf <- adf[sm_ind, ]

    # add edited text column
    adf$size_txt_edited <- adf$size_txt

    # create function to remove a given phrase from all size descriptions
    # draws on and returns text to size_txt_edited column
    remove_phrase <- function(adf, phrase) {
    atl_ind <- which(stringr::str_detect(adf$size_txt_edited, phrase))
    rexp <- paste0("(", phrase, ")( )*")
    
    atl_vals <- stringr::str_remove(adf$size_txt_edited[atl_ind], rexp)
    adf$size_txt_edited[atl_ind] <- atl_vals
    return(adf)
    }

    # add "at least x" values to size
    # when "at least x", s.t. x is integer
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "at least")])
    adf <- remove_phrase(adf, "at least")

    # add "up to x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "up to")])
    adf <- remove_phrase(adf, "up to")

    # add "roughly x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "roughly")])
    adf <- remove_phrase(adf, "roughly")

    # add "nearly x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "nearly")])
    adf <- remove_phrase(adf, "nearly")

    # add "over x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "over")])
    adf <- remove_phrase(adf, "over")

    # add "more than x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "more than")])
    adf <- remove_phrase(adf, "more than")

    # add "about x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "about")])
    adf <- remove_phrase(adf, "about")

    # add "around x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "around")])
    adf <- remove_phrase(adf, "around")

    # add "approximately x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "approximately")])
    adf <- remove_phrase(adf, "approximately")

    # add "an estimated x" and "estimated x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "(an )?(estimated)")])
    adf <- remove_phrase(adf, "(an )?(estimated)")

    # add "an estimate of x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "an estimate of")])
    adf <- remove_phrase(adf, "an estimate of")

    # add "almost x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "almost")])
    adf <- remove_phrase(adf, "almost")

    # add "some x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "some")])
    adf <- remove_phrase(adf, "some ")

    # add "close to x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "close to")])
    adf <- remove_phrase(adf, "close to")

    # add "a crowd of x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "a crowd of")])
    adf <- remove_phrase(adf, "a crowd of")

    # add "less than x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "less than")])
    adf <- remove_phrase(adf, "less than")

    # add "near x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "near")])
    adf <- remove_phrase(adf, "near ")

    # add "under x" and "just under x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "(just )?(under)")])
    adf <- remove_phrase(adf, "(just )?(under)")

    # add "as many as x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "as many as")])
    adf <- remove_phrase(adf, "as many as")

    # add "a group of x"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "a group of")])
    adf <- remove_phrase(adf, "a group of")

    # remove " people" from "x people" for integer processsing
    # also remove " of people" and " people or so"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "( of)?( people).*")])
    adf <- remove_phrase(adf, "( of)?( people).*")

    # remove " or so" from "x or so"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, " or so")])
    adf <- remove_phrase(adf, " or so")

    # remove " or more" from "x or more"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "or more")])
    adf <- remove_phrase(adf, " or more")

    # remove " protesters" from "x protesters"
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "protesters")])
    adf <- remove_phrase(adf, " protesters")

    ## create int
    # best guesses for protest size as integer
    adf$size <- as.integer(adf$size_txt_edited)

    ## simple cases
    def <- c("a dozen", "dozen", "1 dozen", "one dozen", "a little a dozen")
    adf$size[adf$size_txt_edited %in% def] <- 12
    def <- c("two dozen", "2 dozen", "a couple dozen", "a couple of dozen", "a couple of dozens", "couple dozen",
            "two dozens", "two-dozen", "just two dozen", "two dozen)", "a few dozen", "few dozen")
    adf$size[adf$size_txt_edited %in% def] <- 24
    def <- c("3 dozen", "three dozen", "three dozens")
    adf$size[adf$size_txt_edited %in% def] <- 36
    adf$size[adf$size_txt_edited == "four dozen"] <- 48
    adf$size[adf$size_txt_edited == "five dozen"] <- 60

    def <- c("a hundred", "a 100", "hundred", "one hundred", "a little 100")
    adf$size[adf$size_txt_edited %in% def] <- 100
    def <- c("a couple hundred", "a couple of hundreds", "a couple of hundred",
            "couple hundred", "couple of hundreds", "couple of hundred",
            "a few hundred", "a few hundreds", "few hundred", "two hundred",
            "a couple of 100")
    adf$size[adf$size_txt_edited %in% def] <- 200
    adf$size[adf$size_txt_edited == "About 300"] <- 300

    adf$size[adf$size_txt_edited == "a thousand" | adf$size_txt_edited == "thousand"] <- 1000
    adf$size[adf$size_txt_edited == "two thousand" | adf$size_txt_edited == "few thousands"] <- 2000
    adf$size[adf$size_txt_edited == "3000]"] <- 3000
    adf$size[adf$size_txt_edited == "sixty thousand"] <- 60000


    # take arithmetic mean when the estimate is between two numbers
    unique(adf$size_txt_edited[stringr::str_detect(adf$size_txt_edited, "(\\d)+(\\D)+(\\d)+")])

    ind <- which(stringr::str_detect(adf$size_txt_edited, "(\\d)+(\\D)+(\\d)+"))
    num1 <- stringr::str_extract(adf$size_txt_edited[ind], "(\\d)+(?=((\\D)+(\\d)+))")
    num2  <- stringr::str_extract(adf$size_txt_edited[ind], "(\\d)+(?!.)")

    adf$size[ind] <- as.integer((as.integer(num1)+as.integer(num2))/2)

    adf$size[adf$size_txt_edited == "5-8 thousand"] <- 6500 # arithmetic mean
    adf$size[adf$size_txt_edited == "between hundreds and thousands"] <- 1650 # 300-3000 arithmetic mean
    adf$size[(adf$size_txt_edited == "between several hundred and a thousand" | 
                adf$size_txt_edited == "several hundreds to thousands")] <- 1700 # 400-3000 arithmetic mean
    adf$size[adf$size_txt_edited == "hundreds-1500"] <- 900 # 300-1500 arithmetic mean


    # when plural given, resolve to integer using geometric mean
    # between two established bounds
    adf$size[adf$size_txt_edited == "dozens"] <- 30 # 12-100
    adf$size[adf$size_txt_edited == "hundreds"] <- 300 # 100-1000
    adf$size[adf$size_txt_edited == "thousands"] <- 3000 # 1000-10000
    adf$size[adf$size_txt_edited == "tens of thousands"] <- 30000 # 10000-100000

    adf$size[adf$size_txt_edited == "several dozens" | adf$size_txt_edited == "several dozen"] <- 50 # 24-100
    adf$size[adf$size_txt_edited == "several hundred" | adf$size_txt_edited == "several hundreds"] <- 400 # 200-1000
    adf$size[adf$size_txt_edited == "several thousand" | adf$size_txt_edited == "several thousands"] <- 4000 # 2000-20000

    # put common small values to 0
    adf$size[adf$size_txt_edited == "few" | adf$size_txt_edited == "a few"] <- 0
    adf$size[adf$size_txt_edited == "handful" | adf$size_txt_edited == "a handful"] <- 0
    adf$size[adf$size_txt_edited == "small"] <- 0
    adf$size[adf$size_txt_edited == "several" | adf$size_txt_edited == "severall"] <- 0
    half_dozen <- c("a half-dozen", "half-dozen", "half a dozen", "half dozen")
    adf$size[adf$size_txt_edited %in% half_dozen] <- 0

    # 280 problem values remain
    # Most of these are too vague and we've decided the few useful
    # tibits are not worth digging out
    probs <- adf[is.na(adf$size),]

    # now, all but 280 are numbered
    sum(is.na(adf$size))

    data.table::data.table(tibble(unique(adf$size_txt)))

    ### end cleaning, filtering ###

    ## save clean copy of the protest data
    readr::write_csv(adf, file = spth)
    return(adf)
}

organize_protest_data <- function(
    rawpth = "data/USA_2020_Oct10update.csv",
    spthclean = "data/clean_protest_data.csv",
    spthprocessed = "data/processed_protest_data.csv",
    countyagg = TRUE
) {

    fips_codes <- tibble(tidycensus::fips_codes)
    fips_codes$fips <- as.integer(
        fips_codes$state_code
        ) * 1000 + as.integer(
            fips_codes$county_code
            )

    pdf <- clean_protest_data(
        rawpth = rawpth,
        spth = spthclean
    )
    # or, load from file:
    # pdf <- readr::read_csv("data/clean_protest_data.csv")

    ## further manipulation, organization

    # single event per county-day
    # sum the event sizes that take place in a single county on a single day
    if (countyagg == TRUE) {
        pdfs <- pdf %>%
            group_by(EVENT_DATE, fips, state) %>%
            summarize(event_count = sum(event_count), size = sum(size)) %>%
            select(-state) %>%
            left_join(fips_codes, by = "fips") %>%
            ungroup()
    } else {
        pdfs <- pdf %>%
        select(-state) %>%
        left_join(fips_codes, by = "fips") %>%
        ungroup()
    }

    # filter
    pdfs <- pdfs %>% filter(size > 0)

    readr::write_csv(pdfs, spthprocessed)

    return(pdfs)
}
