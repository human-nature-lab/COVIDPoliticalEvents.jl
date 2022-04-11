# basepth = "covid-19-political-events-analysis/primary-elections/"

push!(ARGS, "")

models = [
    "base_model.jl", "mask_model.jl",
    # "ts_model.jl", "turnout_model.jl"
]

argvals = ["full", "nomob"]#, "nomob", "nomob"]

for (x, a) in zip(models, argvals)
    ARGS[1] = a
    include(x)
    GC.gc(true)
end
