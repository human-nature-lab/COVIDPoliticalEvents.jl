# mask_model.jl

include("preamble.jl");

@time match!(model, dat);

@time balance!(model, dat);

using StatsBase

# @chain dat begin
#     @subset(:gaspec .== 1)
#     combine(
#         :rarenev => mean => :mn,
#         :rarenev => quantile => :qtes
#     )
# end

# create strat dict for two-level stratification
stratdict = Dict{Tuple{Int, Int}, Int}();
stratout = Dict{Tuple{Int, Int}, Float64}();
labels = Dict{Int, String}();
onevec = Float64[];
twovec = Float64[];
begin
    c = dat[!, :gaspecial] .== 1;
    
    rnvec = dat[c, vn.rare];

    # use median
    thresh = median(rnvec);

    for r in eachrow(dat[c, :])
      stratdict[(r[vn.t], r[vn.id])] = r[vn.rare] < thresh ? 1 : 2
      stratdict[(r[vn.t], r[vn.id])] = r[vn.rare] < thresh ? 1 : 2
      stratout[(r[vn.t], r[vn.id])] = r[vn.rare]
      if stratdict[(r[vn.t], r[vn.id])] == 1
        push!(onevec, r[vn.rare])
      else
        push!(twovec, r[vn.rare])
      end
    end

    mn1, mx1 = extrema(onevec);
    mn2, mx2 = extrema(twovec);

    labels[1] = string(mn1) * " to " * string(mx1)
    labels[2] = string(mn2) * " to " * string(mx2)
end

model = stratify(customstrat, model, vn.rare, stratdict);

for (k,v) in labels; model.labels[k] = v end # add labels

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

onevec = Float64[];
twovec = Float64[];
relabels = Dict{Int, String}();
for (ob, s) in zip(calmodel.observations, calmodel.strata)
    if s == 1
        push!(onevec, stratout[ob])
    else
        push!(twovec, stratout[ob])
    end
end

mn1, mx1 = extrema(onevec);
mn2, mx2 = extrema(twovec);
relabels[1] = string(mn1) * " to " * string(mx1)
relabels[2] = string(mn2) * " to " * string(mx2)

for (k,v) in relabels; calmodel.labels[k] = v end # add labels
for (k,v) in relabels; refcalmodel.labels[k] = v end # add labels

# refcalmodel.grandbalances

# @chain refcalmodel.results begin
#     groupby(:stratum)
#     combine(:att => mean => :att)
# end

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

TSCSMethods.save_object(savepath * "mask_overall_estimate.jld2", overall)