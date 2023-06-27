# base_model.jl

push!(ARGS, "nomob")
push!(ARGS, "case_rte")

pth = "trump-rallies/"
include("../parameters.jl")
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
  initial_bals = Dict(balvar => 0.25),
  dooverall = true, dobayesfactor = true, dopvalue = true
);

# process_oe(overall, refcalmodel.labels)

# save_object(pth * "rally_" * string(outcome) * "_refcalmodel_" * ARGS[1] * ".jld2", refcalmodel)

# recordset = makerecords(
#   dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
# )

# TSCSMethods.save_object(savepath * string(outcome) * model.title * "overall_estimate.jld2", overall)
