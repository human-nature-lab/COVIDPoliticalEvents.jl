# preamble.jl

Random.seed!(2019)

scenario = "primary "

obvars = [vn.pd, vn.ts16, vn.tout];

model = deathmodel(
  scenario * ARGS[1], :primary, Symbol(ARGS[1]), dat,
  outcome;
  F = F, L = L,
  iterations = iters,
);

dat = dataprep(
  dat, model;
  t_start = 0
);
