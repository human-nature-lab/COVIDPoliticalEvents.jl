# combined analysis
using Random, TSCSMethods, COVIDPoliticalEvents, Dates, DataFrames
import JLD2: load_object, save_object
import CSV
import TSCSMethods: @reset

Random.seed!(2019)

push!(ARGS, "nomob")

pth = "combined_power_sim/"
include("../parameters.jl")
include("preamble.jl");

# execution

@time match!(model, dat; treatcat=protest_treatmentcategories);

# import JLD2; JLD2.save_object(savepath * scenario * string(model.outcome) * model.title * "combined_model_matched.jld2", model)

# import JLD2; JLD2.save_object("" * scenario * string(model.outcome) * model.title * "combined_model_matched.jld2", model)

# import JLD2; model = JLD2.load_object(savepath * scenario * string(model.outcome) * model.title * "combined_model_matched.jld2")

model = filter_treated(model; mintime = 10);

@time balance!(model, dat);

# recent to 2022-12-17 16:22 PM
# import JLD2; JLD2.save_object(savepath * scenario * string(model.outcome) * model.title * "combined_model_matched_balanced.jld2", model)

# import JLD2; model = JLD2.load_object(savepath * scenario * string(model.outcome) * model.title * "combined_model_matched_balanced.jld2")

stratdict = gen_stratdict(dat);

model = stratify(customstrat, model, :excluded, stratdict); # be aware of which one!

# model = remove_stratum(model; stratum = 2)

# save_object(
#     savepath * scenario * " " * string(model.outcome) * " " * model.title * "matched_balanced_post_strat.jld2",
#     model
# )

# model = load_object(savepath * scenario * " " * string(model.outcome) * " " * model.title * "matched_balanced_post_strat.jld2")

@time estimate!(model, dat);

#=
model.results[!, :event] = [evs[x] for x in model.results.stratum];

@chain model.results begin
    groupby(:event)
    combine(:att => mean => :att)
end
=#

# @subset(model.results, :stratum .== 1)

@time refinedmodel = refine(
    model, dat;
    refinementnum=refinementnum, dobalance=true, doestimate=false
);

@time estimate!(refinedmodel, dat);

@time calmodel, refcalmodel, overall = autobalance(
    model, dat;
    calmin=0.08, step=0.025,
    initial_bals = Dict(balvar => 0.25),
    dooverall=true,
);

save_object(pth * "overall_refcalmodel_" * ARGS[1] * ".jld2", refcalmodel)

# save_object("model_thresh_sim.ld2", model)

## setup

# using Statistics, StatsBase

# redproc(overall::Tuple{Dict{Int64, Tuple{Float64, Vector{Float64}}}, Dict{Int64, Float64}}) = [overall[1][1][1], overall[1][1][2][1], overall[1][1][2][3], overall[2][1]]
# redproc(coe::Tuple{Float64, Vector{Float64}}) = [coe[1][1], coe[1][2][1], coe[1][2][3], coe[2]]
# mx(calmodel) = mean.([calmodel.results.treated, calmodel.results.matches])

# function mxstrat(calmodel)
#     x = calmodel.results.treated[calmodel.results.stratum .== 1]
#     y = calmodel.results.matches[calmodel.results.stratum .== 1]
#     mean.([x, y])
# end
    

# ttl = ["ATT", "2.5%", "97.5%", "Bayes Factor", "Avg. Treated", "Avg. Matches", "Caliper"]

# df = DataFrame([x => Float64[] for x in ttl])
# df[!, "Model"] = String[]

# ## do

# for c in [0.15, 0.1, 0.05, 0.025, 0.01] # [0.5, 0.25, 

#   ibs = Dict(
#     balvar => c #, vn.fc => 0.25,
#     # vn.pbl => 0.25, vn.ts16 => 0.25
#   )

#   @time calmodel, refcalmodel, overall = autobalance(
#     model, dat;
#     calmin = 0.08, step = 0.00025,
#     initial_bals = ibs,
#     dooverall = true,
#     bayesfactor = true
#   );

#   coe = estimate!(calmodel, dat; overall = true)
#   push!(df, [redproc(coe)..., mx(calmodel)..., c, "Caliper"])
#   push!(df, [redproc(overall)..., mx(refcalmodel)..., c, "Refined caliper"])
#   # df[!, "Model"] = reduce(vcat, fill(["Caliper", "Refined caliper"], Int(nrow(df) / 2)))
# end

# save_object("thresh_sim." * ARGS[1] * "jld2", df)

# ## display

# # df = load_object("thresh_sim" * ".full" * "jld2")

# pretty_table(df, tf = tf_markdown, show_row_number = false)

# pretty_table(df, tf = tf_latex_default, show_row_number = false)

# ##

# using Parameters
# @reset refcalmodel.results = DataFrame();
# @time overall, overall_bf = estimate!(
#     refcalmodel, dat; overall = true, bayesfactor = true
# );

# @subset(refcalmodel.results, :stratum .== 1)
# overall

# # -0.257 (95% confidence interval, -3.439, 2.782) # paper results
# # (-0.395206, [-2.60643, -0.464576, 2.10169]) # pre-trend results

# recordset = makerecords(
#     dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
# )

# TSCSMethods.save_object(savepath * string(model.outcome) * model.title * "overall_estimate.jld2", (overall, overall_bf))

# save_object(
#     savepath * scenario * " " * string(model.outcome) * " " * model.title * "refcalmodel.jld2",
#     refcalmodel
# )

# # refcalmodel = load_object(
# #     savepath * scenario * " " * string(model.outcome) * " " * model.title * "refcalmodel.jld2"
# # )

# # ## COUNT
# # #=
# # used the matched and balanced (but not estimated) version of the model
# # =#

# # model = load_object(savepath * scenario * " " * string(model.outcome) * " " * model.title * "matched_balanced_post_strat.jld2")

# # @reset model.outcome = if model.outcome == :case_rte
# #     :cases
# # elseif model.outcome == :death_rte
# #     :deaths
# # elseif model.outcome == :case_rte_sma
# #     :cases_sma
# # elseif model.outcome == :death_rte_sma
# #     :deaths_sma
# # end

# # @time estimate!(model, dat);

# # @time refinedmodel = refine(
# #     model, dat;
# #     refinementnum=refinementnum, dobalance=true, doestimate=true
# # );

# # @time calmodel, refcalmodel, overall = autobalance(
# #     model, dat;
# #     calmin=0.08, step=0.05,
# #     initial_bals=Dict(vn.cdr => 0.25),
# #     dooverall=true
# # );

# # recordset = makerecords(
# #     dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
# # )

# # TSCSMethods.save_object(savepath * string(model.outcome) * model.title * "overall_estimate.jld2", overall)

# # save_object(
# #     savepath * scenario * " " * string(model.outcome) * " " * model.title * "refcalmodel.jld2",
# #     refcalmodel
# # )
