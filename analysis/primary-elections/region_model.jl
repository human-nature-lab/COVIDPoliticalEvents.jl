# region_model.jl

include("preamble.jl");

@time match!(model, dat);

model = primary_filter(model;  mintime = 10);

@time balance!(model, dat);

model = stratify(regionate, model);

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true
);

@time calmodel, refcalmodel = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = Dict(vn.cdr => 0.25)
);

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)
