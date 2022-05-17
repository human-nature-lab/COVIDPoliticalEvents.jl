# basepth = "covid-19-political-events-analysis/primary-elections/"

savepath = "protest out/";
scenario = prefix * " protest "

models = [
    "base_model.jl",
    # "recent_model.jl",
    # "size_model.jl"
]

argvals = ["full", "nomob", "nomob"]

for (x, a) in zip(models, argvals)
    ARGS[1] = a
    include(x)
    GC.gc(true)
end
