# main paper panel plot

function ax_overall!(
  Fig,
  model::ModelRecord;
  fpos = [1,1],
  variablecolors = nothing
)

  strat = !(model.stratifier == Symbol(""));
  
  fmin = minimum(model.F); fmax = maximum(model.F)
  pomin = minimum(model.L); pomax = maximum(model.L)
  
  if strat
    error("no stratified models for overall plot")
  else

    axa, _ = tscsmethods.ax_att(
      Fig[fpos...][1,1], fmin, fmax, model.results;
      outcome = model.outcome
    );
    
    axc, _ = tscsmethods.ax_cb(
      Fig[fpos...][1,2], model.grandbalances, pomin, pomax, variablecolors;
      step = 10
    );

  end

  return Fig
end

function ax_ancillary!(
  Fig,
  model::ModelRecord;
  fpos = [2,1]
)

  strat = !(model.stratifier == Symbol(""));
  
  fmin = minimum(model.F); fmax = maximum(model.F);

  if !strat
    error("ancillary analyses are stratified")
  elseif strat
    pdict = tscsmethods.make_pdict()

    sn = sort(unique(
      sort([k for k in keys(model.grandbalances)])
    ));
  
    if isempty(model.labels)
        error("supply strata labels")
    end
    
    for (i, s) in enumerate(sn)

      resi = model.results[model.results.stratum .== s, :];
      
      subfpos = pdict[i];
      axa, _ = tscsmethods.ax_att(
        Fig[fpos...][subfpos...], fmin, fmax, resi;
        outcome = model.outcome,
        attl = model.labels[s],
        forpanel = true
      );

    end
  end

  Label(
    Fig[2:end-1, 0],
    text = "ATT Estimate",
    textsize = 50,
    rotation = pi/2
  )

  return Fig
end

function ax_ancillary!(
  Fig,
  model::ModelRecord;
  fpos = [2,1]
)

  strat = !(model.stratifier == Symbol(""));
  
  fmin = minimum(model.F); fmax = maximum(model.F);

  if !strat
    error("ancillary analyses are stratified")
  elseif strat
    pdict = tscsmethods.make_pdict()

    sn = sort(unique(
      sort([k for k in keys(model.grandbalances)])
    ));
  
    if isempty(model.labels)
        error("supply strata labels")
    end
    
    for (i, s) in enumerate(sn)

      resi = model.results[model.results.stratum .== s, :];
      
      subfpos = pdict[i];
      axa, _ = tscsmethods.ax_att(
        Fig[fpos...][subfpos...], fmin, fmax, resi;
        outcome = model.outcome,
        attl = model.labels[s],
        forpanel = true
      );

    end
  end

  # Label(
  #   Fig[fpos...][2:end-1, 0],
  #   text = "ATT Estimate",
  #   textsize = 10,
  #   rotation = pi/2
  # )

  return Fig
end

function ax_ancillary!(
  Fig,
  model::ModelRecord,
  results;
  fpos = [2,1]
)

  strat = !(model.stratifier == Symbol(""));
  
  fmin = minimum(model.F); fmax = maximum(model.F);

  if !strat
    error("ancillary analyses are stratified")
  elseif strat
    pdict = tscsmethods.make_pdict()

    sn = sort(unique(
      sort([k for k in results.stratum])
    ));
  
    if isempty(model.labels)
        error("supply strata labels")
    end
    
    for (i, s) in enumerate(sn)

      resi = results[results.stratum .== s, :];
      
      subfpos = pdict[i];
      axa, _ = tscsmethods.ax_att(
        Fig[fpos...][subfpos...], fmin, fmax, resi;
        outcome = model.outcome,
        attl = model.labels[s],
        forpanel = true
      );

    end
  end

  # Label(
  #   Fig[fpos...][2:end-1, 0],
  #   text = "ATT Estimate",
  #   textsize = 10,
  #   rotation = pi/2
  # )

  return Fig
end

function primary_panel(
  ; modpth = "grace out/primary out/", spth = "", ext = ".png", dosave = true,
  figwid = 800, figlen = 800,
  oepos = [1,1], ancpos = [2,1]
)

  # overall
  _, _, _, refinedcal = load_object(
    modpth * "primary full_death_rte_.jld2"
  );

  # in-person turnout rate
  _, _, _, refinedcalstrat = load_object(
    modpth * "primary full_death_rte_In-person Turnout Rate.jld2"
  );

  # "Missing Values" => 5
  results = @subset(refinedcalstrat.results, :stratum .!= 5);

  variablecolors = mk_covpal(VariableNames());

  Fig = Figure(resolution = (figwid, figlen));

  ax_overall!(
    Fig,
    refinedcal;
    fpos = oepos,
    variablecolors = variablecolors
  );

  # do this for each sub analysis
  ax_ancillary!(
    Fig,
    refinedcalstrat,
    results;
    fpos = ancpos
  );

  # sideinfo = Label(Fig[2,1][:,0], "ATT Estimate", rotation = pi/2);

  if dosave
    save(
      spth * "primary_panel" * ext,
      Fig
    )
  end

  return Fig
end

function blm_panel(
  ; modpth = "grace out/protest out/", spth = "", ext = ".png", dosave = true,
  figwid = 800, figlen = 800,
  oepos = [1,1], ancpos = [2,1]
)

  # overall
  _, _, _, refinedcal = load_object(
    modpth * "protest full_death_rte_.jld2"
  );

  # protest size
  _, _, _, refinedcalstrat = load_object(
    modpth * "protest nomob_death_rte_prsize.jld2"
  );

  # refinedcalstrat.results

  variablecolors = mk_covpal(VariableNames());

  Fig = Figure(resolution = (figwid, figlen));

  ax_overall!(
    Fig,
    refinedcal;
    fpos = oepos,
    variablecolors = variablecolors
  );

  # do this for each sub analysis
  ax_ancillary2!(
    Fig,
    refinedcalstrat;
    fpos = ancpos
  );

  # sideinfo = Label(Fig[2,1][:,0], "ATT Estimate", rotation = pi/2);

  if dosave
    save(
      spth * "protest_panel" * ext,
      Fig
    )
  end

  return Fig
end