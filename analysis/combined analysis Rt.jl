# combined analysis Rt

# import Pkg; Pkg.activate(".")

using Random, TSCSMethods, COVIDPoliticalEvents, Dates, DataFrames
import JLD2:load_object,save_object
import CSV
import TSCSMethods:@reset

Random.seed!(2019)

# parameters
#= practically, the only parameter that changes across models
is the outcome. for the paper, everything else stays the same
=#
covarspec = "full" # = ARGS[]
outcome = :Rt;
scenario = "combined ";
F = 0:20; L = -30:-1
refinementnum = 5; iters = 10000;
prefix = ""

# setup
dat_store, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath = dataload(
    "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/cvd_dat_use.jld2",
    "combined out/"
)

dat = deepcopy(dat_store);

model, dat = preamble(
    outcome, F, L, dat, scenario, covarspec, iters;
    borderexclude = false, convert_missing = false
);

# execution

@time match!(model, dat; treatcat = protest_treatmentcategories);

# import JLD2; JLD2.save_object(savepath * scenario * string(model.outcome) * model.title * "combined_model_matched.jld2", model)

# import JLD2; model = JLD2.load_object(savepath * scenario * string(model.outcome) * model.title * "combined_model_matched.jld2")

model = filter_treated(model; mintime = 10);

@time balance!(model, dat);

import JLD2; JLD2.save_object(savepath * scenario * string(model.outcome) * model.title * "combined_model_matched_balanced.jld2", model)

# import JLD2; model = JLD2.load_object(savepath * scenario * string(model.outcome) * model.title * "matched_balanced.jld2")

stratdict = gen_stratdict(dat);

model = stratify(customstrat, model, :excluded, stratdict);

# model = remove_stratum(model; stratum = 2)

# save_object(
#     savepath * scenario * " " * string(model.outcome) * " " * model.title * "matched_balanced_post_strat.jld2",
#     model
# )

# model = load_object("combined out/combined  death_rte_sma combined fullmatched_balanced_post_strat.jld2")

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

vn = VariableNames();
@time calmodel, refcalmodel, overall = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = Dict(vn.cdr => 0.25),
  dooverall = true
);

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

TSCSMethods.save_object(savepath * string(model.outcome) * model.title * "overall_estimate.jld2", overall)

save_object(
    savepath * scenario * " " * string(model.outcome) * " " * model.title * "refcalmodel.jld2",
    refcalmodel
)

## COUNT
#=
used the matched and balanced (but not estimated) version of the model
=#

# model = load_object(savepath * scenario * " " * string(model.outcome) * " " * model.title * "matched_balanced_post_strat.jld2")

# @reset model.outcome = if model.outcome == :case_rte
#   :cases
# elseif model.outcome == :death_rte
#   :deaths
# elseif model.outcome == :case_rte_sma
#   :cases_sma
# elseif model.outcome == :death_rte_sma
#   :deaths_sma
# end

# @time estimate!(model, dat);

# @time refinedmodel = refine(
#   model, dat;
#   refinementnum = refinementnum, dobalance = true, doestimate = true
# );

# @time calmodel, refcalmodel, overall = autobalance(
#   model, dat;
#   calmin = 0.08, step = 0.05,
#   initial_bals = Dict(vn.cdr => 0.25),
#   dooverall = true
# );

# recordset = makerecords(
#   dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
# )

# TSCSMethods.save_object(savepath * string(model.outcome) * model.title * "overall_estimate.jld2", overall)

# save_object(
#     savepath * scenario * " " * string(model.outcome) * " " * model.title * "refcalmodel.jld2",
#     refcalmodel
# )
