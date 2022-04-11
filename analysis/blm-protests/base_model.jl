# base_model.jl

include("preamble.jl");

using DataFrames, DataFramesMeta
@subset(dat, :protest .== 1, :prsize .>= 800)

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
  initial_bals = Dict(vn.cdr => 0.25),
  dooverall = true
);

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

TSCSMethods.save_object(savepath * "overall_estimate.jld2", overall)
