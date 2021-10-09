# spillover.jl

# helpers

function mkDataFrame(cts)
  df = DataFrame()
  for (k, v) in cts
    df[!, k] = v
  end
  return df
end

# end helpers

"""
    getneighbordat()

Get the county adjacecy info from the US Census Bureau website.

"https://www2.census.gov/geo/docs/reference/county_adjacency.txt"
"""
function getneighbordat()

  C = CSV.read(
    download("https://www2.census.gov/geo/docs/reference/county_adjacency.txt"),
    DataFrame;
    header = false
  )

  brks = findall((ismissing.(C.Column2) .- 1) * .- 1 .== 1)
  # last is nrow(C)

  cc = zeros(Int64, nrow(C), 2);
  cnt = 0
  for i = eachindex(brks)
    i1 = brks[i]
    cnt += 1
    if i < length(brks)
      i2 = brks[i + 1] - 1
    else
      i2 = nrow(C)
    end
    cc[(i1 : i2), 1] = fill(C.Column2[i1], i2 - i1 + 1)
    cc[(i1 : i2), 2] = C.Column4[i1 : i2]
  end

  ccd = sort!(DataFrame(from = cc[:,1], to = cc[:,2]), :from);

  ul = unique(ccd.from);
  UL = zeros(Int64, length(ul), 2);
  UL[:,1] = ul;
  UL[:,2] = 1:length(ul);

  ky = DataFrame(id = UL[:,1], numfrom = UL[:,2]);
  ky2 = DataFrame(id = UL[:,1], numto = UL[:,2]);

  ccd = leftjoin(ccd, ky, on = [:from => :id]);
  ccd = leftjoin(ccd, ky2, on = [:to => :id]);

  # C is the county adj matrix, in increasing-fips order
  C = zeros(Int64, length(ul), length(ul));

  id2ind = Dict(UL[:, 1] .=> UL[:, 2])
  ind2id = Dict(UL[:, 2] .=> UL[:, 1])


  # for each unique treated observation, look across its unit's row and mark the others as treated
  for i = eachindex(1:nrow(ccd))
    # C[ccd.numfrom[i], ccd.numto[i]] = 1;
    C[id2ind[ccd.from[i]], id2ind[ccd.to[i]]] = 1;
  end
  return C, id2ind, ind2id
end

"""
return the set of neighbors up to degree
"""
function getneighbors(
  treatment, t, id,
  id2ind, ind2id, C,
  dat, degree::Int
)

  CoDict = Dict{Int64, Matrix{Int64}};
  codict = CoDict();
  pathsmat!(codict, C, degree);

  # unique treatments
  trtobs = unique(dat[dat[!, treatment] .== 1, [t, id]]);

  adjf = mkDataFrame(
    Dict(
      :degree => Int64[],
      :egoid => Int64[],
      :egot => Int64[],
      :aid => Int64[],
      :aitreated => Bool[]
    )
  );

  tot = trtobs[!, t];
  toid = trtobs[!, id];

  # include self-loops to treated units as degree 0
  for i in 1:length(trtobs[!, id])
    append!(
      adjf,
      DataFrame(
        degree = 0,
        egoid = trtobs[!, id][i],
        egot = trtobs[!, t][i],
        aid = trtobs[!, id][i],
        aitreated = true
      )
    )
  end
  
  getneighbors_inner!(
    adjf,
    trtobs,
    codict, degree,
    tot, toid,
    id2ind, ind2id
  )
  return adjf
end

function pathsmat!(codict, C, degree)
  for k in 1:degree
    codict[k] = (C^k .> 0) .* 1 # is there a path of length degree
  end
  return codict
end

"""
construct a vector for i in 1:degree that contains the set of untreated neighbors of treated units in the data, for each neighor degree in 1:degree.
"""
function getneighbors_inner!(
  adjf,
  trtobs,
  codict, degree,
  tot, toid,
  id2ind, ind2id
)
  
  for i = eachindex(1:nrow(trtobs))
    egot = @views(tot[i])
    egoid = @views(toid[i])
    
    eind = id2ind[egoid]
    for j in 1:size(codict[1])[1] # over alters to ego
      
      # loop over degree values
      # stop when append happens
      for o in 1:degree
        aijk = @views(codict[o][j, eind]) # i, j of matrix k
        g0 = aijk > 0
        aid = ind2id[j]
        taid = aid .∈ Ref(toid) # alter treated?
        if g0 & (egoid != aid)
          append!(
            adjf,
            DataFrame(
              degree = o,
              egoid = egoid,
              egot = egot,
              aid = aid,
              aitreated = taid
            )
          )
          break # finds first (:. minimum) path from ego to alter, and skips longer paths
        end
      end
    end
  end
  return adjf
end


function treatneighbors!(
  dat, adjf, degree, treatment;
  id = :fips, t = :running
)

  union_treatment = Symbol(string(treatment) * "union");
  dat[!, union_treatment] .= 0;
  
  for k in 0:degree
    adjtr = @view(adjf[adjf.degree .== k, :]);
    
    # new dat column for degree
    new_treatment = Symbol(string(treatment) * string(k));
    dat[!, new_treatment] .= 0;
    treatneighbors_inner!(
      dat,
      adjtr,
      id,
      t,
      new_treatment,
      union_treatment
    );
  end
  return dat
end

function treatneighbors_inner!(
  dat, adjtr,
  id, t,
  new_treatment,
  union_treatment
)

  for i in 1:length(adjtr.aitreated)
    et = @views(adjtr.egot[i])
    eid = @views(adjtr.egoid[i])
    aid = @views(adjtr.aid[i])

    ctrt = (dat[!, id] .== aid) .& (dat[!, t] .== et)
    dat[ctrt, new_treatment] .= 1
    dat[ctrt, union_treatment] .= 1
  end
  return dat
end


function degreeinfo(
  degree, dat, treatment, id, t;
  sink::DataType = Dict{Tuple{Int, Int}, Int}
)
  #=
  no ego id should be listed more than once for an egot
  for each possible aid (see description below)
  we still have observations that are 1 at multiple degrees
  why?
  (at least but should be only) because aid units are registered
  as being adjacent (at whatever degree) separately for each
  egoid x egot; sometimes, this will be at the same time (rallies held in multiple places on same day -- does seem like it should be rare...)
  this function picks the lowest degree
  (across the egos for multiple ego ids at an egot) 
  =#

  union_treatment = Symbol(string(treatment) * "union")
  
  trtvars = [Symbol(string(treatment) * string(k)) for k in 1:degree];
  trtvars = vcat(treatment, trtvars)

  ctrt = dat[!, union_treatment] .== 1;
  selvar = vcat([id, t], trtvars);

  tobs = dat[ctrt, selvar];

  #= because of multiple egot x egoid situation (below)
  catgorize into degree stratum based on minimum
  =#
  
  trts = permutedims(Matrix(tobs[!, trtvars]));
  tobs[!, :degstrt] = Vector{Int64}(undef, size(trts)[2]);
  for j in 1:size(trts)[2]
    for i in 1:(degree + 1)
      if trts[i, j] .== 1
        tobs[j, :degstrt] = i
        break
      end
    end
  end

  select!(tobs, [id, t, :degstrt])
  if sink == DataFrame
    return tobs
  else
    spilldict = sink();
    @eachrow tobs begin
      spilldict[($t, $id)] = :degstrt
    end
    return spilldict
  end
end

"""
    countyspillover_assignment!(cc, dat, degree)

Add new treatment-degree-stratified treatment variables to the dataframe, and generate the assignment of all treated and exposed units.

This should be executed prior to matching, where the treatment union variable should be used, and the stratification assignments should be immediately applied post-matching. It should be applied via stratify!() and customstrat!().

Non-stratified analysis of the union variable estimates the ATT averaged indiscriminately over all exposure levels.
"""
function countyspillover_assignment!(cc, dat, degree)

  C, id2ind, ind2id = getneighbordat();
  adjf = getneighbors(
    cc.treatment, cc.t, cc.id,
    id2ind, ind2id, C, dat, degree
  );
  treatneighbors!(dat, adjf, degree, treatment);
  stratassignments = degreeinfo(degree, dat, treatment, id, t);

  labels = Dict(
    1 => "Treatment",
    2 => "Degree 1",
    3 => "Degree 2",
    4 => "Degree 3",
  );
  
  return dat, stratassignments, labels
end
