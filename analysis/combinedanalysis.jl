# combined analysis
using Random, TSCSMethods, COVIDPoliticalEvents, Dates, DataFrames
import JLD2: load_object, save_object
import CSV
import TSCSMethods: @reset

Random.seed!(2019)

push!(ARGS, "full")
push!(ARGS, "death_rte")

# parameters
#= practically, the only parameter that changes across models
is the outcome. for the paper, everything else stays the same
=#
covarspec = ARGS[1] # = ARGS[]
outcome = Symbol(ARGS[2]); # rates only here
scenario = "combined ";
F = 10:40;
L = -30:-1;
refinementnum = 5;
iters = 10000;
prefix = ""

# setup
dat_store, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath = dataload(
    "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/cvd_dat_use.jld2",
    "combined out/"
)

dat = deepcopy(dat_store);

model, dat = preamble(
    outcome, F, L, dat, scenario, covarspec, iters;
    borderexclude=false
);

# import JLD2; JLD2.save_object("preamble.jld2", [dat_store, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath, model, dat])

# import JLD2; 
# dat_store, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath, model, dat = JLD2.load_object("preamble.jld2")

# execution

@time match!(model, dat; treatcat=protest_treatmentcategories);

# import JLD2; JLD2.save_object(savepath * scenario * string(model.outcome) * model.title * "combined_model_matched.jld2", model)

# import JLD2; JLD2.save_object("" * scenario * string(model.outcome) * model.title * "combined_model_matched.jld2", model)

# import JLD2; model = JLD2.load_object("" * scenario * string(model.outcome) * model.title * "combined_model_matched.jld2")

# assign treatment types events

using DataFramesMeta

evs = [
    :primary,
    :gaspecial,
    :gub,
    :protest,
    :rallyday0,
    :rallyday1,
    :rallyday2,
    :rallyday3
];

dp = @subset(dat, :political .== 1);
dps = select(dp, [:fips, :running, evs...])

dps = stack(
    dps,
    evs, value_name=:held, variable_name=:event
)

@subset!(dps, :held .== 1)

# (tt, tu)
treatcats = Dict{Tuple{Int,Int},Int}()
evs = string.(evs)
for (tt, tu, ev) in zip(dps.running, dps.fips, dps.event)
    treatcats[(tt, tu)] = findfirst(ev .== evs)
end

model = filter_treated(model; mintime = 10);

@time balance!(model, dat);

# recent to 2022-12-15 10:40 AM
# import JLD2; JLD2.save_object("" * scenario * string(model.outcome) * model.title * "combined_model_matched_balanced.jld2", model)

# import JLD2; JLD2.save_object("" * scenario * string(model.outcome) * model.title * "combined_model_matched_balanced pre.jld2", model)

# import JLD2; model = JLD2.load_object("" * scenario * string(model.outcome) * model.title * "combined_model_matched_balanced pre.jld2")

let
    omap = TSCSMethods.getoutcomemap(model.outcome, dat, model.t, model.id)
    filterunits!(model, omap)
end

# stratdict = gen_stratdict(dat);

model = stratify(customstrat, model, :event, treatcats);

# model = remove_stratum(model; stratum = 2)

# save_object(
#     savepath * scenario * " " * string(model.outcome) * " " * model.title * "matched_balanced_post_strat.jld2",
#     model
# )

# model = load_object(savepath * scenario * " " * string(model.outcome) * " " * model.title * "matched_balanced_post_strat.jld2")

@time estimate!(model, dat);

model.results[!, :event] = [evs[x] for x in model.results.stratum];

@chain model.results begin
    groupby(:event)
    combine(:att => mean => :att)
end

using DataFramesMeta
@subset(model.results, :stratum .== 1)

@time refinedmodel = refine(
    model, dat;
    refinementnum=refinementnum, dobalance=true, doestimate=true
);

vn = VariableNames();
@time calmodel, refcalmodel, overall = autobalance(
    model, dat;
    calmin=0.08, step=0.05,
    initial_bals=Dict(vn.cdr => 0.25),
    dooverall=true
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

model = load_object(savepath * scenario * " " * string(model.outcome) * " " * model.title * "matched_balanced_post_strat.jld2")

@reset model.outcome = if model.outcome == :case_rte
    :cases
elseif model.outcome == :death_rte
    :deaths
elseif model.outcome == :case_rte_sma
    :cases_sma
elseif model.outcome == :death_rte_sma
    :deaths_sma
end

@time estimate!(model, dat);

@time refinedmodel = refine(
    model, dat;
    refinementnum=refinementnum, dobalance=true, doestimate=true
);

@time calmodel, refcalmodel, overall = autobalance(
    model, dat;
    calmin=0.08, step=0.05,
    initial_bals=Dict(vn.cdr => 0.25),
    dooverall=true
);

recordset = makerecords(
    dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

TSCSMethods.save_object(savepath * string(model.outcome) * model.title * "overall_estimate.jld2", overall)

save_object(
    savepath * scenario * " " * string(model.outcome) * " " * model.title * "refcalmodel.jld2",
    refcalmodel
)
