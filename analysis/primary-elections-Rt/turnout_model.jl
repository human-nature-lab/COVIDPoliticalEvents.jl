# turnout_model.jl
# N.B. there are missing values for turnout, so separate category (total of 5)

push!(ARGS, "full")

include("preamble.jl");

@time match!(model, dat);

model = primary_filter(model; mintime = 10);

@time balance!(model, dat);

model = stratify(variablestrat, model, vn.tout, dat);

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

relabel!(calmodel, refcalmodel, dat)

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

variablecolors = mk_covpal(VariableNames());

mpset = plot_modelset(
  model = model,
  refinedmodel = refinedmodel,
  calipermodel = calmodel,
  refinedcalipermodel = refcalmodel,
  variablecolors = variablecolors,
  base_savepath = savepath
);

