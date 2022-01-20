# variablenames.jl

"""
  VariableNames()

Struct that contains easy references to "nice" variable names; only some of which are used in the analysis.

N = 12
Pick based on maximum number of covariates used in any analysis to keep the colors consistent throughout the paper.
"""
tscsmethods.@with_kw struct VariableNames
  id = :fips;
  t = :running;

  deathoutcome = :death_rte
  caseoutcome = :case_rte

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
  rec = Symbol("Fitness and Recreation");
  relig = Symbol("Religious Organizations");

  prsz = Symbol("Protest Size");
  prec = Symbol("Recent Protests");
  te = Symbol("Treatment exposure");

  # outcome names
  dr = Symbol("Death Rate")
  cr = Symbol("Case Rate")

  # number of colors to generate
  N = 12;

  # whether some variable changes over time
  timevary = Dict(
    phi => false,
    pbl => false,
    ccr => true, cdr => true,
    ste => false, abbr => false,
    fc => false, bac => false,
    mil => false,
    treg => false, tout => false,
    pd => false,
    ts16 => false,
    p65 => false,
    res => true, resl => true, groc => true, bar => true,
    rec => true, relig => true,
    prsz => false, te => false,
    dr => true,
    cr => true,
  );
end
