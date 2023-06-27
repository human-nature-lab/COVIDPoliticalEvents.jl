# base_model.jl

push!(ARGS, "full")
push!(ARGS, "case_rte")

pth = "primary-elections/"

include("../parameters.jl")
include("preamble.jl");

@time match!(model, dat);

model = primary_filter(model;  mintime = 10);

@time balance!(model, dat);

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

@time calmodel, refcalmodel, overall = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = Dict(),#balvar => 0.25),
  dooverall = true, dobayesfactor = true, dopvalue = true
);

overall

# save_object(pth * "primary_" * string(refcalmodel.outcome) * "_refcalmodel_" * ARGS[1] * ".jld2", refcalmodel)

# recordset = makerecords(
#   dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
# )

# TSCSMethods.save_object(
#   savepath * string(outcome) * model.title * "overall_estimate.jld2", overall
# )

# reconstruct estimates from modelrecord
