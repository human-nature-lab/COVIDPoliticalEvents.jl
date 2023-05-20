# preamble.jl

Random.seed!(2019)

scenario = "trump "

obvars = [vn.pd, vn.ts16, :Exposure];

model = deathmodel(
  scenario * ARGS[1], :rallydayunion, Symbol(ARGS[1]), dat,
  outcome;
  F = F, L = L,
  iterations = iters,
);

dat = dataprep(dat, model);
