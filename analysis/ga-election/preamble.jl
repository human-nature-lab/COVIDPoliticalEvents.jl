# preamble.jl

Random.seed!(2019)

cvs = COVIDPoliticalEvents.covariateset(
  vn, outcome;
  modeltype = Symbol(ARGS[1])
)

model = deathmodel(
  scenario * ARGS[1], :gaspecial, Symbol(ARGS[1]), dat,
  outcome;
  iterations = iters,
  F = F, L = L,
  matchingcovariates = [cvs..., vn.rare]
);

dat = dataprep(dat, model);
