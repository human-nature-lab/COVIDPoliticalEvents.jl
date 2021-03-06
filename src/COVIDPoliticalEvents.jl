module COVIDPoliticalEvents

  using TSCSMethods, Dates, DataFrames, DataFramesMeta
  using Parameters, Accessors
  import TSCSMethods:ModelRecord
  import CSV, HTTP
  import JLD2:load_object
  import TSCSMethods:mean,std
  using CairoMakie
  import ShiftedArrays:lead
  import FileIO.load
  import Indicators:sma
  
  depfiles = [
    "varnames.jl", "data.jl", "setup.jl", "setup_data.jl",
    "models.jl",
    "plotting.jl", "panel_plots.jl", "supplemental_plotting.jl",
    "spillover.jl", "threshold.jl", "stratifiers.jl",
    "countyadjacencies.jl", "countydistances.jl",
    "driving.jl"
  ];
  
  for x in depfiles; include(x) end

  export
    # setup
    VariableNames,
    deathmodel,
    casemodel,
    rtmodel,
    mobmodel,
    # data
    treatstateondate!,
    dataprep,
    primary_filter, filter_treated,
    merge_Rt_data,
    # plotting
    mk_covpal,
    # spillover
    countyspillover_assignment, exclude_border_counties,
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
    protest_treatmentcategories,
    rally_treatmentcategories,
    finish_data, indicatetreatments, make_weekly,
    match_distances,
    add_sma!,
    # combined execution
    dataload, preamble, gen_stratdict
end
