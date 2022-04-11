# turnout_model.jl

include("preamble.jl");

# create strat dict for two-level stratification
stratdict = Dict{Tuple{Int, Int}, Int}();
labels = Dict{Int, String}();
begin
    c = dat[!, :gaspec] .== 1;
    toutbar = TSCSMethods.mean(dat[c, vn.tout]);

    for r in eachrow(dat[c, :])
      stratdict[(r[vn.t], r[vn.id])] = r[vn.tout] < toutbar ? 1 : 2
    end

    mx = string(round(maximum(dat[c, vn.tout]), digits = 2));
    labels[1] = "0.0 to " * string(round(toutbar, digits = 2))
    labels[2] = string(round(toutbar, digits = 2)) * " to " * mx
end

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

# model = stratify(
#   variablestrat, model, vn.tout, dat;
#   zerosep = false
# );

model = stratify(customstrat, model, vn.tout, stratdict);

for (k,v) in labels; model.labels[k] = v end # add labels

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

ibs = Dict(
  vn.cdr => 0.25, vn.fc => 0.25,
  vn.pbl => 0.25, vn.ts16 => 0.25,
  vn.pd => 0.25
)

@time calmodel, refcalmodel = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = ibs
);

refcalmodel.grandbalances[1]
refcalmodel.grandbalances[2]

# refcalmodel.results

# import TSCSMethods.mean

(mean(refcalmodel.results.att[refcalmodel.results.stratum .== 1]),
mean(refcalmodel.results.att[refcalmodel.results.stratum .== 2]))

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel];
  obscovars = [vn.tout]
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
