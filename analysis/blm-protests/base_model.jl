# base_model.jl

push!(ARGS, "nomob")
push!(ARGS, "death_rte")

pth = "blm-protests/"
include("../parameters.jl")
include("preamble.jl");

using DataFrames, DataFramesMeta
# @subset(dat, :protest .== 1, :prsize .>= 800)

@time match!(model, dat; treatcat = protest_treatmentcategories);

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
  initial_bals = Dict(balvar => 0.25),
  dooverall = true, dobayesfactor = true, dopvalue = true
);

overall

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

# save_object(pth * "blm_" * string(refcalmodel.outcome) * "_refcalmodel_" * ARGS[1] * ".jld2", refcalmodel)

# TSCSMethods.save_object(savepath * string(outcome) * model.title * "overall_estimate.jld2", overall)

# overall[1] * mean(refcalmodel.results.treated)
# (overall[2][1] * mean(refcalmodel.results.treated), overall[2][3] * mean(refcalmodel.results.treated))

# res = refcalmodel.results;

# sum(res.att .* res.treated)
# (sum(res[!, Symbol("2.5%")] .* res.treated), sum(res[!, Symbol("97.5%")] .* res.treated))
