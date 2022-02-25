# main paper panel plot

function ax_overall!(
  Fig,
  model::ModelRecord;
  fpos = [1,1],
  lpos = [3,2],
  variablecolors = nothing
)

  strat = !(model.stratifier == Symbol(""));
  
  fmin = minimum(model.F); fmax = maximum(model.F)
  pomin = minimum(model.L); pomax = maximum(model.L);
  
  
  if strat
    error("no stratified models for overall plot")
  else

    axa, _ = TSCSMethods.ax_att(
      Fig[fpos...][1,1], fmin, fmax, model.results;
      outcome = model.outcome
    );

    # Legend(Fig[3,2][1,1], axa)
    
    axc, _ = TSCSMethods.ax_cb(
      Fig[fpos...][1,2], model.grandbalances, pomin, pomax, variablecolors;
      step = 10
    );

    Legend(Fig[lpos...][1,1], axc, nbanks = 3, framevisible = false)

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
    pdict = TSCSMethods.make_pdict()

    sn = sort(unique(
      sort([k for k in keys(model.grandbalances)])
    ));
  
    if isempty(model.labels)
        error("supply strata labels")
    end
    
    for (i, s) in enumerate(sn)

      resi = model.results[model.results.stratum .== s, :];
      
      subfpos = pdict[i];
      axa, _ = TSCSMethods.ax_att(
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
    pdict = TSCSMethods.make_pdict()

    sn = sort(unique(
      sort([k for k in keys(model.grandbalances)])
    ));
  
    if isempty(model.labels)
        error("supply strata labels")
    end
    
    for (i, s) in enumerate(sn)

      resi = model.results[model.results.stratum .== s, :];
      
      subfpos = pdict[i];
      axa, _ = TSCSMethods.ax_att(
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
    pdict = TSCSMethods.make_pdict()

    sn = sort(unique(
      sort([k for k in results.stratum])
    ));
  
    if isempty(model.labels)
        error("supply strata labels")
    end
    
    for (i, s) in enumerate(sn)

      resi = results[results.stratum .== s, :];
      
      subfpos = pdict[i];
      axa, _ = TSCSMethods.ax_att(
        Fig[fpos...][subfpos...], fmin, fmax, resi;
        outcome = model.outcome,
        attl = model.labels[s],
        forpanel = true
      );

    end
  end

  return Fig
end

function primary_plot()

end

function primary_panel(
  ; modpth = "grace out/primary out/", spth = "", ext = ".png", dosave = true,
  figwid = 1800, figlen = 800,
  oepos = [1,2], ancpos = [2,2],
  treatpos = [:, 1],
  pathtoimg = "covid-political-events-paper (working)/method_diagram-01.png"
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

  g1 = Fig[:, 1] = GridLayout();
  g2 = Fig[1, 2] = GridLayout();
  g3 = Fig[2, 2] = GridLayout();
  g4 = Fig[3, 2] = GridLayout();

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

  img = load(pathtoimg);

  axd = Axis(Fig[treatpos...])
  hidedecorations!(axd);
  hidespines!(axd)
  image!(Fig[treatpos...], rotr90(img),)
  axd.aspect = DataAspect()


  for (label, layout) in zip(["a", "b", "c"], [g1, g2, g3])
    Label(layout[1, 1, TopLeft()], label,
        textsize = 26,
        padding = (0, 5, 5, 0),
        halign = :right)
  end
  
  # sideinfo = Label(Fig[2,1][:,0], "ATT Estimate", rotation = pi/2);
  
  rowsize!(g2, 1, Relative(0.9))
  rowsize!(g3, 1, Relative(0.9))
  rowsize!(g3, 2, Relative(0.9))

  colsize!(Fig.layout, 2, Auto())

  colgap!(g2, 1)
  rowgap!(g2, 0.1)

  colgap!(g3, 1)
  rowgap!(g3, 0.1)

  colgap!(g4, 1)
  rowgap!(g4, 0.1)

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
  figwid = 1000, figlen = 800,
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

  g1 = Fig[1, 1] = GridLayout();
  g2 = Fig[2, 1] = GridLayout();

  ax_overall!(
    Fig,
    refinedcal;
    fpos = oepos,
    lpos = [3,1],
    variablecolors = variablecolors
  );

  # do this for each sub analysis
  ax_ancillary!(
    Fig,
    refinedcalstrat;
    fpos = ancpos
  );

  # sideinfo = Label(Fig[2,1][:,0], "ATT Estimate", rotation = pi/2);

  for (label, layout) in zip(["a", "b"], [g1, g2])
    Label(layout[1, 1, TopLeft()], label,
        textsize = 26,
        padding = (0, 5, 5, 0),
        halign = :right)
  end

  rowsize!(g1, 1, Relative(0.9))
  rowsize!(g2, 1, Relative(0.9))
  rowsize!(g2, 2, Relative(0.9))

  colsize!(Fig.layout, 1, Auto())

  # colgap!(g1, 1)
  # rowgap!(g1, 0.1)

  # colgap!(g2, 1)
  # rowgap!(g2, 0.1)

  Fig

  if dosave
    save(
      spth * "protest_panel" * ext,
      Fig
    )
  end

  return Fig
end