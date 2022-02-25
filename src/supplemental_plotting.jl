# functions to create supplemental plots

function make_primary_info(;
  dat = nothing, datapath = "covid-19-data/data/",
  firstdate = Date("2020-03-17")
)
  
  vn = VariableNames();

  if isnothing(dat)
    dat = load_object(datapath * "cvd_dat.jld2");
  end

  tdat = @subset(dat, :primary .== 1)
  tdat = unique(tdat[!, [:date, vn.abbr]]);
  tdat[!, :type] .= "in-person"
  tdat[!, :reschedule] .= "No";
  tdat[!, :cancelled] .= "No";
  tdat.odate = Vector{Union{Dates.Date, Missing}}(missing, nrow(tdat));

  # add removed
  push!(
    tdat,
    (Dates.Date("2020-03-03"), "CO", "mail-in", "No", "Yes", missing)
  )
  push!(
    tdat,
    (Dates.Date("2020-03-10"), "WA", "mail-in", "No", "No", missing)
  )
  push!(
    tdat,
    (Dates.Date("2020-05-22"),"HI", "mail-in", "Yes", "Yes",
    Dates.Date("2020-04-04"))
  )
  push!(
    tdat,
    (Dates.Date("2020-04-17"), "WY", "mail-in", "Yes", "Yes",
    Dates.Date("2020-04-04"))
  )
  push!(
    tdat,
    (Dates.Date("2020-05-02"), "KS", "mail-in", "No", "Yes", missing)
  )
  push!(
    tdat,
    (Dates.Date("2020-04-28"), "OH", "mail-in", "Yes", "Yes",
    Dates.Date("2020-03-17"))
  )
  push!(
    tdat,
    (Dates.Date("2020-04-10"), "AK", "mail-in", "Yes", "Yes",
    Dates.Date("2020-04-04"))
  )
  push!(
    tdat,
    (Dates.Date("2020-05-19"), "OR", "mail-in", "No", "No", missing)
  )
  push!(
    tdat,
    (Dates.Date("2020-03-03"), "UT", "mail-in", "No", "No", missing)
  )
  push!(
    tdat,
    (Dates.Date("2020-02-22"), "NV", "too early", "No", "No", missing)
  )
  push!(
    tdat,
    (Dates.Date("2020-02-29"), "SC", "too early", "No", "No", missing)
  )

  # change reschedule, cancelled

  tooearly = (tdat.type .== "in-person") .&
  (tdat.date .< Dates.Date("2020-03-14"));

  tdat.type[tooearly] .= "too early";

  rschls = [
    "GA", "LA", "MD", "PA",
    "RI", "NY", "DE", "CT",
    "IN", "WV", "KY", "NJ"
  ];
  rschdls = [
    "2020-03-24", "2020-04-04", "2020-04-28",
    "2020-04-28", "2020-04-28", "2020-04-28",
    "2020-04-28", "2020-04-28", "2020-05-05",
    "2020-05-12", "2020-05-19", "2020-06-02"
  ];

  for (i, ste) in enumerate(rschls)
    s = tdat[!, vn.abbr] .== ste
    tdat.reschedule[s] = ["Yes"]
    tdat.odate[s] = [Dates.Date(rschdls[i])]
  end

  if !isnothing(firstdate)
    tdat = tdat[tdat.date .>= firstdate, :]
  end

  tdat = tdat[tdat.type .== "in-person", :]

  return sort!(tdat, :date)
end

"""
Plot the in person turnout rate for GA, the primaries.
"""
function turnout_pl(;
  datapath = "covid-19-data/data/",
  savepath = "supp out/",
  L = -50:-1
)
  
  vn = VariableNames();

  # primary
  dat = load_object(datapath * "cvd_dat.jld2");
  c1 = ismissing.(dat[!, vn.tout]);
  c2 = dat.primary .== 1;
  c3 = dat[!, vn.t] .> (-1 * minimum(L)); # NOT RIGHT?
  mstates = unique(@views(dat[c1 .& c2 .& c3, vn.abbr]));
  primary = @views(dat[.!c1 .& c2 .& c3, :]);
  primary_avg_tout = mean(primary[!, vn.tout]);

  # ga special
  ga_election = ga_turnout(dat);
  ga_avg_tout = mean(ga_election[!, vn.tout]);

  tout_pl = Figure(resolution = (1200, 600));

  ax1 = Axis(
    tout_pl[1, 1],
    title = "Primary",
    # xticks = collect(range(-13, stop = 0; step = 3)),
    # xlabel = "Day",
    # ylabel = "Balance Score",
    xminorgridvisible = true,
    xminorticksvisible = true,
    # xminorticks = IntervalsBetween(3)
  )

  hist!(
    tout_pl[1, 1],
    primary[!, vn.tout],
    # bins = 20,
    color = :grey,
    strokewidth = 1,
    strokecolor = :black
  )

  vlines!(ax1, primary_avg_tout, color = :red)

  ax2 = Axis(
    tout_pl[1, 2],
    title = "GA Special",
    # xticks = collect(range(-13, stop = 0; step = 3)),
    # xlabel = "Day",
    # ylabel = "Balance Score",
    xminorgridvisible = true,
    xminorticksvisible = true,
    # xminorticks = IntervalsBetween(3)
  )

  hist!(
    tout_pl[1, 2],
    ga_election[!, vn.tout],
    # bins = 20,
    color = :grey,
    strokewidth = 1,
    strokecolor = :black
  )

  vlines!(ax2, ga_avg_tout, color = :red)

  # no title in plots per journal style
  # Label(
  #   tout_pl[1, 1:2, Top()],
  #   string(vn.tout), valign = :bottom,
  #   padding = (0, 0, 5, 0)
  # )

  save(
    savepath * "turnout_pl" * ".png",
    tout_pl
  )
  return tout_pl
end

function rescheduled_pl(;
  dm = Symbol("death_rte"),
  cm = Symbol("case_rte"),
  datapath = "covid-19-data/data/",
  savepath = "supp out/",
  fext = ".png",
  prior_days = 14,
  w = 1200,
  h = 600
)

  vn = VariableNames();

  dat = load_object(datapath * "cvd_dat.jld2");
  primary = make_primary_info(; dat = dat);

  resched = @subset(
    primary,
    :type .== "in-person", :reschedule .== "Yes", :cancelled .== "No"
  );

  # number of counties present in each state
  @eachrow! resched begin
    @newcol :countynum::Vector{Int64}
    :countynum = length(
      unique(dat[!, vn.id][dat[!, vn.abbr] .== cols(vn.abbr)])
    )
  end

  places = collect(Iterators.product(1:3, 1:4));
  pl_dm = Figure(resolution = (w, h));
  pl_cm = Figure(resolution = (w, h));

  pal = mk_covpal(vn);

  for (i, r) in enumerate(eachrow(resched))
    cstate = dat[!, vn.abbr] .== r[vn.abbr];

    dat[!, :period] = fill(:none, nrow(dat));

    cdate = (dat[!, :date] .<= r[:date]) .& (dat[!, :date] .>= r[:date] - Day(prior_days));
    dat[cdate, :period] .= :rescheduled;

    corig = (dat[!, :date] .<= r[:odate]) .& (dat[!, :date] .>= r[:odate] - Day(prior_days));
    dat[corig, :period] .= :original;

    # minus the original date
    datsched = dat[cstate .& (cdate .| corig), :];
    c_od = datsched.period .== :original;
    datsched[c_od, dm] = datsched[c_od, dm] .* -1.0;
    datsched[c_od, cm] = datsched[c_od, cm] .* -1.0;

    # hcat(
    #   datsched[datsched.date .== r[:odate], dm],
    #   datsched[datsched.date .== r[:date], dm],
    #   datsched[datsched.date .== r[:odate], dm] + datsched[datsched.date .== r[:date], cm]
    # )

    dmd = Symbol(string(dm) * " Diff.");
    cmd = Symbol(string(cm) * " Diff.");

    datsched = @chain datsched begin
      sort(:date)
      groupby([vn.id, vn.abbr])
      @combine(
        $(dmd) = sum($(dm)),
        $(cmd) = sum($(cm)),
      )
    end

    ax_dm = Axis(
      pl_dm[(places[i])...],
      title = r[vn.abbr],
      # xticks = collect(range(-13, stop = 0; step = 3)),
      # xlabel = "Day",
      # ylabel = "Balance Score",
      xminorgridvisible = true,
      xminorticksvisible = true,
      # xminorticks = IntervalsBetween(3)
    )

    hist!(
      pl_dm[(places[i])...],
      datsched[!, dmd],
      color = pal[vn.cdr],
      strokewidth = 1,
      strokecolor = :black
    )

    vlines!(ax_dm, mean(datsched[!, dmd]), color = :red)

    ax_cm = Axis(
      pl_cm[(places[i])...],
      title = r[vn.abbr],
      # xticks = collect(range(-13, stop = 0; step = 3)),
      # xlabel = "Day",
      # ylabel = "Balance Score",
      xminorgridvisible = true,
      xminorticksvisible = true,
      # xminorticks = IntervalsBetween(3)
    )

    hist!(
      pl_cm[(places[i])...],
      datsched[!, cmd],
      color = pal[vn.ccr],
      strokewidth = 1,
      strokecolor = :black
    )

    vlines!(ax_cm, mean(datsched[!, cmd]), color = :red)

  end

  save(
    savepath * "primary_diff_pl" * fext,
    pl_dm
  )

  save(
    savepath * "primary_diff_case_pl" * fext,
    pl_cm
  )

  return pl_dm, pl_cm
end

function primary_mob_pl(;
  datapath = "covid-19-data/data/",
  savepath = "supp out/",
  fext = ".png",
  days = 14,
  w = 1200,
  h = 800,
  popfactor = 10000
)

  vn = VariableNames();
  
  mobvar = sort(
    [
      vn.res, vn.groc,
      vn.rec, vn.relig, vn.bar
    ]
  );

  dat = load_object(datapath * "cvd_dat.jld2");
  primary = make_primary_info(; dat = dat, firstdate = Date("2020-03-17"));

  # cprim = unique(dat[dat[!, :primary] .== 1, [:date, vn.abbr]]);

  primdat = similar(dat, 0);
  primdat[!, :Day] = Int[];

  for r in eachrow(primary)
    ctime = (dat[!, :date] .<= r[:date] + Day(days)) .& (dat[!, :date] .>= r[:date] - Day(days));
    
    primdat_i = dat[ctime .& (dat[!, vn.abbr] .== r[vn.abbr]), :];
    if nrow(primdat_i) > 0
      primdat_i[!, :Day] = Dates.value.(primdat_i[!, :date] .- r[:date])
      append!(primdat, primdat_i)
    end
  end

  select!(primdat, [:Day, vn.id, :State, mobvar..., :pop])

  # # adjust for population
  # for var in mobvar
  #   primdat[!, var] = primdat[!, var] #./ (primdat[!, :pop])
  # end

  select!(primdat, Not([:pop]))
  vc = Symbol("Visits Per Capita");

  primdat = @chain primdat begin
    stack(
      Not([:Day, vn.id, :State]),
      variable_name = :Place,
      value_name = vc
    )
    groupby([:Day, :State, :Place])
    @combine(
      $vc = mean($vc)
    )
  end

  primary_mobility = Figure(resolution = (h, w));

  axr = nothing;

  # (r, e) = collect(enumerate(unique(primdat.Place)))[1]
  for (r, e) in enumerate(unique(primdat.Place))
    
    datsub = primdat[primdat[!, :Place] .== e, :];

    servals, serlabs, sercols = makeseries_state(
      datsub,
      :State, :Day, vc, days
    );

    axr = Axis(
      primary_mobility[r, 1],
      title = e,
      xticks = collect(range(-days, stop = days; step = 2)),
      # xlabel = "Day",
      # ylabel = "State-level visits per million persons",
      xminorgridvisible = true,
      xminorticksvisible = true,
      xminorticks = IntervalsBetween(2)
    )

    ser = series!(
      axr,
      collect(range(-days, days; step = 1)),
      servals .* popfactor,
      labels = serlabs,
      markersize = 5,
      color = sercols
    )

  end

  lc = Legend(
    primary_mobility,
    axr,
    "State",
    framevisible = false,
    nbanks = 4
  )

  hm_sublayout2 = GridLayout()
  primary_mobility[length(unique(primdat.Place)) + 1, :] = hm_sublayout2

  hm_sublayout2[:v] = [lc]

  # bottominfo = Label(
  #   primary_mobility[6, :],
  #   "Day"
  #   )

  colsize!(primary_mobility.layout, 1, Relative(9/10));
    
  sideinfo = Label(
    primary_mobility[1:5, 0],
    "State-level visits per 10K persons",
    rotation = pi/2
    )

  axr.attributes.xlabel = "Day"

  save(
    savepath * "primary_mob_pl" * fext,
    primary_mobility
  )

  return primary_mobility
end

function makeseries_state(datsub, idvar, tvar, var, days)

  ds = select(datsub, [idvar, tvar, var]);
  states = sort(unique(ds[!, idvar]));

  servals = Matrix{Union{Float64, Missing}}(missing, length(states), length(-days:days))
  
  rnge = (-days:days) .+ (days + 1);

  stedict = Dict(states .=> 1:length(states));
  sd = Dict{Tuple{Int, Int}, Float64}(); # time, state index
  @eachrow ds begin
    sd[($tvar + days + 1, stedict[$idvar])] = $var
  end

  for j in 1:length(rnge) # time
    for i in 1:size(servals)[1] # state
      servals[i, j] = get(sd, (j, i), missing)
    end
  end

  serlabs = states;

  # assume same states for each metric:
  sercols = TSCSMethods.gen_colors(length(serlabs)); 

  return servals, serlabs, sercols
end

function ga_mob_pl(
  datapath = "covid-19-data/data/",
  savepath = "supp out/",
  fext = ".png",
  days = 14,
  w = 1200,
  h = 800,
  popfactor = 10000
)

  vn = VariableNames();
  
  mobvar = sort(
    [
      vn.res, vn.groc,
      vn.rec, vn.relig, vn.bar
    ]
  );

  dat = load_object(datapath * "cvd_dat.jld2");
  treatga!(dat)

  gadat = @chain dat begin
    @subset(
      :State .== "Georgia",
      (:date .>= Date("2021-01-05") - Day(days)) .&
        (:date .<= Date("2021-01-05") + Day(days))
      )
    sort(:date)
  end

  gadat[!, :Day] = Dates.value.(gadat[!, :date] .- Date("2021-01-05"));

  select!(gadat, [:Day, vn.id, mobvar...])
  
  vc = Symbol("Visits Per Capita");
  vcstd = Symbol("Visits Per Capita (std)");

  gadat = @chain gadat begin
    stack(
      Not([:Day, vn.id]),
      variable_name = :Place,
      value_name = vc
    )
    groupby([:Day, :Place])
    @combine(
      $vc = mean($vc .* popfactor),
      $vcstd = std($vc .* popfactor)

    )
  end

  ga_mobility = Figure(resolution = (h, w));

  axr = nothing;

  # (r, e) = collect(enumerate(unique(primdat.Place)))[1]
  for (r, e) in enumerate(sort(unique(gadat.Place)))
    
    datsub = gadat[gadat[!, :Place] .== e, :];

    axr = Axis(
      ga_mobility[r, 1],
      title = e,
      xticks = collect(range(-days, stop = days; step = 2)),
      # xlabel = "Day",
      # ylabel = "State-level visits per million persons",
      xminorgridvisible = true,
      xminorticksvisible = true,
      xminorticks = IntervalsBetween(2)
    )

    ts = collect(range(-days, days; step = 1))

    lne = lines!(
      axr,
      ts,
      datsub[!, vc],
      # labels = serlabs,
      markersize = 5,
      # color = sercols
    )

    band!(
      axr,
      ts,
      datsub[!, vc] + datsub[!, vcstd],
      datsub[!, vc] - datsub[!, vcstd]
    )

  end

  # lc = Legend(
  #   primary_mobility,
  #   axr,
  #   "State",
  #   framevisible = false,
  #   nbanks = 4
  # )

  # hm_sublayout2 = GridLayout()
  # primary_mobility[length(unique(primdat.Place)) + 1, :] = hm_sublayout2

  # hm_sublayout2[:v] = [lc]

  # bottominfo = Label(
  #   primary_mobility[6, :],
  #   "Day"
  #   )

  # colsize!(primary_mobility.layout, 1, Relative(9/10));
    
  sideinfo = Label(
    ga_mobility[1:5, 0],
    "State-level visits per 10K persons",
    rotation = pi/2
    )

  axr.attributes.xlabel = "Day"

  save(
    savepath * "ga_mob_pl" * fext,
    ga_mobility
  )

  return ga_mobility
end

function rally_mob_pl(;
  datapath = "covid-19-data/data/",
  savepath = "supp out/",
  fext = ".png",
  days = 14,
  w = 1200,
  h = 800,
  popfactor = 10000
)

  vn = VariableNames();
  vc = Symbol("Visits Per Capita")

  mobvar = sort(
    [
      vn.res, vn.groc,
      vn.rec, vn.relig, vn.bar
    ]
  );

  dat = load_object(datapath * "cvd_dat.jld2");
  
  # setup the exposure information
  dat, stratassignments, labels, _ = countyspillover_assignment(
    dat, 3, :rallyday, vn.t, vn.id
  );

  select!(
    dat,
    [
      vn.t, vn.id, mobvar...,
      :rallydayunion, :rallyday0, :rallyday1, :rallyday2, :rallyday3
    ]
  )

  rallydat = similar(dat, 0)
  nds = Symbol("Treatment Exposure");
  rallydat[!, nds] = String[];
  rallydat[!, :Day] = Int[];
  
  # strat assignments contains the treatment info
  for (k, v) in stratassignments
    ct1 = (dat[!, vn.t] .>= k[1] - days);
    ct2 = (dat[!, vn.t] .<= k[1] + days);
    cid = dat[!, vn.id] .== k[2];

    dkv = dat[ct1 .& ct2 .& cid, :];
    dkv[!, nds] .= get(labels, v, 0);
    dkv[!, :Day] = dkv[!, vn.t] .- k[1]
    append!(rallydat, dkv)
  end

  rallydat = @chain rallydat begin
    select(
      Not(
        [vn.t, :rallydayunion, :rallyday0, :rallyday1, :rallyday2, :rallyday3]
      )
    )
    stack(Not([:fips, :Day, nds]), value_name = vc, variable_name = :Place)
    groupby([nds, :Day, :Place])
    @combine($vc = mean($vc))
  end

  rally_mobility = Figure(resolution = (h, w));
  axr = nothing;

  for (r, e) in enumerate(unique(rallydat.Place))
    
    c1 = rallydat[!, :Place] .== e;
    datsub = rallydat[c1, :];

    servals, serlabs, sercols = makeseries_state(
      datsub,
      nds, :Day, vc, days
    );

    axr = Axis(
      rally_mobility[r, 1],
      title = e,
      xticks = collect(range(-days, stop = days; step = 2)),
      # xlabel = "Day",
      # ylabel = "State-level visits per million persons",
      xminorgridvisible = true,
      xminorticksvisible = true,
      xminorticks = IntervalsBetween(2)
    )

    ser = series!(
      axr,
      collect(range(-days, days; step = 1)),
      servals .* popfactor,
      labels = serlabs,
      markersize = 5,
      color = sercols
    )

  end

  lc = Legend(
    rally_mobility,
    axr,
    "Treatment Exposure",
    framevisible = false,
    nbanks = 2
  )

  hm_sublayout2 = GridLayout()
  rally_mobility[length(unique(rallydat.Place)) + 1, :] = hm_sublayout2

  hm_sublayout2[:v] = [lc]
    
  sideinfo = Label(
    rally_mobility[1:5, 0],
    "Exposure-level visits per 10K persons",
    rotation = pi/2
    )

  axr.attributes.xlabel = "Day"

  colsize!(rally_mobility.layout, 2, Relative(9/10));

  save(
    savepath * "rally_mob_pl" * fext,
    rally_mobility
  )  

  return rally_mobility
end

function protest_mob_pl(;
  datapath = "covid-19-data/data/",
  savepath = "supp out/",
  fext = ".png",
  days = 14,
  w = 1200,
  h = 800,
  popfactor = 10000
)

  vn = VariableNames();
  vc = Symbol("Visits Per Capita")
  vcstd = Symbol("Visits Per Capita (std)");

  mobvar = sort(
    [
      vn.res, vn.groc,
      vn.rec, vn.relig, vn.bar
    ]
  );
  
  dat = load_object(datapath * "cvd_dat.jld2");
  
  thresholdevent!(
    dat,
    :protest, vn.t, vn.id, 10, 40,
    500, 1000, :prsize
  );

  select!(dat, :date, vn.t, vn.id, mobvar..., :protest)

  pdat = similar(dat, 0);
  pdat[!, :eventnum] = Int[];
  pdat[!, :Day] = Int[];

  for (i, r) in enumerate(eachrow(@subset(dat, :protest .== 1)))
    ct1 = dat[!, vn.t] .>= r[vn.t] - days
    ct2 = dat[!, vn.t] .<= r[vn.t] + days
    cid = dat[!, vn.id] .== r[vn.id]
    pdi = dat[ct1 .& ct2 .& cid, :]
    pdi[!, :Day] = pdi[!, vn.t] .- r[vn.t]
    pdi[!, :eventnum] .= i
    append!(pdat, pdi)
  end

  pdat = @chain pdat begin
    select(Not([vn.t, vn.id, :protest, :eventnum, :date]))
    stack(Not(:Day), value_name = vc, variable_name = :Place)
    groupby([:Day, :Place])
    @combine(
      $vc = mean($vc .* popfactor),
      $vcstd = std($vc .* popfactor)
    )
  end

  blm_mobility = Figure(resolution = (h, w));
  axr = nothing;

  # (r, e) = collect(enumerate(unique(primdat.Place)))[1]
  for (r, e) in enumerate(sort(unique(pdat.Place)))
    
    datsub = pdat[pdat[!, :Place] .== e, :];

    axr = Axis(
      blm_mobility[r, 1],
      title = e,
      xticks = collect(range(-days, stop = days; step = 2)),
      # xlabel = "Day",
      # ylabel = "State-level visits per million persons",
      xminorgridvisible = true,
      xminorticksvisible = true,
      xminorticks = IntervalsBetween(2)
    )

    ts = collect(range(-days, days; step = 1))

    lne = lines!(
      axr,
      ts,
      datsub[!, vc],
      # labels = serlabs,
      markersize = 5,
      # color = sercols
    )

    band!(
      axr,
      ts,
      datsub[!, vc] + datsub[!, vcstd],
      datsub[!, vc] - datsub[!, vcstd]
    )

  end

  # lc = Legend(
  #   primary_mobility,
  #   axr,
  #   "State",
  #   framevisible = false,
  #   nbanks = 4
  # )

  # hm_sublayout2 = GridLayout()
  # primary_mobility[length(unique(primdat.Place)) + 1, :] = hm_sublayout2

  # hm_sublayout2[:v] = [lc]

  # bottominfo = Label(
  #   primary_mobility[6, :],
  #   "Day"
  #   )

  # colsize!(primary_mobility.layout, 1, Relative(9/10));
    
  sideinfo = Label(
    blm_mobility[1:5, 0],
    "State-level visits per 10K persons",
    rotation = pi/2
    )

  axr.attributes.xlabel = "Day"

  save(
    savepath * "blm_mob_pl" * fext,
    blm_mobility
  )

  return blm_mobility
end

function exposure_shift(;
  datapath = "covid-19-data/data/",
  savepath = "supp out/",
  fext = ".png",
  w = 1200,
  h = 800,
  treatment = :rallyday,
  maxexposure = 3,
  var = Symbol("Trump 2016 Vote Share")
)

  vn = VariableNames();

  dat = load_object(datapath * "cvd_dat.jld2");
  
  # setup the exposure information
  dat, stratassignments, labels, _ = countyspillover_assignment(
    dat, maxexposure, treatment, vn.t, vn.id
  );

  exvars = [
    Symbol(string(treatment) * "union"),
    [Symbol(string(treatment) * string(i)) for i in 1:maxexposure]...
  ];

  select!(
    dat,
    [
      vn.t, vn.id, var,
      exvars...
    ]
  )

  @subset!(dat, $(exvars[1]) .== 1)

  nds = Symbol("Treatment Exposure");
  dat[!, nds] .= fill("", nrow(dat));
  for r in eachrow(dat)
    r[nds] = labels[get(stratassignments, (r[vn.t], r[vn.id]), 0)]
  end

  select!(dat, [vn.t, vn.id, var, nds]);

  tes = sort(unique(dat[!, nds]));
  tescols = TSCSMethods.gen_colors(length(tes));

  # vals = @chain dat begin
  #   groupby(nds)
  #   @combine($(vn.ts16) = mean($(vn.ts16)))
  # end
  
  trump_shift = Figure(resolution = (w, h));

  ax = Axis(
    trump_shift[1, 1],
    # title = ndi,
    # xticks = collect(range(-14, stop = 14; step = 2)),
    xminorgridvisible = true,
    xminorticksvisible = true,
    # xminorticks = IntervalsBetween(2)
  )

  for (j, ndi) in enumerate(tes)

    c1 = dat[!, nds] .== ndi;
    tsndi = @views(dat[c1, var]);

    density!(
      ax,
      tsndi,
      # offset = -i/4,
      label = ndi,
      strokecolor = tescols[j],
      strokearound = true,
      strokewidth = 2,
      color = (tescols[j], 0.2),
      bandwidth = 0.1
    )

  end

  lc = Legend(
    trump_shift,
    ax,
    "Treatment Exposure",
    framevisible = false,
    nbanks = 4
  )

  hm_sublayout2 = GridLayout()
    trump_shift[2, :] = hm_sublayout2

  hm_sublayout2[:v] = [lc]

  rowsize!(trump_shift.layout, 1, Relative(9/10));
  colsize!(trump_shift.layout, 1, Relative(1));

  save(
    savepath * string(treatment) * "_shift_pl" * fext,
    trump_shift
  )

  return trump_shift
end

function protest_size_hists(
  datapath = "covid-19-data/data/",
  savepath = "supp out/",
  fext = ".png",
  w = 1200,
  h = 800
)

  vn = VariableNames();

  dat = load_object(datapath * "cvd_dat.jld2");
  
  thresholdevent!(
    dat,
    :protest, vn.t, vn.id, 10, 40,
    500, 1000, :prsize
  );

  select!(dat, :date, vn.t, vn.id, :prsize, :protest)
  rename!(dat, :prsize => vn.prsz);

  c1 = dat[!, :protest] .== 1;
  prdat = @views(dat[c1, :]);

  protest_sz = Figure(resolution = (w, h));

  ax1 = Axis(
    protest_sz[1, 1],
    title = "All protests",
    # xticks = collect(range(-14, stop = 14; step = 2)),
    # xlabel = "Day",
    # ylabel = "State-level visits per million persons",
    xminorgridvisible = true,
    xminorticksvisible = true,
    # xminorticks = IntervalsBetween(2)
  )

  hist!(
    protest_sz[1, 1],
    prdat[!, vn.prsz],
    bins = 100,
    color = :grey,
    strokewidth = 1,
    strokecolor = :black
  )

  vlines!(ax1, mean(prdat[!, vn.prsz]), color = :red)

  ax2 = Axis(
    protest_sz[2, 1],
    title = "Protests larger than 1000 individuals",
    # xticks = collect(range(-14, stop = 14; step = 2)),
    # xlabel = "Day",
    # ylabel = "State-level visits per million persons",
    xminorgridvisible = true,
    xminorticksvisible = true,
    # xminorticks = IntervalsBetween(2)
  )

  c2 = prdat[!, vn.prsz] .>= 1000;
  pr1K = @views(prdat[c2, vn.prsz]);

  hist!(
    protest_sz[2, 1],
    pr1K,
    bins = 100,
    color = :grey,
    strokewidth = 1,
    strokecolor = :black
  )

  vlines!(ax2, mean(pr1K), color = :red)

  save(
    savepath * "blm_sz_pl" * fext,
    protest_sz
  )

  return protest_sz
end
