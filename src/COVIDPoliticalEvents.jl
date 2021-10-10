module COVIDPoliticalEvents

  using tscsmethods, Dates
  
  include("setup.jl")
  include("varnames.jl")
  include("plotting.jl")
  include("spillover.jl")
  include("threshold.jl")
  include("stratifiers.jl")

  export
  
    # setup
    VariableNames,
    deathmodel,
    casemodel,
    # plotting
    mk_covpal,
    # spillover
    countyspillover_assignment!,
    # threshold
    thresholdevent!,
    # stratifications
    regionate!, datestrat!, primarydistancestrat!
end
