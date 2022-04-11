# base_model.jl

include("preamble.jl");

@time match!(model, dat);

model = trim_model(model)

@time balance!(model, dat);

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

@time calmodel, refcalmodel = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = nothing
);

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
);
