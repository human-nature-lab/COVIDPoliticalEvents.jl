module COVIDPoliticalEvents

  using tscsmethods, Dates, DataFrames, DataFramesMeta, Parameters, Accessors
  import tscsmethods:ModelRecord
  import CSV, HTTP
  import JLD2:load_object
  import tscsmethods:mean,std
  using CairoMakie
  import ShiftedArrays:lead
  import FileIO.load
  
  include("varnames.jl")
  include("data.jl")
  include("setup.jl")
  include("plotting.jl")
  include("panel_plots.jl")
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
    primary_mob_pl, ga_mob_pl, rally_mob_pl, protest_mob_pl,
    exposure_shift, protest_size_hists,
    primary_panel, blm_panel,
    protest_treatmentcategories
end
