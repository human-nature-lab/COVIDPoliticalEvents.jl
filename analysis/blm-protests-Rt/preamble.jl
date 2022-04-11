# preamble.jl

using Random, TSCSMethods, COVIDPoliticalEvents, DataFrames
import JLD2:load_object

Random.seed!(2019)

savepath = "Rt out/";
datapath = "data/";
scenario = "protest "

refinementnum = 5; iters = 10000;

dat = load_object(datapath * "cvd_dat.jld2");
protest_dat = load_object(datapath * "final_protest_data.jld2")
select!(dat, Not([:protest, :prsize, :prcount]))
dat = leftjoin(dat, protest_dat, on = [:fips, :date => :pr_event_date]);

pr_vars = [:protest, :prsize, :prcount, :pr_blm, :pr_bluetrump, :pr_covid];
for v in pr_vars
  c1 = ismissing.(dat[!, v])
  x = if eltype(skipmissing(dat[!, v])) == Bool
    false
  else 0
  end
  dat[c1, v] .= x
  dat[!, v] = disallowmissing(dat[!, v])
end

sort!(dat, [:fips, :date])

transpth = "covidestim_estimates_2022-03-05.csv"
transdatafile = datapath * transpth

dat = merge_Rt_data(dat, transdatafile)

vn = VariableNames();

obvars = [vn.pd, vn.ts16, :prsize];

model = rtmodel(
  scenario * ARGS[1], :protest, Symbol(ARGS[1]), dat; iterations = iters
);

dat = dataprep(dat, model; convert_missing = false);
