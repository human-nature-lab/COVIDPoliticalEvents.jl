# stratifications.jl
# Paper-specific stratification functions.

"""
US Census Region
"""
function regionate(
  model::AbstractCICModel; regiontype = :region, datpath = false
)

  if !(regiontype .∈ Ref([:region, :state, :division]))
    error("supply valid region type")
  end

  @unpack meanbalances, observations = model
  strata = Vector{Int}(undef, length(observations));

  if !datpath
    creg = CSV.read(download("https://raw.githubusercontent.com/kjhealy/fips-codes/master/county_fips_master.csv"), DataFrame)
    @subset!(creg, $regiontype .!= "NA")
  else
    creg = read(datpath, DataFrame)
    @subset!(creg, $regiontype .!= "NA")
  end

  rnme = Symbol(string(regiontype) * "_name");
  X = sort(unique(creg[!, [regiontype, rnme]]), regiontype)[!, rnme];

  dd = Dict{Int, Int}();
  sizehint!(dd, nrow(creg))
  for (i, v) in enumerate(creg[!, regiontype])
    vx = tryparse(Int, v)
    dd[creg[i, :fips]] = isnothing(vx) ? 0 : vx
  end

  for (i, ob) in enumerate(observations)
    strata[i] = get(dd, ob[2], 0)
  end
    
  return strata, Dict(1:length(X) .=> X), Symbol("Region")
end

"""
Treatment Date
"""
function datestrat!(
  model::AbstractCICModel, dat::DataFrame;
  qtes = [0, 0.25, 0.5, 0.75, 1.0],
  datestart = Date("2020-03-01")
)

  @unpack meanbalances, observations, t, treatment = model;
  strata = Vector{Int}(undef, length(observations));

  udtes = unique(dat[dat[!, treatment] .== 1, t]);
  # we want quantiles of unique
  # udtes = unique(@view dat[dat[!, treatment] .== 1, :date]);

  X = sort(Int.(round.(tscsmethods.quantile(udtes, qtes), digits = 0)));
  Xlen = length(X);

  for (i, ob) in enumerate(observations)
    strata[i] = tscsmethods.assignq(ob[1], X, Xlen)
  end

  dteq = string.(datestart + Day.(X));

  return strata, tscsmethods.label_variablestrat(dteq), Symbol("Primary Date")
end

# Population Density
# cc, labs = variablestrat!(
#   cc, dat, Symbol("Pop. Density");
#   qtes = [0, 0.25, 0.5, 0.75, 1.0]
# )

# Treatment Date - Date of First Case
function primarydistancestrat!(model, dat; qtes = [0, 0.25, 0.5, 0.75, 1.0])

  @unpack meanbalances, observations, ids, t, treatment = model;
  strata = Vector{Int}(undef, length(observations));

  # get first case dates
  
  dd = Dict{Int64, Int64}();
  sizehint!(dd, length(ids));
  # mm = maximum(dat[!, :running])
  for u in ids
    udat = @view dat[dat[!, :fips] .== u, [:fips, :running, :casescum]];
    udat = sort(udat, [:fips, :running], view = true);
    ff = findfirst(udat[!, :casescum] .> 0);
    if !isnothing(ff)
      dd[u] = ff
    else dd[u] = 0 # if there isn't a case yet assign value 0
    end
  end

  # X = sort(tscsmethods.quantile(values(dd), qtes));
  X = sort(Int.(round.(tscsmethods.quantile(values(dd), qtes), digits = 0)))
  Xlen = length(X);

  for (i, ob) in enumerate(observations)
    strata[i] = tscsmethods.assignq(dd[ob[2]], X, Xlen)
  end

  return strata, tscsmethods.label_variablestrat(string.(X)), Symbol("Date of First Case to Primary")
end

# Trump's Share of the Vote in 2016
# variablestrat!(
#   cc, dat, Symbol("Trump 2016 Vote Share");
#   qtes = [0, 0.25, 0.5, 0.75, 1.0]
# )

# # Voter Turnout
# variablestrat!(
#   cc, dat, Symbol("In-person Turnout Rate");
#   qtes = [0, 0.25, 0.5, 0.75, 1.0]
# )

# # Cumulative Case Rate
# variablestrat!(
#   cc, dat, Symbol("Cum. Case Rate");
#   qtes = [0, 0.25, 0.5, 0.75, 1.0], zerosep = false
# )

# # Cumulative Death Rate
# variablestrat!(
#   cc, dat, Symbol("Cum. Death Rate");
#   qtes = [0, 0.25, 0.5, 0.75, 1.0], zerosep = false
# )

"""
    add_recent_events!(dat, t, id, treatment; recency = 21)

Add a column, only to units that corresponds to units at treatment, representing the number of recent events, within period recency, for the treated observation. Other rows receive value 0.
"""
function add_recent_events!(dat, t, id, treatment; recency = 21)
  
  sv = Symbol("Recent Protests");
  
  dat[!, sv] .= 0;
  tobs = @views dat[dat[!, treatment] .== 1, [t, id, sv]];

  for r in eachrow(tobs)
    c1 = dat[!, id] .== r[id];
    c2 = (dat[!, t] .< r[t]) .& (dat[!, t] .>= (r[t] - recency)); # past three weeks

    r[sv] = sum(@views(dat[c1 .& c2, treatment]))
  end
  
  return dat
end
