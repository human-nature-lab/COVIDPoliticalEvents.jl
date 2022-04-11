# preamble.jl

using Random, TSCSMethods, COVIDPoliticalEvents
import JLD2:load_object

Random.seed!(2019)

savepath = "primary out/";
datapath = "data/";
scenario = "primary "

refinementnum = 5; iters = 10000;

dat = load_object(datapath * "cvd_dat.jld2");

vn = VariableNames();

obvars = [vn.pd, vn.ts16, vn.tout];

model = deathmodel(
  scenario * ARGS[1], :primary, Symbol(ARGS[1]), dat; iterations = iters
);

dat = dataprep(
  dat, model;
  t_start = 0
);
