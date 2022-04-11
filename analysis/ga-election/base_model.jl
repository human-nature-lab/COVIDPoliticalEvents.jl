# base_model.jl

include("preamble.jl");

@time match!(model, dat);

@time balance!(model, dat);

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

ibs = Dict(
  vn.cdr => 0.25 #, vn.fc => 0.25,
  # vn.pbl => 0.25, vn.ts16 => 0.25
)

@time calmodel, refcalmodel, overall = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = ibs,
  dooverall = true
);

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

TSCSMethods.save_object(savepath * "overall_estimate.jld2", overall)
