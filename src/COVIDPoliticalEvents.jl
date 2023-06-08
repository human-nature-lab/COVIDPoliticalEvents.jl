module COVIDPoliticalEvents

  using TSCSMethods, Dates, DataFrames, DataFramesMeta
  using Parameters, Accessors
  import TSCSMethods:ModelRecord
  import CSV, HTTP
  import TSCSMethods:mean,std
  using ShiftedArrays # import ShiftedArrays:lead
  import Indicators:sma
  import FileIO.load
  import Downloads:download
  import TSCSMethods:save_object,load_object
  import CategoricalArrays:categorical

  depfiles = [
    "varnames.jl", "data.jl", "setup.jl", "setup_data.jl",
    "models.jl",
    "spillover.jl", "threshold.jl", "stratifiers.jl",
    "countyadjacencies.jl", "countydistances.jl",
    "driving.jl",
    
  ];
  
  for x in depfiles; include(x) end

  export
    # from other packages
    load_object, save,
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
    # mk_covpal,
    # spillover
    countyspillover_assignment, exclude_border_counties,
    # threshold
    thresholdevent!,
    # stratifications
    regionate, datestrat, primarydistancestrat,
    add_recent_events!,
    protest_treatmentcategories,
    rally_treatmentcategories,
    finish_data, indicatetreatments, make_weekly,
    match_distances,
    add_sma!,
    # combined execution
    dataload, preamble, gen_stratdict
    
end
