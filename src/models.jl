# models.jl

function deathmodel(
  title::String, treatment, modeltype, dat;
  F = 10:40, L = -30:-1, iterations = 500,
  matchingcovariates = nothing,
  rate = true
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

  observations, ids = TSCSMethods.observe(dat[!, vn.t], dat[!, vn.id], dat[!, treatment]);

  # tobs = make_tobsvec(length(observations), length(ids));
  tobs = TSCSMethods.make_matches(
    length(observations), length(ids), length(F)
  );

  model = CIC(
    title = title,
    id = vn.id,
    t = vn.t,
    treatment = treatment,
    outcome = rate ? vn.deathoutcome : :deaths,
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
  matchingcovariates = nothing,
  rate = true
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

  observations, ids = TSCSMethods.observe(dat[!, vn.t], dat[!, vn.id], dat[!, treatment]);

  # tobs = make_tobsvec(length(observations), length(ids));
  tobs = TSCSMethods.make_matches(length(observations), length(ids), length(F));

  model = CIC(
    title = title,
    id = vn.id,
    t = vn.t,
    treatment = treatment,
    outcome = rate ? vn.caseoutcome : cases,
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

function rtmodel(
  title::String, treatment, modeltype, dat;
  F = 0:40, L = -30:-1, iterations = 500,
  matchingcovariates = nothing
)

  vn = VariableNames();
  
  covariates = if isnothing(matchingcovariates)
    covariateset(
      vn, vn.rt;
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

  observations, ids = TSCSMethods.observe(dat[!, vn.t], dat[!, vn.id], dat[!, treatment]);

  # tobs = make_tobsvec(length(observations), length(ids));
  tobs = TSCSMethods.make_matches(length(observations), length(ids), length(F));

  model = CIC(
    title = title,
    id = vn.id,
    t = vn.t,
    treatment = treatment,
    outcome = vn.rt,
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

function mobmodel(
  title::String, outcome, refoutcome, treatment, modeltype, dat;
  F = 0:40, L = -30:-1, iterations = 500,
  matchingcovariates = nothing
)

  vn = VariableNames();
  
  covariates = if isnothing(matchingcovariates)
    covariateset(
      vn, refoutcome;
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

  observations, ids = TSCSMethods.observe(dat[!, vn.t], dat[!, vn.id], dat[!, treatment]);

  # tobs = make_tobsvec(length(observations), length(ids));
  tobs = TSCSMethods.make_matches(length(observations), length(ids), length(F));

  model = CIC(
    title = title,
    id = vn.id,
    t = vn.t,
    treatment = treatment,
    outcome = outcome,
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
