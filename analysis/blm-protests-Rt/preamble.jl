# preamble.jl

Random.seed!(2019)

savepath = "Rt out/";
scenario = "protest "

obvars = [vn.pd, vn.ts16, :prsize];

model = rtmodel(
  scenario * ARGS[1], :protest, Symbol(ARGS[1]), dat; iterations = iters
);

dat = dataprep(dat, model; convert_missing = false);
