# preamble.jl

Random.seed!(2019)

obvars = [vn.pd, vn.ts16, :prsize];

model = deathmodel(
  scenario * ARGS[1], :protest, Symbol(ARGS[1]), dat,
  outcome;
  F = F, L = L,
  iterations = iters,
);

dat = dataprep(dat, model);
