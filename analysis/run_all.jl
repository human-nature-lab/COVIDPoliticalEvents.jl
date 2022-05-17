# run all models

include("general_parameters.jl")

# models
modelsets = [
    # "primary-elections/run_models.jl",
    "ga-election/run_ga.jl",
    "gub-elections/base_model.jl",
    "trump-rallies/run_trump.jl",
    "blm-protests/run_blm.jl"
];

dat = deepcopy(dat_store);

for mset in modelsets
    println(mset)
    dat = deepcopy(dat_store);
    include(mset)
end
