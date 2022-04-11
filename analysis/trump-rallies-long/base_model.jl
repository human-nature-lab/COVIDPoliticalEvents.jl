# base_model.jl

include("preamble.jl");

@time match!(model, dat; treatcat = rally_treatmentcategories);

@time balance!(model, dat);

# dat, stratassignments, labels, stratifier
model = stratify(customstrat, model, :exposure, stratassignments; labels);

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
