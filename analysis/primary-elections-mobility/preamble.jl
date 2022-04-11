# preamble.jl

using Random, TSCSMethods, COVIDPoliticalEvents
import JLD2:load_object

Random.seed!(2019)

savepath = "mobility out/";
datapath = "data/";
scenario = "mobility primary "

refinementnum = 5; iters = 10000;

dat = load_object(datapath * "cvd_dat.jld2");

vn = VariableNames();

obvars = [vn.pd, vn.ts16, vn.tout];

model = mobmodel(
  scenario * ARGS[1],
  [vn.res, vn.groc, vn.rec],
  vn.deathoutcome,
  :primary, Symbol(ARGS[1]), dat;
  iterations = iters
);

dat = dataprep(
  dat, model;
  t_start = 0
);
