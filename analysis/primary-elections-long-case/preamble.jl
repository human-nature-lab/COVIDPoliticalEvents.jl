# preamble.jl

using Random, TSCSMethods, COVIDPoliticalEvents
import JLD2:load_object

Random.seed!(2019)

savepath = "long out/";
datapath = "data/";
scenario = "long primary "

refinementnum = 5; iters = 10000;

dat = load_object(datapath * "cvd_dat.jld2");

vn = VariableNames();

obvars = [vn.pd, vn.ts16, vn.tout];

model = casemodel(
  scenario * ARGS[1], :primary, Symbol(ARGS[1]), dat;
  F = 10:100,
  iterations = iters
);

dat = dataprep(
  dat, model;
  t_start = 0
);
