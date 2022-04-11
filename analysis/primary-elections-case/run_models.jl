# basepth = "covid-19-political-events-analysis/primary-elections/"

push!(ARGS, "full")

models = [
    "base_model.jl", "turnout_model.jl"
]

for x in models
    include(x)
    GC.gc(true)
end
