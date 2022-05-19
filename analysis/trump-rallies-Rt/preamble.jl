# preamble.jl

Random.seed!(2019)

scenario = "rally "

model = rtmodel(
  scenario * ARGS[1], :rallydayunion, Symbol(ARGS[1]), dat; iterations = iters
);

dat = dataprep(dat, model; convert_missing = false);
