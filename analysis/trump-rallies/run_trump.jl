# basepth = "covid-19-political-events-analysis/primary-elections/"

savepath = "rally out/";
scenario = prefix * " rally "

models = [
    "base_model.jl",
    # "ts_model.jl",
];

argvals = ["nomob", "nomob"]

for (x, a) in zip(models, argvals)
    ARGS[1] = a
    include(x)
    GC.gc(true)
end
