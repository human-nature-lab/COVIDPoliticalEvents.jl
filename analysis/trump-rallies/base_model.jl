# base_model.jl

include("preamble.jl");

@time match!(model, dat; treatcat = rally_treatmentcategories);

@time balance!(model, dat);

# dat, stratassignments, labels, stratifier
model = stratify(
  customstrat, model, :exposure, trump_stratassignments; labels = trump_labels
);

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

TSCSMethods.save_object(savepath * string(outcome) * model.title * "overall_estimate.jld2", overall)
