# base_model.jl

push!(ARGS, "nomob")

include("preamble.jl");

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

@time calmodel, refcalmodel = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = Dict(vn.cdr => 0.25)
);

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)
