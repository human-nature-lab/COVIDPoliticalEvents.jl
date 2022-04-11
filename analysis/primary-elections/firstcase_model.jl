# firstcase_model.jl

include("preamble.jl");

@time match!(model, dat);

model = primary_filter(model;  mintime = 10);

using DataFrames, DataFramesMeta

firstcases = @chain dat begin
  @subset(:cases .> 0)
  groupby(:fips)
  combine(:running => minimum => :firstcase)
end

dat = leftjoin(dat, firstcases, on = vn.id);

strating = (@chain dat begin
  @subset(:primary .== 1)
  @combine(:qte = TSCSMethods.quantile(collect(skipmissing(:firstcase))))
end).qte

# dat[!, :stratum] = 

stratdict = Dict{Tuple{Int, Int}, Int}();
stratout = Dict{Tuple{Int, Int}, Float64}();
labels = Dict{Int, String}();

@eachrow! dat begin
  @newcol :stratum::Vector{Int}
  :stratum = if !ismissing(:firstcase)
    if (:firstcase <= strating[2])
      1
    elseif (:firstcase <= strating[3]) & (:firstcase > strating[2])
      2
    elseif (:firstcase <= strating[4]) & (:firstcase > strating[3])
      3
    elseif (:firstcase > strating[4])
      4
    end
  else
    5
  end
end

stratdict = Dict{Tuple{Int, Int}, Int}()
for r in eachrow(@subset(dat, :primary .== 1))
  stratdict[(r[vn.t], r[vn.id])] = r[:stratum]
end

stratout = Dict(dat[!, vn.id] .=> dat[!, :firstcase]);

labels = Dict{Int, String}();
for s in sort(unique(dat.stratum))
  if s < 5
    c1 = (dat.stratum .== s) .& (dat.primary .== 1)
    mn, mx = extrema(skipmissing(dat[c1, :firstcase]));
    labels[s] = string(mn) * " to " * string(mx)
  else
    labels[s] = "No Cases"
  end
end

fives = Any[]
[if v == 5; push!(fives, k) end for (k, v) in stratdict];

tests = Bool[]
for ob in model.observations
  if all([fv != ob for fv in fives])
    push!(tests, true)
  else push!(tests, false)
  end
end

using Accessors
@reset model.observations = model.observations[tests];
@reset model.matches = model.matches[tests];
@reset model.treatednum = length(model.observations)

@time balance!(model, dat);

model = stratify(customstrat, model, :firstcase, stratdict);

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

relabels = Dict{Int, String}();
for s in sort(unique(refcalmodel.strata))
  if s < 5
    sobs = refcalmodel.observations[refcalmodel.strata .== s]
    mn, mx = extrema([stratout[sob[2]] for sob in sobs])
    relabels[s] = string(mn) * " to " * string(mx)
  else relabels[s] = "No Cases"
  end
end

for (k,v) in labels; model.labels[k] = v end # add labels
for (k,v) in relabels; calmodel.labels[k] = v end # add labels
for (k,v) in relabels; refcalmodel.labels[k] = v end # add labels

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

# @chain refcalmodel.results begin
#   groupby(:stratum)
#   combine(
#     :att => TSCSMethods.mean => :att,
#     :treated => TSCSMethods.mean => :treated,
#     :matches => TSCSMethods.mean => :matches
#   )
# end