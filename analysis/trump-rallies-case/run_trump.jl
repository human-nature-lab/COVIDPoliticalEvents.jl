# basepth = "covid-19-political-events-analysis/primary-elections/"

push!(ARGS, "")

models = [
    "base_model.jl"
]

argvals = ["nomob"]

for (x, a) in zip(models, argvals)
    ARGS[1] = a
    include(x)
    GC.gc(true)
end
