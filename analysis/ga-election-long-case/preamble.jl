# preamble.jl

using Random, TSCSMethods, COVIDPoliticalEvents, Dates
import JLD2:load_object

Random.seed!(2019)

savepath = "long out/";
datapath = "data/";
scenario = "long ga "

refinementnum = 5; iters = 10000;

dat = load_object(datapath * "cvd_dat.jld2");

vn = VariableNames();

obvars = [vn.pd, vn.ts16, vn.tout];

treatstateondate!(
  dat;
  state_abbreviation = "GA",
  eventdate = Date("2021-01-05"),
  treatment_variable = :gaspec
)

# replace the primary turnout data with the GA turnout values
begin
  ga_election = COVIDPoliticalEvents.ga_turnout(dat) #; datpath = "") # = "covid-19-data/data/");
  ed = Dict(ga_election[!, vn.id] .=> ga_election[!, vn.tout]);
  dat[!, vn.tout] .= 0.0;
  tochng = @views dat[dat.State .== "Georgia", [vn.id, vn.tout]]
  for r in eachrow(tochng)
    r[vn.tout] = ed[r[vn.id]]
  end
end

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

model = casemodel(
  scenario * ARGS[1], :gaspec, Symbol(ARGS[1]), dat;
  iterations = iters,
  F = 10:100,
  matchingcovariates = [cvs..., rare]
);

model.timevary[rare] = false

dat = dataprep(dat, model);
