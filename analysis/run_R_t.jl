# run all models

include("general_parameters.jl")

savepath = "Rt out/";
# add R_t
transpth = "covidestim_estimates_2022-03-05.csv"
transdatafile = datapath * transpth;
dat_store = merge_Rt_data(dat_store, transdatafile);

# F defined on general_parameters.jl, and is not used
# instead default 0:20 is used

# models
modelsets = [
    "primary-elections-Rt/base_model.jl",
    "ga-election-Rt/base_model.jl",
    "gub-elections-Rt/base_model.jl",
    "trump-rallies-Rt/base_model.jl",
    "blm-protests-Rt/base_model.jl"
];

dat = deepcopy(dat_store);

for mset in modelsets
    println(mset)
    dat = deepcopy(dat_store);
    include(mset)
end
