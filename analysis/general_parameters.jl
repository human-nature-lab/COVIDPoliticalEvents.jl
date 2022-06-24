# general model parameters

using Random, TSCSMethods, COVIDPoliticalEvents, Dates, DataFrames
import JLD2:load_object
import CSV

datapath = "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/";
datafile = "cvd_dat_use.jld2";

vn = VariableNames();

outcome = :death_rte

F = 10:40; L = -30:-1
refinementnum = 5; iters = 10000;
prefix = ""

dat_store, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables = load_object(datapath * datafile);

sort(dat_store, [:fips, :date])

if prefix == "weekly"
    F = 1:6; L = -4:-1;
    dat_store = make_weekly(dat_store, pr_vars, trump_variables);
end
