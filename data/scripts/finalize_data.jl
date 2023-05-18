# finalize the data

using Random, TSCSMethods, COVIDPoliticalEvents, Dates
import JLD2:load_object, save_object

datapath = "data/";

vn = VariableNames();

# do this one and just load
dat = load_object(datapath * "cvd_dat.jld2");
dat = finish_data(dat, datapath);
dat, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables = indicatetreatments(dat);

TSCSMethods.rename!(dat, :deathscum => vn.cd, :casescum => vn.cc)

save_object(
    datapath * "cvd_dat_use.jld2",
    [
        dat, trump_stratassignments, trump_labels, trump_stratifier,
        pr_vars, trump_variables
    ]
);
