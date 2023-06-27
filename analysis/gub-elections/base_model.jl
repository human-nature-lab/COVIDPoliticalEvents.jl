# base_model.jl

pth = "gub-elections/"

push!(ARGS, "nomob")
push!(ARGS, "case_rte")

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
    calmin = 0.08, step = 0.05,
    initial_bals = Dict(), # balvar => 0.25
    dooverall = true, dobayesfactor = true, dopvalue = true
);

overall
  
# @reset refcalmodel.results = DataFrame()
# Random.seed!(2019)

# oe = estimate!(
#     refcalmodel, dat; overallestimate = true, dobayesfactor = true, dopvalue = true
# )

# overall

# save_object(pth * "gub_" * string(refcalmodel.outcome) * "_refcalmodel_" * ARGS[1] * ".jld2", refcalmodel)

recordset = makerecords(
    dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

# TSCSMethods.save_object(savepath * string(outcome) * model.title * "overall_estimate.jld2", overall)

mean(model.results.att)
mean(ld.model.results.att)

mean(refinedmodel.results.att)
mean(ld.refinedmodel.results.att)

mean(calmodel.results.att)
mean(ld.calmodel.results.att)

mean(refcalmodel.results.att)
mean(ld.refcalmodel.results.att)

