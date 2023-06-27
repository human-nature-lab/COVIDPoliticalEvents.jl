# preamble.jl

scenario = "ga ";

cvs = COVIDPoliticalEvents.covariateset(
  vn, outcome;
  modeltype = Symbol(ARGS[1])
)

mc = [cvs..., vn.rare]
# mc = setdiff(mc, [vn.fc])

# mc = [cvs[1:2]..., vn.res, vn.rare]

model = deathmodel(
  scenario * ARGS[1], :gaspecial, Symbol(ARGS[1]), dat,
  outcome;
  iterations = iters,
  F = F, L = L,
  matchingcovariates = mc
);

dat = dataprep(dat, model);
