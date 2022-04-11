# preprocess.R

source("scripts/getjhu.R")
source("scripts/final_data_organize.R")

# SPECIFY API KEY
ckey <- tidycensus::census_api_key(api_key)

preprocess(
  scale_mult = 10000,
    # put the rate scale on deaths per 1000 people
    # for visual clarity and interpretability
  origindate = "2020-03-01",
  ckey, # US CENSUS API KEY
  blsdata = "data/bls_unemployment.csv",
  delindata = "data/census_delineation.csv",
  rucdata = "data/ruralurbancodes2013.csv",
  primary_turnout_data = "data/2020_presidential_primary_turnout.csv",
  rally_data = "data/trump_rallies.csv",
  protest_data = "data/final_protest_data.csv"
);
