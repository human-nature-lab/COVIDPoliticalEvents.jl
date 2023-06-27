# spillover.jl

function pathsmat!(codict, C, degree)
  for k in 1:degree
    codict[k] = (C^k .> 0) .* 1 # is there a path of length degree
  end
  return codict
end

"""
        getneighbors(
            treatment, t, id,
            id2ind, ind2id, C,
            dat, degree::Int
        )

Return the set of neighbors up to degree.
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

    tot = trtobs[!, t];
    toid = trtobs[!, id];

    getneighbors_inner!(
        adjf,
        trtobs,
        codict, degree,
        tot, toid,
        id2ind, ind2id
    )

    return adjf
end

"""
        getneighbors_inner!(
            adjf,
            trtobs,
            codict, degree,
            tot, toid,
            id2ind, ind2id
        )

Construct a vector for i in 1:degree that contains the set of untreated neighbors of treated units in the data, for each neighbor degree in 1:degree.

For cases where multiple direct treatments spillover onto a county, find the minimum path from ego to alter, and skip longer paths
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
        egoid = @views(toid[i]) # the directly treated unit
    
        eind = id2ind[egoid]
        for j in 1:size(codict[1])[1] # over alters to ego
            # loop over degree values and stop when append happens
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
                    # find first (:. minimum) path from ego to alter; skip longer paths
                    break
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
    countyspillover_assignment(dat, degree, treatment, t, id)

Add new treatment-degree-stratified treatment variables to the dataframe, and generate the assignment of all treated and exposed units.

This should be executed prior to matching, where the treatment union variable should be used, and the stratification assignments should be immediately applied post-matching. It should be applied via stratify!() and customstrat!().

Non-stratified analysis of the union variable estimates the ATT averaged indiscriminately over all exposure levels.
"""
function countyspillover_assignment(dat, degree, treatment, t, id)

  C, id2ind, ind2id = getneighbordat();
  adjf = getneighbors(
    treatment, t, id,
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

  return dat, stratassignments, labels, Symbol(string(treatment) * "union")
end
