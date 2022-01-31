# setup.jl
# functions involved in setting up the models

"""
    protest_treatmentcategories(x)

(For use as input to match!)
Protest treatment history categories.
We look at total count in the pre-treatment crossover
period for both the treated unit and its (potential) match.
If the totals, for each, in the same period fall into the same cateory,
we allow the match.
"""
function protest_treatmentcategories(x)
  if x == 0; g = 0 end
  if (x == 1) | (x == 2); g = 1 end
  if (x > 2) & (x < 10); g = 2 end
  if (x >= 10); g = 3 end
  return g
end

"""
    rally_treatmentcategories(x)

(For use as input to match!)
Rally treatment history categories.
We look at total count in the pre-treatment crossover
period for both the treated unit and its (potential) match.
If the totals, for each, in the same period fall into the same cateory,
we allow the match.

The exposures are accounted for directly in match!
"""
function rally_treatmentcategories(x)
  return x <= 0 ? 0 : 1
end

"""
    covariateset(vn::VariableNames, outcome::Symbol; modeltype::String = "epi")

Return the covariates for the specified model type ("epi", "nomob", "full").
"""
function covariateset(
  vn::VariableNames, outcome::Symbol;
  modeltype::Symbol = :epi
)

  epi = modeltype == :epi
  nomob = modeltype == :nomob
  full = modeltype == :full

  deathrte = outcome == :death_rte
  caserte = outcome == :case_rte

  if epi & deathrte
    return [vn.cdr, vn.pd, vn.fc]
  elseif epi & caserte
    return [vn.ccr, vn.pd, vn.fc]
  elseif nomob & deathrte
    return [vn.cdr, vn.fc, vn.pd, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65];
  elseif nomob & caserte
    return [vn.ccr, vn.fc, vn.pd, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65];
  elseif full & deathrte
    return [
      vn.cdr, vn.fc, vn.pd, vn.res, vn.groc,
      vn.rec, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65
    ];
  elseif full & caserte
    return [
      vn.ccr, vn.fc, vn.pd, vn.res, vn.groc,
      vn.rec, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65
    ];
  end
end

function deathmodel(
  title::String, treatment, modeltype, dat;
  F = 10:40, L = -30:-1, iterations = 500,
  matchingcovariates = nothing
)
  
  vn = VariableNames();
  
  covariates = if isnothing(matchingcovariates)
    covariateset(
      vn, vn.deathoutcome;
      modeltype = modeltype
    );
  else matchingcovariates
  end

  # filter timevary to entries in modelcovariates
  timevary = Dict{Symbol, Bool}();
  for (covar, v) in vn.timevary
    if covar ∈ covariates
      timevary[covar] = v
    end
  end;

  observations, ids = tscsmethods.observe(dat[!, vn.t], dat[!, vn.id], dat[!, treatment]);

  # tobs = make_tobsvec(length(observations), length(ids));
  tobs = tscsmethods.make_matches(
    length(observations), length(ids), length(F)
  );

  model = CIC(
    title = title,
    id = vn.id,
    t = vn.t,
    treatment = treatment,
    outcome = vn.deathoutcome,
    covariates = covariates,
    timevary = timevary,
    F = F,
    L = L, # 40 days before up to 1 day before (-10 is day of) 
    observations = observations,
    ids = ids,
    matches = tobs,
    treatednum = length(observations),
    estimator = "ATT",
    iterations = iterations
  )

  return model
end

function casemodel(
  title::String, treatment, modeltype, dat;
  F = 10:40, L = -30:-1, iterations = 500,
  matchingcovariates = nothing
)

  vn = VariableNames();
  
  covariates = if isnothing(matchingcovariates)
    covariateset(
      vn, vn.caseoutcome;
      modeltype = modeltype
    );
  else matchingcovariates
  end

  # filter timevary to entries in modelcovariates
  timevary = Dict{Symbol, Bool}();
  for (covar, v) in vn.timevary
    if covar ∈ covariates
      timevary[covar] = v
    end
  end;

  observations, ids = tscsmethods.observe(dat[!, vn.t], dat[!, vn.id], dat[!, treatment]);

  # tobs = make_tobsvec(length(observations), length(ids));
  tobs = tscsmethods.make_matches(length(observations), length(ids), length(F));

  model = CIC(
    title = title,
    id = vn.id,
    t = vn.t,
    treatment = treatment,
    outcome = vn.caseoutcome,
    covariates = covariates,
    timevary = timevary,
    F = F,
    L = L,
    observations = observations,
    ids = ids,
    matches = tobs,
    treatednum = length(observations),
    estimator = "ATT",
    iterations = iterations
  )

  return model
end
