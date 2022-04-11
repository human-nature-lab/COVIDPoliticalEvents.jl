# preamble.jl
# primary elections Rt

using Random, TSCSMethods, COVIDPoliticalEvents
import JLD2:load_object

Random.seed!(2019)

savepath = "Rt out/";
datapath = "data/";
scenario = "primary "

refinementnum = 5; iters = 10000;

dat = load_object(datapath * "cvd_dat.jld2");

transpth = "covidestim_estimates_2022-03-05.csv"
transdatafile = datapath * transpth

import CSV
using DataFrames, DataFramesMeta

dat = merge_Rt_data(dat, transdatafile)

vn = VariableNames();

obvars = [vn.pd, vn.ts16, vn.tout];

model = rtmodel(
  scenario * ARGS[1], :primary, Symbol(ARGS[1]), dat; iterations = iters
);

dat = dataprep(
  dat, model;
  t_start = 0, convert_missing = false
);
