# variablenames.jl

"""
  VariableNames()

Struct that contains easy references to "nice" variable names; only some of which are used in the analysis.

N = 12
Pick based on maximum number of covariates used in any analysis to keep the colors consistent throughout the paper.
"""
@with_kw struct VariableNames
  phi = Symbol("Pct. Hispanic");
  pbl = Symbol("Pct. Afr. American");
  ccr = Symbol("Cum. Case Rate");
  cdr = Symbol("Cum. Death Rate");

  ste = :State;
  abbr = Symbol("State Abbr.");
  fc = Symbol("Date of First Case");
  bac = Symbol("Pct. with Bacc. Deg.");

  mil = Symbol("Median Income (log)");
  treg = Symbol("Tot. Registered Voters");
  tout =  Symbol("In-person Turnout Rate");
  pd =  Symbol("Pop. Density");

  ts16 = Symbol("Trump 2016 Vote Share");
  p65 = Symbol("Pct. 65 yrs and Above");
  res = Symbol("Full-Service Restaurants");

  resl = Symbol("Restaurants Limited-Service");
  groc = :Grocers;
  bar = Symbol("Drinking Places (Alcoholic Beverages)");
  rec = Symbol("Fitness and Recreational Sports Centers");
  relig = Symbol("Religious Organizations");

  prsz = Symbol("Protest Size");
  te = Symbol("Treatment exposure");

  # outcome names
  dr = Symbol("Death Rate")
  cr = Symbol("Case Rate")

  # number of colors to generate
  N = 12;
end
  
"""
    covariateset(vn::VariableNames, outcome::Symbol; modeltype::String = "epi")

Return the covariates for the specified model type ("epi", "nomob", "full").
"""
function covariateset(
  vn::VariableNames, outcome::Symbol;
  modeltype::String = "epi"
)
  if modeltype == "epi" & outcome == :death_rte
    return [vn.cdr, vn.pd, vn.fc]
  elseif modeltype == "epi" & outcome == :case_rte
    return [vn.ccr, vn.pd, vn.fc]
  elseif modeltype == "nomob" & outcome == :death_rte
    return [vn.cdr, vn.fc, vn.pd, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65];
  elseif modeltype == "nomob" & outcome == :case_rte
    return [vn.ccr, vn.fc, vn.pd, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65];
  elseif modeltype == "full" & outcome == :death_rte
    return [
      vn.cdr, vn.fc, vn.pd, vn.res, vn.groc,
      vn.rec, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65
    ];
  elseif modeltype == "full" & outcome == :case_rte
    return [
      vn.ccr, vn.fc, vn.pd, vn.res, vn.groc,
      vn.rec, vn.pbl, vn.phi, vn.ts16, vn.mil, vn.p65
    ];
  end
end
