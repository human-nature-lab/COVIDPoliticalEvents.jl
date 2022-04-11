# organize the protest data for output to analysis
# with default treatment definition based on 9 - 40 days after event
pkgs <- c("dplyr", "magrittr", "tibble", "ggplot2")
for (pkg in pkgs) library(pkg, character.only = TRUE)


## functions
# make_protest_treatment <- function(ste_df,
#                                    cvd_df,
#                                    delay = 0,
#                                    window_open = 13,
#                                    window_close = 32) {
#   # need to handle protest day categories:
#   # if "omit", remove the observations
#   # if "cont" then 0

#   # we already have protest day

#   cvd_df$prot_window <- 0
#   cvd_df$window_stat <- character(nrow(cvd_df))

#   fips_ls <- unique(cvd_df$fips)

#   for (i in seq_along(fips_ls)) {
#     fip <- fips_ls[i]
#     prot_days <- cvd_df %>%
#       filter(
#         fips == fip,
#         # already removed control observations from prot_day:
#         prot_day == 1
#         ) %>%
#       select(running, trt_stat)
#     p <- prot_days$running
#     begin <- p + window_open
#     end <- p + window_close

#     # begin (rows), end (rows), and prot_days$running have the same length
#     dates_mat <- array(
#       data = NA,
#       dim = c(length(begin), window_close - window_open + 1))
#     for (j in seq_along(begin)) {
#       dates_mat[j, ] <- seq(from = begin[j], to = end[j], by = 1)
#     }

#     # want two vectors of same length as dates_mat
#     # that give the treatment status of each event
#     # then the date range for each value should get
#     # "omit"
#     # then overwrite with "trt" in same fashion
  
#     trt_vec <- rep(NA, length(begin))

#     omit_vals <- which(prot_days$trt_stat == "omit")
#     trt_vals <- which(prot_days$trt_stat == "trt")
#     # control are 0 anyway

#     # we need to get the days for each category
#     omit_days <- as.vector(dates_mat[omit_vals, ])
#     trt_days <- as.vector(dates_mat[trt_vals, ])
#     omit_days <- setdiff(omit_days, trt_days) # precedence to "trt"
#     # omit_days and trt_days should be partition of
#     # window_vals

#     window_vals <- unique(as.vector(dates_mat))

#     cvd_df %<>%
#       mutate(prot_window = case_when(
#         running %in% window_vals & fips == fip ~ 1,
#         TRUE ~ prot_window
#       )) %>%
#       mutate(window_stat = case_when(
#         running %in% omit_days & fips == fip ~ "omit",
#         running %in% trt_days & fips == fip ~ "trt",
#         TRUE ~ window_stat
#       ))

#     # this is leading to zero rows
#     # likely error in code
#     # rows_to_rem <- which(
#     #   cvd_df$fips == fip & cvd_df$running %in% omit_obs
#     #   )

#     # cvd_df %<>%
#     #   slice(-rows_to_rem)
#   }
#   return(cvd_df)
# }

## end functions

fips_codes <- tibble(tidycensus::fips_codes)
fips_codes$fips <- as.integer(
    fips_codes$state_code
    ) * 1000 + as.integer(
        fips_codes$county_code
        )

pdf <- readr::read_csv("data/clean_protest_data.csv")

## further manipulation, organization

# single event per county-day
# sum the event sizes that take place in a single county on a single day
pdfs <- pdf %>%
  group_by(EVENT_DATE, fips, state) %>%
  summarize(event_count = sum(event_count), size = sum(size)) %>%
  select(-state) %>%
  left_join(fips_codes, by = "fips") %>%
  ungroup()

# filter
pdfs %<>%
  filter(size > 0)

readr::write_csv(pdfs, "data/processed_protest_data.csv")