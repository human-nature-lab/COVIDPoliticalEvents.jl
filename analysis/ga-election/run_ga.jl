# basepth = "covid-19-political-events-analysis/primary-elections/"

savepath = "ga out/";
scenario = prefix * " ga "

models = [
    "base_model.jl",
    # "mask_model.jl",
    #"ts_model.jl", "turnout_model.jl"
];

argvals = ["nomob", "nomob", "nomob", "nomob"]
# argvals = fill("epi", 4)
# argvals = ["full", "nomob"]
# argvals = ["nomob", "nomob"]
# argvals = ["epi", "epi"]

for (x, a) in zip(models, argvals)
    ARGS[1] = a
    include(x)
    GC.gc(true)
end
