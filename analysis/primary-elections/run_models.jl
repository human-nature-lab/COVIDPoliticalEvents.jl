# basepth = "covid-19-political-events-analysis/primary-elections/"

savepath = "primary out/";
scenario =  prefix * " primary "

models = [
    # "base_model.jl",
    # "turnout_model.jl",
    # "cumdeathrate_model.jl", "cumcaserate_model.jl",
    # "date_model.jl",
    # "firstcase_model.jl", "pop_density_model.jl",
    "region_model.jl",
    # "ts_model.jl", 
];

for x in models
    # ARGS[1] = "full"
    include(x)
    GC.gc(true)
end
