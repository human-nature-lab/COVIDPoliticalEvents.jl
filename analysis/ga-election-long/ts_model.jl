# ts_model.jl

include("preamble.jl");

@time match!(model, dat);

@time balance!(model, dat);

# Trump's Share of the Vote in 2016
# 50% is what qunatile?
# import TSCSMethods.DataFramesMeta
# TSCSMethods.quantile(
#   TSCSMethods.@subset(dat, $(model.treatment) .== 1)[!, vn.ts16],
#   [0, 0.5, 1.0]
# )
# TSCSMethods.quantile(
#   TSCSMethods.@subset(dat, $(model.treatment) .== 1)[!, vn.ts16],
#   [0, 0.195, 1.0]
# )

model = stratify(
  variablestrat, model, vn.ts16, dat;
  zerosep = false, 
  qtes = [0, 0.195, 1.0] # 50% voteshare for Trump at 0.195
);

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

ibs = Dict(
  vn.cdr => 0.25, vn.fc => 0.25,
  vn.pbl => 0.25, vn.ts16 => 0.25
)

@time calmodel, refcalmodel = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = Dict(vn.cdr => 0.25)
);

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
