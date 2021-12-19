module COVIDPoliticalEvents

  using tscsmethods, Dates, DataFrames, DataFramesMeta, Parameters, Accessors
  import CSV, HTTP
  import JLD2:load_object
  import tscsmethods:mean,std
  using CairoMakie
  
  include("varnames.jl")
  include("data.jl")
  include("setup.jl")
  include("plotting.jl")
  include("supplemental_plotting.jl")
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
    primary_filter,
    # plotting
    mk_covpal,
    # spillover
    countyspillover_assignment,
    # threshold
    thresholdevent!,
    # stratifications
    regionate, datestrat, primarydistancestrat,
    add_recent_events!,
    # supplemental plotting
    turnout_pl, rescheduled_pl,
    primary_mob_pl, ga_mob_pl,
    exposure_shift, protest_size_hists
end
