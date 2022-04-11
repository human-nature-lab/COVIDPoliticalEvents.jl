# recent_model.jl

push!(ARGS, "nomob")

include("preamble.jl");

add_recent_events!(dat, vn.t, vn.id, :protest; recency = 30)

import TSCSMethods.quantile
stratdict = Dict{Tuple{Int, Int}, Int}();
labels = Dict{Int, String}();

begin
    quantile(dat[(dat.protest .== 1), vn.prec])
    qs = quantile(
      dat[(dat.protest .== 1) .& (dat[!, vn.prec] .> 0), vn.prec],
      [0, 0.333, 0.6666, 1]
    );

    for r in eachrow(dat[dat.protest .== 1, :])
      stratdict[(r[vn.t], r[vn.id])] = if r[vn.prec] <= 1
        1
      elseif (r[vn.prec] > 1) & (r[vn.prec] <= 4)
        2
      elseif r[vn.prec] > 4
        3
      end
    end

    labels[1] = "0 to 1"
    labels[2] = "2 to 4"
    labels[3] = "4 to 27"
end

@time match!(model, dat; treatcat = protest_treatmentcategories);

@time balance!(model, dat);

model = stratify(customstrat, model, vn.prec, stratdict);
for (k,v) in labels; model.labels[k] = v end # add labels

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
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel];
  obscovars = [vn.prec]
)

nonrem = recordset.obsinfo[recordset.obsinfo.removed .== false, :];

nonrem[!, :timetreated] = [obs[1] for obs in refcalmodel.observations]
nonrem[!, :treatedunit] = [obs[2] for obs in refcalmodel.observations]
nonrem[!, :stratum] = [s for s in refcalmodel.strata];

using DataFramesMeta

@chain nonrem begin
  groupby(:stratum)
  combine(vn.prec => extrema => vn.prec)
end

# labels change?

trtfo = treatedinfo(refcalmodel, [vn.prec], dat);
trtfo[!, :stratum] = Vector{Int}(undef, nrow(trtfo));
for (i, e) in enumerate(trtfo[!, :obs])
  trtfo[i, :stratum] = stratdict[e]
end

@chain trtfo begin
  groupby(:stratum)
  combine(vn.prec => extrema => :ext)
end

# NO CHANGE TO LABELS

variablecolors = mk_covpal(VariableNames());

mpset = plot_modelset(
  model = model,
  refinedmodel = refinedmodel,
  calipermodel = calmodel,
  refinedcalipermodel = refcalmodel,
  variablecolors = variablecolors,
  base_savepath = savepath
);
