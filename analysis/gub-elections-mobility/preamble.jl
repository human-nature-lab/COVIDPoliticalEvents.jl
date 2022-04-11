# preamble.jl

using Random, TSCSMethods, COVIDPoliticalEvents, Dates
import JLD2:load_object

Random.seed!(2019)

savepath = "mobility out/";
datapath = "data/";
scenario = "mobility gub "

refinementnum = 5; iters = 10000;

dat = load_object(datapath * "cvd_dat.jld2");

vn = VariableNames();

obvars = [vn.pd, vn.ts16];

treatstateondate!(
  dat;
  state_abbreviation = ["NJ", "VA"],
  eventdate = Date("2021-11-02"),
  treatment_variable = :gub,
);

# remove other election counties on that date
# NJ Gub & Ohio House
housecounties = [39035, 39153, 39159, 39097, 39049];
c1 = dat.fips .∉ Ref(housecounties);
dat = dat[c1, :];

import HTTP, CSV
using DataFrames, DataFramesMeta
rare = Symbol("Rarely Mask");
http_response = HTTP.get("https://raw.githubusercontent.com/nytimes/covid-19-data/master/mask-use/mask-use-by-county.csv");
maskdat = CSV.File(http_response.body) |> DataFrame;
@transform!(maskdat, $rare = :NEVER + :RARELY)
maskdat[!, rare] = disallowmissing(maskdat[!, rare])

dat = leftjoin(dat, maskdat, on = vn.id => :COUNTYFP)
dat[!, rare] = disallowmissing(dat[!, rare])

cvs = COVIDPoliticalEvents.covariateset(
  vn, vn.deathoutcome;
  modeltype = Symbol(ARGS[1])
)

model = mobmodel(
  scenario * ARGS[1],
  [vn.res, vn.groc, vn.rec],
  vn.deathoutcome,
  :gub,
  Symbol(ARGS[1]),
  dat;
  iterations = iters,
  matchingcovariates = setdiff([cvs..., rare], [vn.fc])
);

dat = dataprep(dat, model);
