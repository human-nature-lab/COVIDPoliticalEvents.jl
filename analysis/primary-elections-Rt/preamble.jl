# preamble.jl
# primary elections Rt

Random.seed!(2019)

scenario = "primary "

obvars = [vn.pd, vn.ts16, vn.tout];

model = rtmodel(
  scenario * ARGS[1], :primary, Symbol(ARGS[1]), dat; iterations = iters
);

dat = dataprep(
  dat, model;
  t_start = 0, convert_missing = false
);
