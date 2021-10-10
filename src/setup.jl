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

function deathmodel(title::String, treatment, modeltype)

  outcome = :death_rte;

  vn = VariableNames();

  modelcovariates = covariateset(
    vn, outcome;
    modeltype = modeltype
  );

  # filter timevary to entries in modelcovariates
  modelcovariates_timevary = Dict{Symbol, Bool}();
  for (covar, v) in vn.timevary
    if covar ∈ modelcovariates
      modelcovariates_timevary[covar] = v
    end
  end

  cc = cicmodel(
    title = title,
    id = :fips,
    t = :running,
    outcome = outcome,
    treatment = treatment,
    covariates = modelcovariates,
    timevary = modelcovariates_timevary,
    fmin = 10,
    fmax = 40,
    mmin = -50,
    mmax = -1
  );
  return cc
end

function casemodel(title::String, treatment, modeltype)

  outcome = :case_rte;

  vn = VariableNames();

  modelcovariates = covariateset(
    vn, outcome;
    modeltype = modeltype
  );

  # filter timevary to entries in modelcovariates
  modelcovariates_timevary = Dict{Symbol, Bool}();
  for (covar, v) in vn.timevary
    if covar ∈ modelcovariates
      modelcovariates_timevary[covar] = v
    end
  end

  cc = cicmodel(
    title = title,
    id = :fips,
    t = :running,
    outcome = outcome,
    treatment = treatment,
    covariates = modelcovariates,
    timevary = modelcovariates_timevary,
    fmin = 3, # CHECK
    fmax = 40,
    mmin = -50, # CHANGE PO DIFFERS FOR CASE RATE
    mmax = -1
  );
  
  return cc
end
