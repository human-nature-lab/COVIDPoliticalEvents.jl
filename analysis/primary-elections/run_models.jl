# basepth = "covid-19-political-events-analysis/primary-elections/"

ARGS[1] = "full"

savepath = "primary out/";
scenario =  prefix * " primary "

models = [
    "base_model.jl",
    "turnout_model.jl",
    # "cumdeathrate_model.jl", "cumcaserate_model.jl",
    # "date_model.jl",
    # "firstcase_model.jl", "pop_density_model.jl",
    # "region_model.jl", "ts_model.jl", 
];

for x in models
    include(x)
    GC.gc(true)
end
