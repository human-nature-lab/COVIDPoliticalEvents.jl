# date_model.jl

include("preamble.jl");

using Dates, DataFrames, DataFramesMeta

# create strat dict based on date_exploration.jl reasoning
stratdict = Dict{Tuple{Int, Int}, Int}();
labels = Dict{Int, String}();
begin
    trtdates = sort(unique(@subset(dat, :primary .== 1).date));
    xx = unique(@subset(dat, :date .∈ Ref(trtdates))[!, [:date, vn.t]]);
    xx.stratum = [1,1,1,2,2,2,2,3,3,3,3]
    xd = Dict(xx.running .=> xx.stratum)

    for obs in model.observations; stratdict[obs] = xd[obs[1]] end

    for i in 1:3
      labels[i] = ""
      dtsi = trtdates[xx.stratum .== i]
      for (j, dts) in enumerate(dtsi)
        if j < length(dtsi)
          labels[i] = labels[i] * string(dts) * ", "
        else
          labels[i] = labels[i] * string(dts)
        end
      end
    end
end

@time match!(model, dat);

# model = primary_filter(model;  mintime = 10);

@time balance!(model, dat);

model = stratify(customstrat, model, :date, stratdict);

for (k,v) in labels; model.labels[k] = v end

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
