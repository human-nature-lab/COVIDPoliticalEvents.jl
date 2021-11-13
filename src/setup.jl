# setup.jl
# functions involved in setting up the models

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

function deathmodel(title::String, treatment, modeltype, dat; iterations = 500)
  
  vn = VariableNames();
  
  covariates = covariateset(
    vn, vn.deathoutcome;
    modeltype = modeltype
  );

  # filter timevary to entries in modelcovariates
  timevary = Dict{Symbol, Bool}();
  for (covar, v) in vn.timevary
    if covar ∈ covariates
      timevary[covar] = v
    end
  end;

  observations, ids = tscsmethods.observe(dat[!, vn.t], dat[!, vn.id], dat[!, treatment]);
  
  # tobs = make_tobsvec(length(observations), length(ids));
  tobs = tscsmethods.make_matches(length(observations), length(ids));

  model = CIC(
    title = title,
    id = vn.id,
    t = vn.t,
    treatment = treatment,
    outcome = vn.deathoutcome,
    covariates = covariates,
    timevary = timevary,
    F = 10:40,
    L = -50:-1,
    observations = observations,
    ids = ids,
    matches = tobs,
    treatednum = length(observations),
    estimator = "ATT",
    iterations = iterations
  )

  return model
end

function casemodel(title::String, treatment, modeltype, dat; iterations = 500)

  vn = VariableNames();
  
  covariates = covariateset(
    vn, vn.caseoutcome;
    modeltype = modeltype
  );

  # filter timevary to entries in modelcovariates
  timevary = Dict{Symbol, Bool}();
  for (covar, v) in vn.timevary
    if covar ∈ covariates
      timevary[covar] = v
    end
  end;

  observations, ids = tscsmethods.observe(dat[!, vn.t], dat[!, vn.id], dat[!, treatment]);
  
  # tobs = make_tobsvec(length(observations), length(ids));
  tobs = tscsmethods.make_matches(length(observations), length(ids));

  model = CIC(
    title = title,
    id = vn.id,
    t = vn.t,
    treatment = treatment,
    outcome = vn.caseoutcome,
    covariates = covariates,
    timevary = timevary,
    F = 3:40, ## UPDATE
    L = -50:-1, ## UPDATE
    observations = observations,
    ids = ids,
    matches = tobs,
    treatednum = length(observations),
    estimator = "ATT",
    iterations = iterations
  )

  return model
end
