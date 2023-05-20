# base_model.jl

using TSCSMethods, COVIDPoliticalEvents
push!(ARGS, "nomob")
using Random

scenario = "";
F = 0:20; L = -30:-1
refinementnum = 5; iters = 10000;
prefix = ""

# setup
# dat_store, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath = dataload(
#     "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/cvd_dat_use.jld2",
#     "post out/"
# )

savepath = "post out/"

import JLD2

# JLD2.save_object("dataload.jld2", [dat_store, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables])

dat, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables = JLD2.load_object("dataload.jld2")

vn = VariableNames()

include("preamble.jl");

@time match!(model, dat; treatcat = protest_treatmentcategories);

model = trim_model(model)

model = variable_filter(
  model, :prsize, dat;
  mn = 800
)

@time balance!(model, dat);

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

@time calmodel, refcalmodel, overall = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = Dict(vn.cdr => 0.25),
  dooverall = true, bayesfactor = true
);

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

JLD2.save_object(savepath * "blm_rt_overall.jld2", overall)
