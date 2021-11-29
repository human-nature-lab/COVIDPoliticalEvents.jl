module COVIDPoliticalEvents

  using tscsmethods, Dates, DataFrames, DataFramesMeta, Parameters
  import CSV
  
  include("varnames.jl")
  include("data.jl")
  include("setup.jl")
  include("plotting.jl")
  include("spillover.jl")
  include("threshold.jl")
  include("stratifiers.jl")

  export
  
    # setup
    VariableNames,
    deathmodel,
    casemodel,
    # data
    treatga!,
    dataprep,
    primary_filter!,
    # plotting
    mk_covpal,
    # spillover
    countyspillover_assignment!,
    # threshold
    thresholdevent!,
    # stratifications
    regionate!, datestrat!, primarydistancestrat!,
    add_recent_events!
end
