# base_model.jl

using Random
Random.seed!(2019)

pth = "ga-election/"
push!(ARGS, "epi")

include("../parameters.jl")
include("preamble.jl");

@time match!(model, dat);

@time balance!(model, dat);

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

ibs = Dict(
  balvar => 0.05,
  # vn.rare => 0.1,
  # vn.fc => 0.15
)

@time calmodel, refcalmodel, overall = autobalance(
  model, dat;
  calmin = 0.08, step = 0.025,
  initial_bals = ibs,
  dooverall = true,
  bayesfactor = true
);

using Statistics

overall
res = refcalmodel.results;
mean(res.att), mean(res[!, Symbol("2.5%")]), mean(res[!, Symbol("97.5%")])
mean(res.treated)

sum(res[!, Symbol("2.5%")] .> 0)

fg = covrob_plot(refcalmodel)
save("ga_refcal_other.svg", fg)

save_object(pth * "ga_"  * string(refcalmodel.outcome) * "_refcalmodel_" * ARGS[1] * ".jld2", refcalmodel)

# ## setup
# import TSCSMethods.mean
# redproc(coe) = [coe[1][1], coe[1][2][1], coe[1][2][3], coe[2]]
# mx(calmodel) = mean.([calmodel.results.treated, calmodel.results.matches])

# ttl = ["ATT", "2.5%", "97.5%", "Bayes Factor", "Avg. Treated", "Avg. Matches", "Caliper"]

# df = DataFrame([x => Float64[] for x in ttl])
# df[!, "Model"] = String[]

# ## do

# for c in [0.5, 0.25, 0.15, 0.1, 0.05, 0.025, 0.01]

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

# ## display
# using PrettyTables
# pretty_table(df, tf = tf_markdown, show_row_number = false)

# pretty_table(df, tf = tf_latex_default, show_row_number = false)

# save_object("df" * ARGS[1] * ".jld2")

# ##

# # oe = load_object("ga out/death_rte ga nomoboverall_estimate.jld2")
# # x.refcalmodel.results
# # refcalmodel.results

# # oe
# # overall

# # recordset = makerecords(
# #   dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
# # )

# # TSCSMethods.save_object(savepath * string(outcome) * model.title * "overall_estimate.jld2", overall)
