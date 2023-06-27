using Random, TSCSMethods, COVIDPoliticalEvents, Dates, DataFrames
using JLD2, Arrow
import CSV

Random.seed!(2019)

vn = VariableNames();

savepath = "post out/";

# savepath = "combined out/"
# scenario = "combined ";
prefix = ""

# parameters
#= practically, the only parameter that changes across models
is the outcome. for the paper, everything else stays the same
=#
covarspec = ARGS[1] # = ARGS[]
outcome = Symbol(ARGS[2]); # rates only here

balvar = if outcome == :death_rte
    vn.cdr
elseif outcome == :case_rte
    vn.ccr
end

F = 10:40;
L = -30:-1;
refinementnum = 5;
iters = 10000;

# using Arrow
# dat = Arrow.read("cvd_20230102.arrow")
# dat = Arrow.Table(dat) |> DataFrame

dat, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables = load_object("dataload.jld2")

# dat_store, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath = dataload(
#     # outcome, # removed outcome on 2023-06-03
#     "cvd_dat_use.jld2",
#     savepath
# )

# dat, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath = dataload(
#     "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/cvd_dat_use.jld2",
#     savepath
# )

# save_object("dataload.jld2", [dat, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath])
