# base_model.jl

push!(ARGS, "full")
# ARGS[1] = "nomob"

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
  initial_bals = Dict(vn.cdr => 0.25),
  dooverall = true
);

refcalmodel.results

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

TSCSMethods.save_object(savepath * "case_overall_estimate.jld2", overall)
