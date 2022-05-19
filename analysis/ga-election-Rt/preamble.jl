# preamble.jl

Random.seed!(2019)

scenario = "ga "

obvars = [vn.pd, vn.ts16, vn.tout];
cvs = COVIDPoliticalEvents.covariateset(
  vn, vn.rt;
  modeltype = Symbol(ARGS[1])
)

model = rtmodel(
  scenario * ARGS[1], :gaspecial, Symbol(ARGS[1]), dat;
  iterations = iters,
  matchingcovariates = [cvs..., vn.rare]
);

dat = dataprep(dat, model, convert_missing = false);
