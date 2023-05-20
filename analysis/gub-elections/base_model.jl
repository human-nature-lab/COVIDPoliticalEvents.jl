# base_model.jl

pth = "gub-elections/"
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

@time calmodel, refcalmodel, overall = autobalance(
  model, dat;
  calmin = 0.08, step = 0.0025,
  initial_bals = Dict(balvar => 0.25),
  dooverall = true, bayesfactor = true
);

save_object(pth * "gub_" * string(refcalmodel.outcome) * "_refcalmodel_" * ARGS[1] * ".jld2", refcalmodel)

# recordset = makerecords(
#   dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
# )

# TSCSMethods.save_object(savepath * string(outcome) * model.title * "overall_estimate.jld2", overall)
