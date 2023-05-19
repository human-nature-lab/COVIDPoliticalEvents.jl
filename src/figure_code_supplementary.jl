# figure_code_supplementary.jl

## Pre-trend plot

function pretrendfig(;
    models = [
        (
            "pre out/combined full_death_rte_excluded.jld2",
            "pre out/combined full_case_rte_excluded.jld2",
        ),
        (
            "pre out/primary full_death_rte_.jld2",
            "pre out/primary full_case_rte_.jld2"
        ),
        (
            "pre out/ga nomob_death_rte_.jld2",
            "pre out/ga nomob_case_rte_.jld2"
        ),
        (
            "pre out/ gub out nomob_death_rte_.jld2",
            "pre out/ gub out nomob_case_rte_.jld2"
        ),
        (
            "pre out/blm nomob_death_rte_.jld2",
            "pre out/blm nomob_case_rte_.jld2"
        ),
        (
            "pre out/trump nomob_death_rte_exposure.jld2",
            "pre out/trump nomob_case_rte_exposure.jld2"
        )
    ]
)

    ##
    ylabels = ("Death rate (per 10,000)", "Case rate (per 10,000)")
    xlabel = "Day"
    outcomecolors = (gen_colors(3)[3], gen_colors(3)[2])
    offsets = (0.15, 0.15)

    ##
    fg = Figure(
        backgroundcolor = :transparent,
        resolution = (1000, 1200),
        fontsize = 12 * 1
    );
    
    # overall
    m1, m2 = [load_object(x).refcalmodel for x in models[1]];
    @subset!(m1.results, :stratum .== 1)
    @subset!(m2.results, :stratum .== 1)
    panelA = fg[1, 1] = GridLayout()
    _figure!(panelA, m1, m2, xlabel, outcomecolors, offsets, ylabels)

    # primaries
    m1, m2 = [load_object(x).refcalmodel for x in models[2]];
    panelB = fg[2, 1] = GridLayout()
    _figure!(panelB, m1, m2, xlabel, outcomecolors, offsets, ylabels)

    # GA
    m1, m2 = [load_object(x).refcalmodel for x in models[3]];
    panelC = fg[3, 1] = GridLayout()
    _figure!(panelC, m1, m2, xlabel, outcomecolors, offsets, ylabels)

    # Gub
    m1, m2 = [load_object(x).refcalmodel for x in models[4]];
    panelD = fg[4, 1] = GridLayout()
    _figure!(panelD, m1, m2, xlabel, outcomecolors, offsets, ylabels)

    # BLM
    m1, m2 = [load_object(x).refcalmodel for x in models[5]];
    panelE = fg[5, 1] = GridLayout()
    _figure!(panelE, m1, m2, xlabel, outcomecolors, offsets, ylabels)

    # Trump 
    m1, m2 = [load_object(x).refcalmodel for x in models[6]];
    @subset!(m1.results, :stratum .== 1)
    @subset!(m2.results, :stratum .== 1)
    panelF = fg[6, 1] = GridLayout()
    _figure!(panelF, m1, m2, xlabel, outcomecolors, offsets, ylabels)

    for (label, layout) in zip(["a", "b", "c", "d", "e", "f"], [panelA, panelB, panelC, panelD, panelE, panelF])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    return fg
end

function _figure!(panelA, m1, m2, xlabel, outcomecolors, offsets, ylabels)

    ## setup
    @subset!(m1.results, :f .!= -1)
    @subset!(m2.results, :f .!= -1)
    fmin, fmax, fs, atts, lwr, upr = extract(m1, m2);
    intr = 5
    xt = collect(fmin:intr:fmax);


    ## deaths
    axm1 = Axis(
        panelA[1,1];
        xlabel = xlabel,
        ylabel = ylabels[1],
        xticks = xt,
        xminorticks = IntervalsBetween(intr),
        yticklabelcolor = outcomecolors[1]
    );

    # reference block
    vlines!(
        axm1,
        -1.49:0.001:-0.51;
        color = :grey, linestyle = nothing, linewidth = 0.2
    )

    # treatment block
    vlines!(
        axm1,
        -0.49:0.001:0.51;
        color = :honeydew, linestyle = nothing, linewidth = 0.2
    )

    rb1 = rangebars!(
        axm1,
        fs[1] .+ offsets[1],
        lwr[1], upr[1],
        color = outcomecolors[1];
        whiskerwidth = 0,
        label = ylabels[1]
    );

    sc1 = scatter!(
        axm1, fs[1] .+ offsets[1], atts[1], markersize = 5, color = :black
    );

    ## cases
    axm2 = Axis(
        panelA[1,1],
        ylabel = ylabels[2],
        xticks = xt,
        yticklabelcolor = outcomecolors[2],
        yaxisposition = :right
    );

    rb2 = rangebars!(
        axm2,
        fs[2] .- offsets[2],
        lwr[2], upr[2],
        color = outcomecolors[2];
        whiskerwidth = 0,
        label = "cases"
    );

    sc2 = scatter!(
        axm2, fs[2] .- offsets[2], atts[2], markersize = 5, color = :black
    );

    # design
    hidespines!(axm2)
    hidexdecorations!(axm2)

    xlims!(axm1, [-30.5, 9.5])
    xlims!(axm2, [-30.5, 9.5])

    yd, yc = get_ylims(m1, m2)

    yd = max(abs.(yd)...)
    yc = max(abs.(yc)...)

    ylims!(axm1, (-yd, yd))
    ylims!(axm2, (-yc, yc))

    # zero line
    hlines!(axm1, [0.0], color = :black, linestyle = :dash, linewidth = 0.8)

    hidedecorations!(axm1, ticks = false, ticklabels = false, label = false)
    hidedecorations!(axm2, ticks = false, ticklabels = false, label = false)

    # grey box lines
    vlx = collect(-30.5:9.5);

    vlines!(
        axm1, vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )

    axm1, axm2
end

##

function plot_si_set(
    fileset;
    sipth = "plotting/supplementary_figures/"
)

    for (e, si) in fileset
        println(e)
        X = load_object(e)
        tpe = typeof(X) == TSCSMethods.CICRecords
        if !tpe
            println("wrong type")
            continue
        end
        
        str = X.model.stratifier != Symbol("") ? string(X.model.stratifier) : ""
        scenario = X.model.title * " " * str;

        modelfigure(X, scenario)
    end
end

function modelfigure(X, scenario)

    vn = VariableNames()

    stratifier = X.model.stratifier;

    if stratifier == Symbol("")
        f = _modelfigure_nostrat(
            [X.model, X.refinedmodel, X.calmodel, X.refcalmodel]
        )

        return f
    else

        treatment = if occursin("ga", scenario)
            :gaspec
        elseif occursin("primary", scenario)
            :primary
        elseif occursin("protest", scenario)
            :protest
        elseif occursin("rally", scenario)
            :rallydayunion
        elseif occursin("gub", scenario)
        end

        if (treatment == :gaspec) & (stratifier == vn.tout)
            stratifier = :gaout
        end

        if stratifier == Symbol("Date of First Case to Primary")
            stratifier = Symbol("Date of First Case")
        end

        f = _modelfigure_strat([X.model, X.refinedmodel])
        fc = _modelfigure_strat([X.calmodel, X.refcalmodel])
        
        return [f, fc]
    end
end

function diagnostic(e; simple = false)
    X = load_object(e)
    str = X.model.stratifier != Symbol("") ? string(X.model.stratifier) : ""
    scenario = X.model.title * " " * str;

    return if !simple
        modelfigure(X, scenario)
    else
        modelfigure_simple(X; stratum = 1)
    end
end

function modelfigure(X, scenario)

    vn = VariableNames()

    stratifier = X.model.stratifier;

    if stratifier == Symbol("")
        f = _modelfigure_nostrat(
            [X.model, X.refinedmodel, X.calmodel, X.refcalmodel]
        )

        return f
    else

        treatment = if occursin("ga", scenario)
            :gaspec
        elseif occursin("primary", scenario)
            :primary
        elseif occursin("protest", scenario)
            :protest
        elseif occursin("rally", scenario)
            :rallydayunion
        elseif occursin("gub", scenario)
        end

        if (treatment == :gaspec) & (stratifier == vn.tout)
            stratifier = :gaout
        end

        if stratifier == Symbol("Date of First Case to Primary")
            stratifier = Symbol("Date of First Case")
        end

        f = _modelfigure_strat([X.model, X.refinedmodel])
        fc = _modelfigure_strat([X.calmodel, X.refcalmodel])
        
        # regular refined, caliper refined
        return [f, fc]
    end
end

function modelfigure_simple(X; stratum = nothing)

    if !isnothing(stratum)
        [@subset!(x.results, :stratum .== stratum) for x in [X.model, X.refinedmodel, X.calmodel, X.refcalmodel]]
        
        [
            select!(
                x.results, Not(:stratum)) for x in [X.model, X.refinedmodel, X.calmodel, X.refcalmodel]
        ]

        @reset X.model.balances = X.model.balances[stratum]
        @reset X.refinedmodel.balances = X.refinedmodel.balances[stratum]
        @reset X.calmodel.balances = X.calmodel.balances[stratum]
        @reset X.refcalmodel.balances = X.refcalmodel.balances[stratum]
    end

    f = _modelfigure_nostrat(
        [X.model, X.refinedmodel, X.calmodel, X.refcalmodel]
    )
    
    return f
end

# plot a whole model result, in the SI
function _modelfigure_nostrat(models)

    f = Figure(
        backgroundcolor = :transparent,
        resolution = (800, 1000)
    );

    G = f[1:5, 1] = GridLayout();
    ga = G[1,1] = GridLayout();
    gb = G[2,1] = GridLayout();
    gc = G[3,1] = GridLayout();
    gd = G[4,1] = GridLayout();
    gleg = G[5,1] = GridLayout();

    layoutsplit(x) = (x[1,1], x[1,2]); # rhs: att, lhs: cb

    subpanels = [
        layoutsplit(ga),
        layoutsplit(gb),
        layoutsplit(gc),
        layoutsplit(gd)
    ];

    ylabelatt = if models[1].outcome == :case_rte
        "Case rate (per 10K pers.)"
    elseif models[1].outcome == :death_rte
        "Death rate (per 10K pers.)"
    elseif models[1].outcome == :deaths
        "Deaths"
    elseif models[1].outcome == :cases
        "Cases"
    else "ATT"
    end

    axcb = [];
    for (gi12, mi, cnt) in zip(subpanels, models, 1:4)
        if cnt == 1
            xlabel = "Day"
            ylabelatt = ylabelatt
            ylabelcb = "Balance score"
        else
            xlabel = ""
            ylabelatt = ""
            ylabelcb = ""
        end
        axs, rbs, scs = add_att_axis!(
            gi12[1], mi;
            xlabel = xlabel, ylabel = ylabelatt
        )
        axcb, ser = add_cb!(
            gi12[2], mi;
            xlabel = xlabel, ylabel = ylabelcb
        )

        for i in eachindex(axs)
            axs[i].xgridvisible = false
            axs[i].ygridvisible = false
        end

        axcb.xgridvisible = false
        axcb.ygridvisible = false
    end

    legcb = Legend(
        f[5,:], axcb, "Covariates",
        nbanks = 3;
        framevisible = false,
        labelsize = 12,
        tellwidth = false,
        tellheight = false,
    )

    for (label, layout) in zip(["a", "b", "c", "d"], [ga, gb, gc, gd])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    return f
end

# plot a whole model result, in the SI
function _modelfigure_strat(models)

    f = Figure(
        backgroundcolor = :transparent,
        resolution = (1000*1.5, 900*1.5)
    );

    S = unique(models[1].results.stratum)

    G = f[1:(length(S)+1), 1:2] = GridLayout();
    G1 = f[1:4, 1] = GridLayout();
    ga = G[1,1] = GridLayout();
    gb = G[2,1] = GridLayout();
    gc = G[3,1] = GridLayout();
    gd = G[4,1] = GridLayout();

    gleg = G[(length(S)+1),1:2];

    G2 = f[1:(length(S)+1), 2] = GridLayout();
    ga2 = G[1,2] = GridLayout();
    gb2 = G[2,2] = GridLayout();
    gc2 = G[3,2] = GridLayout();
    gd2 = G[4,2] = GridLayout();
    
    layoutsplit(x) = (x[1,1], x[1,2]); # rhs: att, lhs: cb
    
    subpanels = [
        layoutsplit(ga),
        layoutsplit(gb),
        layoutsplit(gc),
        layoutsplit(gd)
    ];

    subpanels2 = [
        layoutsplit(ga2),
        layoutsplit(gb2),
        layoutsplit(gc2),
        layoutsplit(gd2)
    ];
        
    if length(S) == 5
        ge = G[5,1] = GridLayout();
        push!(subpanels, layoutsplit(ge))

        ge2 = G[5,2] = GridLayout();
        push!(subpanels2, layoutsplit(ge2))
    end

    ylabelatt = if models[1].outcome == :case_rte
        "Case rate (per 10K pers.)"
    elseif models[1].outcome == :death_rte
        "Death rate (per 10K pers.)"
    else "ATT"
    end

    for (gi12, s, cnt) in zip(subpanels, S, 1:length(S))
        if cnt == 1
            xlabel = "Day"
            ylabelatt = ylabelatt
            ylabelcb = "Balance score"
        else
            xlabel = ""
            ylabelatt = ""
            ylabelcb = ""
        end
        resi = @subset(models[1].results, :stratum .== s)
        select!(resi, Not(:stratum))
        label = !isnothing(models[1].labels) ? models[1].labels[s] : nothing
        axs, rbs, scs = add_att_axis!(
            gi12[1], resi,models[1].outcome;
            xlabel = xlabel, ylabel = ylabelatt, label = label,
        )
        cbi = models[1].balances[s];
        axcb, ser = add_cb!(
            gi12[2], cbi;
            xlabel = xlabel, ylabel = ylabelcb
        )

        for i in eachindex(axs)
            axs[i].xgridvisible = false
            axs[i].ygridvisible = false
        end

        axcb.xgridvisible = false
        axcb.ygridvisible = false
    end

    axcb = [];
    for (gi212, s, cnt) in zip(subpanels2, S, 1:length(S))
        xlabel = ""
        ylabelatt = ""
        ylabelcb = ""
        resi = @subset(models[2].results, :stratum .== s)
        axs, rbs, scs = add_att_axis!(
            gi212[1], resi,models[1].outcome;
            xlabel = xlabel, ylabel = ylabelatt
        )
        cbi = models[2].balances[s];
        axcb, ser = add_cb!(
            gi212[2], cbi;
            xlabel = xlabel, ylabel = ylabelcb
        )

        for i in eachindex(axs)
            axs[i].xgridvisible = false
            axs[i].ygridvisible = false
        end

        axcb.xgridvisible = false
        axcb.ygridvisible = false
    end

    legcb = Legend(
        f[(length(S)+2), :], axcb, "Covariates",
        nbanks = 6;
        framevisible = false,
        labelsize = 12,
        tellwidth = false,
        tellheight = false,
        margin = (-130, 30, 30, 30),
        orientation = :horizontal
    )

    for (label, layout) in zip(["a", "b"], [G1, G2])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    return f
end

function rally_ts_x_exposure_fig(X, scenario)

    @unpack model, refinedmodel, calmodel, refcalmodel, obsinfo, matchinfo = X;
    @unpack stratifier, title = model;
    
    S = unique(model.results.stratum)

    ylabelatt = if model.outcome == :case_rte
        "Case rate (per 10K pers.)"
    elseif model.outcome == :death_rte
        "Death rate (per 10K pers.)"
    else "ATT"
    end

    fpos = [collect(Iterators.product(1:4,1:4))[:, [1,3]], collect(Iterators.product(1:4,1:4))[:, [2,4]]]

    Figs = Vector{Figure}(undef, 4)

    axcb = []

    for (o, m) in enumerate([model, refinedmodel, calmodel, refcalmodel])
  
        f = Figure(
            backgroundcolor = :transparent,
            resolution = (1000*1.5, 900*1.5)
            );
            
        G = f[1:4, 1:4] = GridLayout();
        gleg = f[5,:]
        Gx = f[1:5, 1:4] = GridLayout();

        for (s, k) in zip(S, 1:length(S))
            
            if k == 1
                xlabel = "Day"
                ylabelatt = ylabelatt
                ylabelcb = "Balance score"
            else
                xlabel = ""
                ylabelatt = ""
                ylabelcb = ""
            end

            resi = @subset(m.results, :stratum .== s)
            select!(resi, Not(:stratum))
            label = !isnothing(m.labels) ? m.labels[s] : nothing
            
            fpk = fpos[1][k]; fpk2 = fpos[2][k];

            axs, rbs, scs = add_att_axis!(
                f[fpk...], resi, model.outcome;
                xlabel = xlabel, ylabel = ylabelatt, label = label,
            )

            for i in eachindex(axs)
                axs[i].xgridvisible = false
                axs[i].ygridvisible = false
            end
            
            cbi = m.balances[s];

            axcb, ser = add_cb!(
                f[fpk2...], cbi;
                xlabel = xlabel, ylabel = ylabelcb
            )

            axcb.xgridvisible = false
            axcb.ygridvisible = false
        end

        legcb = Legend(
            f[4+1, :], axcb, "Covariates",
            nbanks = 6;
            framevisible = false,
            labelsize = 12,
            tellwidth = false,
            tellheight = false,
            margin = (130, 30, 100, 30),
        )

        Figs[o] = f
    end

    return Figs
end

## non outcome plots

function testingfig(
    dat_store;
    p1 = "combined out/grace combined out/combined full_death_rte_excluded.jld2"
)

    # COUNTY
    # tst = CSV.read(download("https://raw.githubusercontent.com/govex/COVID-19/master/data_tables/testing_data/county_time_series_covid19_US.csv"), DataFrame)
    # data only available after 2021-08-01

    ## process testing data

    ste_link = "https://raw.githubusercontent.com/govex/COVID-19/master/data_tables/testing_data/time_series_covid19_US.csv" # state level data
    ste = CSV.read(
        download(ste_link),
        DataFrame
    )

    begin
        dates = Vector{Date}(undef, nrow(ste));
        for i in 1:nrow(ste)
            dates[i] = Date(ste.date[i], dateformat"m/d/y")
        end
        ste.date = dates;
        ste[!, :running] = [Dates.value(s - Date("2020-03-01")) for s in ste.date];
    end

    sort!(ste, [:state, :running])
    select!(ste, Not(:date))

    ste[!, :positivity] = ste[!, :cases_conf_probable] .* inv.(ste[!, :tests_combined_total])

    testvars = [
        :cases_conf_probable, :cases_confirmed, :cases_probable,
        :tests_combined_total #, :positivity
    ];

    @subset(ste, :state .== "MA")

    ## model information

    recordset = load_object(p1)

    model = recordset.model;

    obs = model.observations[model.strata .== 1];
    obs = DataFrame(:running => [ob[1] for ob in obs], :fips => [ob[2] for ob in obs]);

    obdat = innerjoin(
        obs, recordset.matchinfo,
        on = [:running => :timetreated, :fips => :treatedunit]
    );

    obdat[!, :period] = obdat.f .+ obdat.f
    select!(obdat, [:fips, :running, :period, :f])

    obdat = leftjoin(obdat, dat_store; on = [:period => :running, :fips]);
    sort!(obdat, [:running, :fips, :period])

    obdat = leftjoin(
        obdat,
        ste,
        on = [:period => :running, Symbol("State Abbr.") => :state]
    )

    pctΔ(y1, y2) = (y2 .- y1) .* inv.(y1) .* 100

    # calcualte percentage difference
    begin
        gdf = groupby(obdat, [:running, :fips])
        for g in gdf
            for v in testvars
                fst = g[1, v] # min for cumulative, not nec. for positivity
                g[!, v] = pctΔ(fst, g[!, v])
            end
        end
    end

    findfirst(([keys(gdf)[i][1] for i in 1:length(gdf)] .== 72) .& ([keys(gdf)[i][2] for i in 1:length(gdf)] .== 31005) .== true)

    gdf[240][!, [:fips, :running, :period, :f, testvars...]]

    ob3 = @chain obdat begin
        groupby([:f])
        combine([v => mean∘skipmissing => v for v in [testvars..., :positivity]])
    end

    for v in testvars[end-1:end]
        vn = Symbol(string(v) * "_diff")
        ob3[!, vn] = Vector{Union{Float64, Missing}}(missing, nrow(ob3))
        ob3[2:end, vn] = diff(ob3[!, v])
    end

    ob3


    fg = begin
        f = Figure()
        ax1 = Axis(
            f[1,1];
            ylabel = "Pct. change in total tests",
            xlabel = "Day",
            yticklabelcolor = :cornflowerblue
        )
        ax2 = Axis(
            f[1,1];
            ylabel = "Positivity",
            yticklabelcolor = :goldenrod1
        )

        lines!(
            ax1, ob3.f, ob3.tests_combined_total;
            color = :cornflowerblue,
            label = "Total tests"
        )
        lines!(
            ax2, ob3.f, ob3.positivity .* 100;
            color = :goldenrod1,
            label = "Positivity"
        )
        
        ax2.yaxisposition = :right
        ax2.yticklabelalign = (:left, :center)
        ax2.xticklabelsvisible = false
        ax2.xticklabelsvisible = false
        ax2.xlabelvisible = false

        hidexdecorations!(
            ax1, grid = true, ticks = false, ticklabels = false, label = false
        )
        hidexdecorations!(
            ax2, grid = true, ticks = false, ticklabels = false, label = false
        )
        hideydecorations!(
            ax1, grid = true, ticks = false, ticklabels = false, label = false
        )
        hideydecorations!(
            ax2, grid = true, ticks = false, ticklabels = false, label = false
        )

        linkxaxes!(ax1, ax2)

        f
    end

    return fg
end

### supplemental_plots.jl

# ga_turnout.jl

"""
get and handle the turnout data for the GA special election
"""
function ga_turnout(dat; datapath = "covid-19-data/data/")

    pdict = Dict(dat.fips .=> dat.pop);

    vn = VariableNames()

    ge = CSV.read(
        datapath * "ga_election_results_clean.csv", 
        DataFrame
    );

    select!(ge, Not(Symbol("Total Votes")));

    urlb = HTTP.get(
    "https://raw.githubusercontent.com/kjhealy/fips-codes/master/state_and_county_fips_master.csv"
    ).body;

    ftab = CSV.read(urlb, DataFrame);
    ftab = @subset(ftab, :state .== "GA");

    ftab = @eachrow ftab begin
        @newcol :county::Vector{String}
        :county = replace(:name, " County" => "")
    end;

    select!(ftab, [:fips, :county]);

    ge = leftjoin(ge, ftab, on = :County => :county);

    ge[!, :pop] .= [get(pdict, e, 0) for e in ge.fips]

    ge.fips = convert(Vector{Int64}, ge.fips);

    select!(ge, Not(:County))
    ge[!, vn.tout] = ge.day_of .* inv.(ge.pop);

    return ge
end;

function gub_turnout(dat; njdatapath = "covid-19-data/data/")

  urlb = HTTP.get(
    "https://apps.elections.virginia.gov/SBE_CSV/ELECTIONS/ELECTIONTURNOUT/Turnout-2021%20November%20General%20.csv"
  ).body;

  vadat = CSV.read(urlb, DataFrame);

  vadat = @chain vadat begin
    groupby(:locality)
    combine(:in_person_ballots => sum => :in_person_ballots)
    @transform(:locality = lowercase.(:locality))
  end
  rename!(vadat, :in_person_ballots => :va_in_person)

  njdat = CSV.read(njdatapath * "nj_turnout.csv", DataFrame);

  njdat = @transform(
    @transform(
      njdat,
      :County = lowercase.(:County),
      :in_person = :total_ballots - :ballots_by_mail
    ),
    :County = :County .* " county"
  );

  select!(njdat, :County, :in_person)
  rename!(njdat, :in_person => :nj_in_person)

  fpsdat = HTTP.get(
    "https://raw.githubusercontent.com/kjhealy/fips-codes/master/state_and_county_fips_master.csv"
  ).body;

  fpsdat = CSV.read(fpsdat, DataFrame);
  njfpsdat = @chain fpsdat begin
    @subset(:state .== "NJ")
    @transform(:name = lowercase.(:name))
  end

  vafpsdat = @chain fpsdat begin
    @subset(:state .== "VA")
    @transform(:name = lowercase.(:name))
  end

  njdat = leftjoin(njdat, njfpsdat, on = :County => :name)
  njdat = disallowmissing(njdat);

  vadat = leftjoin(vadat, vafpsdat, on = :locality => :name)

  vadat.fips[vadat.locality .== "king & queen county"] = [51097]
  vadat.state[vadat.locality .== "king & queen county"] = ["VA"]

  vadat = disallowmissing(vadat);

  rename!(njdat, :nj_in_person => :in_person)
  rename!(vadat, :va_in_person => :in_person)
  
  select!(njdat, :fips, :in_person, :state)
  select!(vadat, :fips, :in_person, :state)
  
  gubturnout = vcat(njdat, vadat)

  popd = Dict(dat.fips .=> dat.pop);
  gubturnout[!, :pop] .= [get(popd, e, 0) for e in gubturnout.fips]

  gubturnout[!, Symbol("In-person Turnout Rate")] = gubturnout.in_person .* inv.(gubturnout.pop)

  return gubturnout
end

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
    turnoutplot(dat)

Plot the in person turnout rate for GA, primaries, NJ, VA.
"""
function turnoutplot(pout, gout, njout, vaout)

    L = -50:-1

    ##

    tout_pl = Figure();

    l1 = tout_pl[1, 1] = GridLayout()
    l2 = tout_pl[1, 2] = GridLayout()
    l3 = tout_pl[2, 1] = GridLayout()
    l4 = tout_pl[2, 2] = GridLayout()

    ax1 = Axis(
        l1[1, 1],
        xgridvisible = false,
        ygridvisible = false,
    )

    hist!(
        ax1,
        pout,
        color = :grey,
        strokewidth = 1,
        strokecolor = :black
    )

    vlines!(ax1, mean(pout), color = :red)

    ax2 = Axis(
        l2[1, 1],
        xgridvisible = false,
        ygridvisible = false,
    )

    hist!(
        ax2,
        gout,
        color = :grey,
        strokewidth = 1,
        strokecolor = :black
    )

    vlines!(ax2, mean(gout), color = :red)

    ax3 = Axis(
        l3[1, 1],
        xgridvisible = false,
        ygridvisible = false,
    )

    hist!(
        ax3,
        njout,
        color = :grey,
        strokewidth = 1,
        strokecolor = :black
    )

    vlines!(ax3, mean(njout), color = :red)

    ax4 = Axis(
        l4[1, 1],
        xgridvisible = false,
        ygridvisible = false,
    )

    hist!(
        ax4,
        vaout,
        color = :grey,
        strokewidth = 1,
        strokecolor = :black
    )

    vlines!(ax4, mean(vaout), color = :red)

    for (label, layout) in zip(["a", "b", "c", "d"], [l1, l2, l3, l4])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    return tout_pl
end

function rescheduled_pl(dat)
    
    prior_days = 14
    dm = Symbol("death_rte")
    cm = Symbol("case_rte")

    vn = VariableNames();

    primary = make_primary_info(; dat = dat);

    resched = @subset(
        primary,
        :type .== "in-person", :reschedule .== "Yes",
        :cancelled .== "No"
    );

    # number of counties present in each state
    @eachrow! resched begin
        @newcol :countynum::Vector{Int64}
        :countynum = length(
            unique(dat[!, vn.id][dat[!, vn.abbr] .== cols(vn.abbr)])
        )
    end

    places = collect(Iterators.product(1:3, 1:4));

    ## Figure
    f = Figure(resolution = (800, 1000))

    pl_dm = f[1, 1] = GridLayout();
    pl_cm = f[2, 1] = GridLayout(); 

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
            xgridvisible = false,
            ygridvisible = false,
            xminorticksvisible = true,
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
            xgridvisible = false,
            ygridvisible = false,
            xminorticksvisible = true,
        )

        hist!(
            pl_cm[(places[i])...],
            datsched[!, cmd],
            color = pal[vn.ccr],
            strokewidth = 1,
            strokecolor = :black
        )

        vlines!(ax_cm, mean(datsched[!, cmd]), color = :red)

        for (label, layout) in zip(["a", "b"], [pl_dm, pl_cm])
            Label(layout[1, 1, TopLeft()], label,
                fontsize = 26,
                padding = (0, 5, 5, 0),
                halign = :right
            )
        end

    end

    return f
end

function primary_mob_pl(
    dat; 
    days = 14,
    w = 1200,
    h = 800,
    popfactor = 10000
)

  vc = Symbol("Visits Per Capita");
  vn = VariableNames();
  mobvar = sort(
    [
      vn.res, vn.groc,
      vn.rec, vn.relig, vn.bar
    ]
  );

  primary = make_primary_info(; dat = dat, firstdate = Date("2020-03-17"));

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

  select!(primdat, Not([:pop]))

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

  colsize!(primary_mobility.layout, 1, Relative(9/10));
    
  sideinfo = Label(
    primary_mobility[1:5, 0],
    "State-level visits per 10K persons",
    rotation = pi/2
    )

  axr.xlabel = "Day"

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
  sercols = gen_colors(length(serlabs)); 

  return servals, serlabs, sercols
end

function ga_mob_pl(
    dat;
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

  for (r, e) in enumerate(sort(unique(gadat.Place)))
    
    datsub = gadat[gadat[!, :Place] .== e, :];

    axr = Axis(
      ga_mobility[r, 1],
      title = e,
      xticks = collect(range(-days, stop = days; step = 2)),
      xminorgridvisible = true,
      xminorticksvisible = true,
      xminorticks = IntervalsBetween(2)
    )

    ts = collect(range(-days, days; step = 1))

    lne = lines!(
      axr,
      ts,
      datsub[!, vc],
      markersize = 5,
    )

    band!(
      axr,
      ts,
      datsub[!, vc] + datsub[!, vcstd],
      datsub[!, vc] - datsub[!, vcstd]
    )

  end
    
  sideinfo = Label(
    ga_mobility[1:5, 0],
    "State-level visits per 10K persons",
    rotation = pi/2
    )

  axr.xlabel = "Day"

  return ga_mobility
end

function rally_mob_pl(
  dat;
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

  axr = []
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

  axr.xlabel = "Day"

  colsize!(rally_mobility.layout, 2, Relative(9/10));

  return rally_mobility
end

function protest_mob_pl(;
  datapath = "covid-19-data/data/",
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

  for (r, e) in enumerate(sort(unique(pdat.Place)))
    
    datsub = pdat[pdat[!, :Place] .== e, :];

    axr = Axis(
      blm_mobility[r, 1],
      title = e,
      xticks = collect(range(-days, stop = days; step = 2)),
      xminorgridvisible = true,
      xminorticksvisible = true,
      xminorticks = IntervalsBetween(2)
    )

    ts = collect(range(-days, days; step = 1))

    lne = lines!(
      axr,
      ts,
      datsub[!, vc],
      markersize = 5
    )

    band!(
      axr,
      ts,
      datsub[!, vc] + datsub[!, vcstd],
      datsub[!, vc] - datsub[!, vcstd]
    )

  end

  sideinfo = Label(
    blm_mobility[1:5, 0],
    "State-level visits per 10K persons",
    rotation = pi/2
    )

  axr.xlabel = "Day"

  return blm_mobility
end

function exposure_shift(
    dat;
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
  tescols = gen_colors(length(tes));
  
  trump_shift = Figure(resolution = (w, h));

  ax = Axis(
    trump_shift[1, 1],
    xgridvisible = false,
    ygridvisible = false,
  )

  for (j, ndi) in enumerate(tes)

    c1 = dat[!, nds] .== ndi;
    tsndi = @views(dat[c1, var]);

    density!(
      ax,
      tsndi,
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

  return trump_shift
end

function protest_size_hists(
  dat;
  w = 1200,
  h = 800
)

  vn = VariableNames();
  
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
    ygridvisible = false,
    xgridvisible = false,
    xminorticksvisible = true,
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
    ygridvisible = false,
    xgridvisible = false,
    xminorticksvisible = true
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

  return protest_sz
end

## robustness

## inner functions

function add_att_axis!(
    g, m;
    lwrlab = Symbol("2.5%"),
    uprlab = Symbol("97.5%"),
    intr = 5,
    xlabel = "Day",
    ylabel = "Death rate (per 10,000 persons)"
)

    c1 = "stratum" .∈ Ref(names(m.results))
    
    c3 = if c1
        length(m.labels) > 1
    else
        false
    end

    res = if c1 & !c3
        @subset(m.results, :stratum .== 1)
    else
        m.results
    end

    c2 = if c1
        length(unique(res.stratum)) > 1
    else
        false
    end
    
    fs = res[!, :f]; atts = res[!, :att];
    fmin, fmax = extrema(fs);
    lwr = res[!, lwrlab]; upr = res[!, uprlab];

    varcolors = colorvariables()
    outcome = m.outcome
    outcomecolor = varcolors[outcome]

    axs = [];
    rbs = [];
    scs = [];
    
    if c1 & c2
        strata = sort(unique(res.stratum));
        labels = length(m.labels) == 0 ? nothing : m.labels;
        for (i, s) in enumerate(strata)
            cs = res.stratum .== s;
            a, b = isodd(i) ? (i, 1) : (i-1, 2)
            label = !isnothing(labels) ? labels[s] : nothing;

            if i < length(strata)-2
                xl = "Day"; yl = "";
            else
                xl = "Day"; yl = ""
            end

            axmain, rb, sc = _add_att_axis!(
                g[i, 1],
                fs[cs], atts[cs], lwr[cs], upr[cs],
                fmin, fmax, intr,
                xl, yl,outcomecolor;
                label = label
            );
            push!(axs, axmain)
            push!(rbs, rb)
            push!(scs, sc)
        end
    else
        axmain, rb, sc = _add_att_axis!(
            g[1,1], fs, atts, lwr, upr, fmin, fmax, intr,
            xlabel, ylabel, outcomecolor
        );
        push!(axs, axmain)
        push!(rbs, rb)
        push!(scs, sc)
    end
    
    return axs, rbs, scs
end

function _add_att_axis!(
    fposition, fs, atts, lwr, upr, fmin, fmax, intr,
    xlabel, ylabel,outcomecolor;
    label = nothing,
)

    xt = collect(fmin:intr:fmax);

    if isnothing(label)
        axmain = Axis(
            fposition,
            xlabel = xlabel, ylabel = ylabel,
            xticks = xt,
            xminorgridvisible = true,
            xminorticksvisible = true,
            xminorticks = IntervalsBetween(intr)
        );
    else
        axmain = Axis(
            fposition,
            xlabel = xlabel, ylabel = ylabel,
            title = label,
            xticks = xt,
            xminorgridvisible = true,
            xminorticksvisible = true,
            xminorticks = IntervalsBetween(intr)
        );
    end

    rb = rangebars!(
        axmain,
        fs,
        lwr, upr,
        color = outcomecolor;
        whiskerwidth = 10,
        label = ylabel
    );

    sc = scatter!(axmain, fs, atts, markersize = 5, color = :black);

    hlines!(axmain, [0.0], color = :black, linestyle = :dash, linewidth = 1)

    # label_tt = Label(
    #     gb[1,1],
    #     "test", # labels[s],
    #     # halign = :center
    # )
    #   f[f[1,2], Top()] = label_tt

    # supertitle = f2[0, :] = Label(
    #     f2,
    #     txt2,
    #     color = (:black, 0.25)
    # )

    return axmain, rb, sc
end

function add_cb2!(
    fposition, m;
    matchwindow = -30:1:-1, intr = 5,
    xlabel = "Day", ylabel = "Balance score", title = ""
)

    cb = m.grandbalances;
    
    xtcb = collect(
        range(
            minimum(matchwindow), stop = maximum(matchwindow);
            step = intr
        )
    );

    axcb = Axis(
        fposition,
        title = title,
        xlabel = xlabel,
        ylabel = ylabel,
        xticks = xtcb,
        xminorgridvisible = false,
        # xminorticksvisible = false,
        xminorticks = IntervalsBetween(intr)
    );

    covariates = sort([k for k in keys(cb)]);

    # covals = Vector{Vector{Float64}}(undef, length(covariates));
    covals = Matrix{Float64}(
        undef, length(covariates), length(matchwindow)
    );

    for (c, covar) in enumerate(covariates)
        vals = cb[covar];
        if length(vals) == 1
            covals[c, :] = fill(vals, length(matchwindow))
        else
            covals[c, :] = vals;
        end
    end

    vn = VariableNames();
    variablecolors = colorvariables();

    ser = series!(
        axcb,
        collect(matchwindow),
        covals,
        labels = [string(covar) for covar in covariates],
        markersize = 5,
        color = [variablecolors[covar] for covar in covariates]
    );

    ylims!(axcb, -0.15, 0.15)

    hlines!(axcb, [-0.1, 0.1], color = :grey50, linestyle = :dash, linewidth = 1)
        
    return axcb, ser
end

function add_cb2!(
    fposition, cb::Dict;
    matchwindow = -30:1:-1, intr = 5,
    xlabel = "Day", ylabel = "Balance score", title = ""
)
    
        xtcb = collect(
            range(
                minimum(matchwindow), stop = maximum(matchwindow);
                step = intr
            )
        );
    
        axcb = Axis(
            fposition,
            title = title,
            xlabel = xlabel,
            ylabel = ylabel,
            xticks = xtcb,
            xminorgridvisible = true,
            xminorticksvisible = true,
            xminorticks = IntervalsBetween(intr)
        );
    
        covariates = sort([k for k in keys(cb)]);
    
        # covals = Vector{Vector{Float64}}(undef, length(covariates));
        covals = Matrix{Float64}(
            undef, length(covariates), length(matchwindow)
        );
    
        for (c, covar) in enumerate(covariates)
            vals = cb[covar];
            if length(vals) == 1
                covals[c, :] = fill(vals, length(matchwindow))
            else
                covals[c, :] = vals;
            end
        end

        vn = VariableNames();
    
        variablecolors = colorvariables()
    
        ser = series!(
            axcb,
            collect(matchwindow),
            covals,
            labels = [string(covar) for covar in covariates],
            markersize = 5,
            color = [variablecolors[covar] for covar in covariates]
        );

        ylims!(axcb, -0.15, 0.15)

        hlines!(axcb, [-0.1, 0.1], color = :grey50, linestyle = :dash, linewidth = 1)
        
    return axcb, ser
end

function add_cbs_axis!(g, gb, m; labels = nothing)

    axs = [];
    lns = [];

    c1 = typeof(m) .∈ Ref([CICStratified, CaliperCICStratified, RefinedCaliperCICStratified])
    c2 = if c1
        length(m.labels) > 0
    else false
    end

    if c1 & c2
        strata = sort(unique(keys(gb)));
        # labels = nothing
        for (i, s) in enumerate(strata)
            #a, b = isodd(i) ? (i, 1) : (i-1, 2)

            # yl = i == 1 ? "Balance score" : ""
            yl = ""

            lab = !isnothing(labels) ? labels[s] : ""

            axcb, ln = add_cb2!(
                g[i, 1], gb[s];
                matchwindow = -30:1:-1, intr = 5,
                xlabel = "Day", ylabel = yl, title = lab
            )

            push!(axs, axcb)
            push!(lns, ln)
        end
    else
        axcb, ln = add_cb2!(
            g[1, 1], gb;
            matchwindow = -30:1:-1, intr = 5,
            xlabel = "Day", ylabel = "Balance score"
        )
        push!(axs, axcb)
        push!(lns, ln)
    end
    
    return axs, lns
end

function covrob_plot(m)

    c1 = typeof(m) .∈ Ref([CICStratified, CaliperCICStratified, RefinedCaliperCICStratified])
    c2 = if c1
        length(m.labels) > 0
    else false
    end

    q = c1 & c2 ? 1200 : 300

    f = Figure(
        backgroundcolor = :transparent,
        resolution = (800, q)
    );

    fa = f[:, 1] = GridLayout();
    fb = f[:, 2] = GridLayout();
    fc = f[2,:] = GridLayout();

    fd = f[1, 1:2] = GridLayout();

    ylabelatt = assign_ylabel(m.outcome)
    xlabel = "Day"
    ylabelcb = "Balance score"

    # varcolors = colorvariables()
    # outcomecolor = varcolors[m.outcome]

    axs, rbs, scs = add_att_axis!(
        fa, m;
        xlabel = xlabel, ylabel = ylabelatt
    )

    # axcb, ser = add_cb!(
    #     fb[1,1], m;
    #     xlabel = xlabel, ylabel = ylabelcb
    # )
    
    labs = (c1 & c2) ? m.labels : nothing

    gb = if c1 & !c2
        m.grandbalances[1]
    else
        m.grandbalances
    end

    axcb, lns =  if c1 & c2
        add_cbs_axis!(fb, gb, m; labels = labs)
    else
        axcb, ln = add_cb2!(
            fb[1,1], gb;
            matchwindow = -30:1:-1, intr = 5,
            xlabel = "Day", ylabel = "Balance score"
        )
    end

    axcb1 = if c1 & c2
        axcb[1]
    else
        axcb
    end

    legcb = Legend(
        fc[1,1], axcb1, "Covariates",
        nbanks = 4;
        framevisible = false,
        labelsize = 12,
        # position = :lt,
        tellwidth = false,
        tellheight = false,
        # margin = (30, 30, 300, 30),
        # halign = ha, valign = va,
        # orientation = :horizontal
    )

    for (label, layout) in zip(["a", "b"], [fa, fb])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    colsize!(fa, 1, Auto(100))
    rowsize!(f.layout, 1, Auto(1))
    rowsize!(f.layout, 2, Auto(.5))
    return f
end

# treatment plot

function assigneventcolor(x)
    clrs = Makie.wong_colors()
    return if x == "Primary"
        clrs[1]
    elseif x == "GA Special"
        clrs[5]
    elseif x == "Rally"
        clrs[2]
    elseif x == "Gubernatorial"
        clrs[3]
    elseif x == "Protest"
        clrs[4]
    end
end

function sizeprocess(
    dat;
    njdat = "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/nj_turnout.csv",
    vadat = "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/va_turnout.csv",
    trumpdat = "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/trump_rallies.csv"

)

    trt = subset(
        dat,
        :political => ByRow(==(1)),
        [a => ByRow(==(0)) for a in [:rallyday1, :rallyday2, :rallyday3]],
        # :size => ByRow(>(0)),
        skipmissing = true
    )
        
    tn = names(trt)

    tr = Symbol("In-person Turnout Rate");
    gatr = Symbol("In-Person Turnout Rate (GA)");

    trt.prsize
    trt[!, tr] .* trt.pop
    trt[!, gatr] .* trt.pop

    trt[!, :size] = Vector{Union{Float64, Missing}}(missing, nrow(trt));
    # trt[!, :event] = Vector{Union{String, Missing}}(missing, nrow(trt));
    trt[!, :event] = Vector{String}(undef, nrow(trt));

    events = [:primary, :rallyday0, :gub, :gaspecial, :protest]

    eventnames = Dict(
        :primary => "Primary", :rallyday0 => "Rally",
        :gub => "Gubernatorial", :gaspecial => "GA Special",
        :protest => "Protest"
    );

    eventsize = Dict(
        :primary => tr,
        # :rallyday0 => "Rally",
        # :gub => "Gubernatorial",
        :gaspecial => gatr,
        :protest => :prsize
    )

    let
        for rw in eachrow(trt)
            for vbl in events
                if rw[vbl] == 1
                    rw[:event] = eventnames[vbl]
                    rw[:size] = if (vbl == :primary) | (vbl == :gaspecial)
                        round(rw[get(eventsize, vbl, missing)] * rw[:pop]; digits = 0)
                    else
                        if !ismissing(get(eventsize, vbl, missing))
                            rw[get(eventsize, vbl, missing)]
                        else missing
                        end
                    end
                end
            end
        end
    end

    ##


    ## add gub
    let
        nj = CSV.read(njdat, DataFrame)

        va = CSV.read(vadat, DataFrame)

        nj[!, :in_person] = nj.total_ballots - nj.ballots_by_mail;

        gubturnout = Dict(
            vcat(nj.fips, va.fips) .=> vcat(nj.in_person, va.election_day)
        )

        for (i, (fps, ev)) in enumerate(zip(trt.fips, trt.event))
            if ev == "Gubernatorial"
                trt.size[i] = get(gubturnout, fps, missing)
            end
        end
    end

    ## add trump
    let
        trmp = CSV.read(trumpdat, DataFrame)

        # trmp.date = Date.(trmp.date, "m/d/y") + Dates.Year(2000);
        trmp.size = sqrt.(trmp.crowd_lwr .* trmp.crowd_upr)

        dd = Dict{Tuple{Date, Int}, Union{Float64, Missing}}()
        for r in eachrow(trmp)
            dd[(r.date, r.fips)] = r.size
        end

        for (i, (dte, fps, ev)) in enumerate(zip(trt.date, trt.fips, trt.event))
            if ev == "Rally"
                trt.size[i] = get(dd, (dte, fps), missing)
            end
        end
    end


    ##

    evs = [
        :primary,
        :gaspecial,
        :gub,
        :protest,
        :rallyday0,
        :rallyday1,
        :rallyday2,
        :rallyday3
    ];

    dp = @subset(dat, :political .== 1);
    dps = select(dp, [:fips, :running, evs...])

    dps = stack(
        dps,
        evs, value_name=:held, variable_name=:event
    )

    @subset!(dps, :held .== 1)

    # (tt, tu)
    treatcats = Dict{Tuple{Int,Int},Int}();
    evs = string.(evs);
    for (tt, tu, ev) in zip(dps.running, dps.fips, dps.event)
        treatcats[(tt, tu)] = findfirst(ev .== evs)
    end


    trt[!, :eventcat] .= 0;
    for (j, (tt, tu)) in enumerate(zip(trt.running, trt.fips))
        trt[j, :eventcat] = treatcats[(tt, tu)]
    end

    trt.eventcat = categorical([evs[i] for i in trt.eventcat]);
    # trt.eventcat = categorical(trt.eventcat);

    trt = @subset(trt, :eventcat .∉ Ref(["rallyday1", "rallyday2", "rallyday3"]))
    trt = dropmissing(trt, :size)

    trt.size_adj = trt.size ./ 10000
    trt.size_rnd = Vector{Union{Int, Missing}}(undef, nrow(trt));

    for (i, x) in enumerate(trt.size)
        if !ismissing(x)
            trt.size_rnd[i] = round(x; digits = 0)
        end
    end
    trt.pop_adj = trt.pop ./ 10000

    return trt
end

function treatmentplot(dat, gadatafile, protestdatafile)

    # parameters so that we can run the functions
    #= practically, the only parameter that changes across models
    is the outcome. for the paper, everything else stays the same
    =#
    covarspec = "full" # = ARGS[]
    outcome = :Rt;
    scenario = "combined ";
    F = 0:20; L = -30:-1
    iters = 10000;
    
    dat = finish_data(dat, gadatafile, protestdatafile);
    dat, _, _, _, _, _ = indicatetreatments(dat);
    
    vn = VariableNames();
    TSCSMethods.rename!(dat, :deathscum => vn.cd, :casescum => vn.cc);
    
    _, dat = preamble(
        outcome, F, L, dat, scenario, covarspec, iters;
        borderexclude = false, convert_missing = false
    );
    
    sort!(dat, [:fips, :date]);
        
    trt = sizeprocess(dat);
    trt.lpop = log.(trt.pop);
    trt.lsize = log.(trt.size);
    trt.pct = trt.size ./ trt.pop
    
    trt2 = trt;
    
    ## xlabels
    dtlab = Date("2020-03-01"):Month(4):maximum(trt.date) |> collect
    dtdf = dtlab .- Date("2020-03-01")
    dtlab = string.(dtlab)
    dtval = [Dates.value(e) for e in dtdf]
    
    @subset!(trt2, :size .> 20, :pct .<= 1)

    fg = Figure(resolution = (900, 800))
    ga = fg[1, 1:2] = GridLayout()
    gx = ga[1,2] = GridLayout()
    gb = fg[2, 1:2] = GridLayout()

    slab = (Int.(round.(exp.([2.5,5,7.5,10,12.5]); digits = 0)));
    ords = floor.(Int, log10.(slab))
    slab = Int.([round(e; digits = r*-1) for (e, r) in zip(slab, ords)])
    svals = log.(slab);
    slab = string.(slab)

    ax1 = Axis(
        ga[1,1];
        xticks = (svals, slab),
        title = "Event sizes",
        ylabel = "frequency",
        xgridvisible = false,
        ygridvisible = false
    )
    hist!(ax1, log.(trt2.size); bins = 100, color = :grey)

    ax3 = Axis(
        ga[1,2];
        title = "Event sizes (as pct. of population)",
        xgridvisible = false,
        ygridvisible = false
    )
    hist!(ax3, trt2.pct; bins = 100, color = :grey)

    ax2 = Axis(
        gb[1, 1];
        title = "Event sizes over time",
        ylabel = "persons",
        xgridvisible = false,
        ygridvisible = false,
        xticks = (dtval, dtlab),
        yticks = (svals, slab),
    )

    # eclrs = [(:transparent, 0.8) for e in trt.event]

    scs = []

    for e in unique(trt2.event)
        ti = @subset(trt2, :event .== e)
        sci = scatter!(
            ax2, ti.running, log.(ti.size);
            color = :transparent,
            label = e,
            strokecolor = [assigneventcolor.(e) for e in ti.event],
            strokewidth = 1
        )
        push!(scs, sci)
    end

    eclr = [assigneventcolor(x) for x in unique(trt.event)]

    group_color = [
        MarkerElement(
            marker = :circle,
            color = :transparent, strokecolor = color,
            strokewidth = 1,
            markersize = 15
        ) for color in eclr
    ]

    lg = Legend(
            gb[1, 2],
            group_color,
            string.(unique(trt.event)),
            "Event"
        )

    for (label, layout) in zip(["a", "b", "b"], [ga, gx, gb])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            # font = :bold,
            padding = (0, 5, 5, 0),
            halign = :right)
    end

    # include these in figure
    # mean(trt2.size), std(trt2.size)
    # mean(trt2.pct), std(trt2.pct)

    return fg
end

###

function plot_si_set(fileset)

    sipth = "plotting/supplementary_figures/"
    edpth = "plotting/extended_figures/"

    for (e, si) in fileset
        println(e)
        X = load_object(e)
        tpe = typeof(X) == TSCSMethods.CICRecords
        if !tpe
            println("wrong type")
            continue
        end
        
        str = X.model.stratifier != Symbol("") ? string(X.model.stratifier) : ""
        scenario = X.model.title * " " * str;

        modelfigure(
            X, scenario,
            sipth, ".svg"
        )
    end
end

function modelfigure(
    X, scenario,
    savepth, format
)

    vn = VariableNames()

    stratifier = X.model.stratifier;

    if stratifier == Symbol("")
        f = _modelfigure_nostrat(
            [X.model, X.refinedmodel, X.calmodel, X.refcalmodel]
        )
        if !isnothing(savepth)
            save(
                    savepth * scenario *string(X.model.outcome) * format, f
                )
        end
        return f
    else

        treatment = if occursin("ga", scenario)
            :gaspec
        elseif occursin("primary", scenario)
            :primary
        elseif occursin("protest", scenario)
            :protest
        elseif occursin("rally", scenario)
            :rallydayunion
        elseif occursin("gub", scenario)
        end

        if (treatment == :gaspec) & (stratifier == vn.tout)
            stratifier = :gaout
        end

        if stratifier == Symbol("Date of First Case to Primary")
            stratifier = Symbol("Date of First Case")
        end

        f = _modelfigure_strat([X.model, X.refinedmodel])
        fc = _modelfigure_strat([X.calmodel, X.refcalmodel])
        
        if !isnothing(savepth)
            for (fg, nm) in zip([f, fc], ["regular_refined", "caliper_refined"])
                save(
                    savepth * scenario *string(X.model.outcome) * nm * format, fg
                )
            end
        end
        return [f, fc]
    end
end

function diagnostic(e; simple = false)
    X = load_object(e)
    str = X.model.stratifier != Symbol("") ? string(X.model.stratifier) : ""
    scenario = X.model.title * " " * str;

    return if !simple
        modelfigure(X, scenario)
    else
        modelfigure_simple(X; stratum = 1)
    end
end

function modelfigure(X, scenario)

    vn = VariableNames()

    stratifier = X.model.stratifier;

    if stratifier == Symbol("")
        f = _modelfigure_nostrat(
            [X.model, X.refinedmodel, X.calmodel, X.refcalmodel]
        )

        return f
    else

        treatment = if occursin("ga", scenario)
            :gaspec
        elseif occursin("primary", scenario)
            :primary
        elseif occursin("protest", scenario)
            :protest
        elseif occursin("rally", scenario)
            :rallydayunion
        elseif occursin("gub", scenario)
        end

        if (treatment == :gaspec) & (stratifier == vn.tout)
            stratifier = :gaout
        end

        if stratifier == Symbol("Date of First Case to Primary")
            stratifier = Symbol("Date of First Case")
        end

        f = _modelfigure_strat([X.model, X.refinedmodel])
        fc = _modelfigure_strat([X.calmodel, X.refcalmodel])
        
        # regular refined, caliper refined
        return [f, fc]
    end
end

function modelfigure_simple(X; stratum = nothing)

    if !isnothing(stratum)
        [@subset!(x.results, :stratum .== stratum) for x in [X.model, X.refinedmodel, X.calmodel, X.refcalmodel]]
        
        [
            select!(
                x.results, Not(:stratum)) for x in [X.model, X.refinedmodel, X.calmodel, X.refcalmodel]
        ]

        @reset X.model.balances = X.model.balances[stratum]
        @reset X.refinedmodel.balances = X.refinedmodel.balances[stratum]
        @reset X.calmodel.balances = X.calmodel.balances[stratum]
        @reset X.refcalmodel.balances = X.refcalmodel.balances[stratum]
    end

    f = _modelfigure_nostrat(
        [X.model, X.refinedmodel, X.calmodel, X.refcalmodel]
    )
    
    return f
end

# plot a whole model result, in the SI
function _modelfigure_nostrat(models)

    f = Figure(
        backgroundcolor = :transparent,
        resolution = (800, 1000)
    );

    G = f[1:5, 1] = GridLayout();
    ga = G[1,1] = GridLayout();
    gb = G[2,1] = GridLayout();
    gc = G[3,1] = GridLayout();
    gd = G[4,1] = GridLayout();
    gleg = G[5,1] = GridLayout();

    layoutsplit(x) = (x[1,1], x[1,2]); # rhs: att, lhs: cb

    subpanels = [
        layoutsplit(ga),
        layoutsplit(gb),
        layoutsplit(gc),
        layoutsplit(gd)
    ];

    ylabelatt = if models[1].outcome == :case_rte
        "Case rate (per 10K pers.)"
    elseif models[1].outcome == :death_rte
        "Death rate (per 10K pers.)"
    elseif models[1].outcome == :deaths
        "Deaths"
    elseif models[1].outcome == :cases
        "Cases"
    else "ATT"
    end

    axcb = [];
    for (gi12, mi, cnt) in zip(subpanels, models, 1:4)
        if cnt == 1
            xlabel = "Day"
            ylabelatt = ylabelatt
            ylabelcb = "Balance score"
        else
            xlabel = ""
            ylabelatt = ""
            ylabelcb = ""
        end
        axs, rbs, scs = add_att_axis!(
            gi12[1], mi;
            xlabel = xlabel, ylabel = ylabelatt
        )
        axcb, ser = add_cb!(
            gi12[2], mi;
            xlabel = xlabel, ylabel = ylabelcb
        )

        for i in eachindex(axs)
            axs[i].xgridvisible = false
            axs[i].ygridvisible = false
        end

        axcb.xgridvisible = false
        axcb.ygridvisible = false
    end

    legcb = Legend(
        f[5,:], axcb, "Covariates",
        nbanks = 3;
        framevisible = false,
        labelsize = 12,
        # position = :lt,
        tellwidth = false,
        tellheight = false,
        # margin = (30, 30, 300, 30),
        # halign = ha, valign = va,
        # orientation = :horizontal
    )

    for (label, layout) in zip(["a", "b", "c", "d"], [ga, gb, gc, gd])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    return f
end

# plot a whole model result, in the SI
function _modelfigure_strat(models)

    f = Figure(
        backgroundcolor = :transparent,
        resolution = (1000*1.5, 900*1.5)
    );

    S = unique(models[1].results.stratum)

    G = f[1:(length(S)+1), 1:2] = GridLayout();
    G1 = f[1:4, 1] = GridLayout();
    ga = G[1,1] = GridLayout();
    gb = G[2,1] = GridLayout();
    gc = G[3,1] = GridLayout();
    gd = G[4,1] = GridLayout();

    gleg = G[(length(S)+1),1:2];

    G2 = f[1:(length(S)+1), 2] = GridLayout();
    ga2 = G[1,2] = GridLayout();
    gb2 = G[2,2] = GridLayout();
    gc2 = G[3,2] = GridLayout();
    gd2 = G[4,2] = GridLayout();
    
    layoutsplit(x) = (x[1,1], x[1,2]); # rhs: att, lhs: cb
    
    subpanels = [
        layoutsplit(ga),
        layoutsplit(gb),
        layoutsplit(gc),
        layoutsplit(gd)
    ];

    subpanels2 = [
        layoutsplit(ga2),
        layoutsplit(gb2),
        layoutsplit(gc2),
        layoutsplit(gd2)
    ];
        
    if length(S) == 5
        ge = G[5,1] = GridLayout();
        push!(subpanels, layoutsplit(ge))

        ge2 = G[5,2] = GridLayout();
        push!(subpanels2, layoutsplit(ge2))
    end

    ylabelatt = if models[1].outcome == :case_rte
        "Case rate (per 10K pers.)"
    elseif models[1].outcome == :death_rte
        "Death rate (per 10K pers.)"
    else "ATT"
    end

    for (gi12, s, cnt) in zip(subpanels, S, 1:length(S))
        if cnt == 1
            xlabel = "Day"
            ylabelatt = ylabelatt
            ylabelcb = "Balance score"
        else
            xlabel = ""
            ylabelatt = ""
            ylabelcb = ""
        end
        resi = @subset(models[1].results, :stratum .== s)
        select!(resi, Not(:stratum))
        label = !isnothing(models[1].labels) ? models[1].labels[s] : nothing
        axs, rbs, scs = add_att_axis!(
            gi12[1], resi,models[1].outcome;
            xlabel = xlabel, ylabel = ylabelatt, label = label,
        )
        cbi = models[1].balances[s];
        axcb, ser = add_cb!(
            gi12[2], cbi;
            xlabel = xlabel, ylabel = ylabelcb
        )

        for i in eachindex(axs)
            axs[i].xgridvisible = false
            axs[i].ygridvisible = false
        end

        axcb.xgridvisible = false
        axcb.ygridvisible = false
    end

    axcb = [];
    for (gi212, s, cnt) in zip(subpanels2, S, 1:length(S))
        xlabel = ""
        ylabelatt = ""
        ylabelcb = ""
        resi = @subset(models[2].results, :stratum .== s)
        axs, rbs, scs = add_att_axis!(
            gi212[1], resi,models[1].outcome;
            xlabel = xlabel, ylabel = ylabelatt
        )
        cbi = models[2].balances[s];
        axcb, ser = add_cb!(
            gi212[2], cbi;
            xlabel = xlabel, ylabel = ylabelcb
        )

        for i in eachindex(axs)
            axs[i].xgridvisible = false
            axs[i].ygridvisible = false
        end

        axcb.xgridvisible = false
        axcb.ygridvisible = false
    end

    legcb = Legend(
        f[(length(S)+2), :], axcb, "Covariates",
        nbanks = 6;
        framevisible = false,
        labelsize = 12,
        # position = :lt,
        tellwidth = false,
        tellheight = false,
        margin = (-130, 30, 30, 30),
        # halign = ha, valign = va,
        orientation = :horizontal
    )

    for (label, layout) in zip(["a", "b"], [G1, G2])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    return f
end

function rally_ts_x_exposure_fig(
    X, scenario;
    savepth = "covid-political-events-paper (working)/si_figures/",
    format = ".png"
)

    @unpack model, refinedmodel, calmodel, refcalmodel, obsinfo, matchinfo = X;
    @unpack stratifier, title = model;
    
    S = unique(model.results.stratum)

    ylabelatt = if model.outcome == :case_rte
        "Case rate (per 10K pers.)"
    elseif model.outcome == :death_rte
        "Death rate (per 10K pers.)"
    else "ATT"
    end

    fpos = [collect(Iterators.product(1:4,1:4))[:, [1,3]], collect(Iterators.product(1:4,1:4))[:, [2,4]]]

    Figs = Vector{Figure}(undef, 4)

    axcb = []

    for (o, m) in enumerate([model, refinedmodel, calmodel, refcalmodel])
  
        f = Figure(
            backgroundcolor = :transparent,
            resolution = (1000*1.5, 900*1.5)
            );
            
        G = f[1:4, 1:4] = GridLayout();
        gleg = f[5,:]
        Gx = f[1:5, 1:4] = GridLayout();

        for (s, k) in zip(S, 1:length(S))
            
            if k == 1
                xlabel = "Day"
                ylabelatt = ylabelatt
                ylabelcb = "Balance score"
            else
                xlabel = ""
                ylabelatt = ""
                ylabelcb = ""
            end

            resi = @subset(m.results, :stratum .== s)
            select!(resi, Not(:stratum))
            label = !isnothing(m.labels) ? m.labels[s] : nothing
            
            # c = k <= 4 ? 1 : 2
            # k2 = k <= 4 ? k : k-4
            fpk = fpos[1][k]; fpk2 = fpos[2][k];

            axs, rbs, scs = add_att_axis!(
                f[fpk...], resi, model.outcome;
                xlabel = xlabel, ylabel = ylabelatt, label = label,
            )

            for i in eachindex(axs)
                axs[i].xgridvisible = false
                axs[i].ygridvisible = false
            end
            
            cbi = m.balances[s];

            axcb, ser = add_cb!(
                f[fpk2...], cbi;
                xlabel = xlabel, ylabel = ylabelcb
            )

            axcb.xgridvisible = false
            axcb.ygridvisible = false
        end

        legcb = Legend(
            f[4+1, :], axcb, "Covariates",
            nbanks = 6;
            framevisible = false,
            labelsize = 12,
            # position = :lt,
            tellwidth = false,
            tellheight = false,
            margin = (130, 30, 100, 30),
        )

        Figs[o] = f
    end

    if !isnothing(savepth)
        for (fg, nm) in zip(
            Figs, ["regular", "refined", "caliper", "refined caliper"]
        )
            save(savepth * scenario * nm * format, fg)
        end
    end
    return Figs
end

## non outcome plots

function testingfig(
    dat_store;
    p1 = "combined out/grace combined out/combined full_death_rte_excluded.jld2"
)

    # COUNTY
    # tst = CSV.read(download("https://raw.githubusercontent.com/govex/COVID-19/master/data_tables/testing_data/county_time_series_covid19_US.csv"), DataFrame)
    # data only available after 2021-08-01

    ## process testing data

    ste_link = "https://raw.githubusercontent.com/govex/COVID-19/master/data_tables/testing_data/time_series_covid19_US.csv" # state level data
    ste = CSV.read(
        download(ste_link),
        DataFrame
    )

    begin
        dates = Vector{Date}(undef, nrow(ste));
        for i in 1:nrow(ste)
            dates[i] = Date(ste.date[i], dateformat"m/d/y")
        end
        ste.date = dates;
        ste[!, :running] = [Dates.value(s - Date("2020-03-01")) for s in ste.date];
    end

    sort!(ste, [:state, :running])
    select!(ste, Not(:date))

    ste[!, :positivity] = ste[!, :cases_conf_probable] .* inv.(ste[!, :tests_combined_total])

    testvars = [
        :cases_conf_probable, :cases_confirmed, :cases_probable,
        :tests_combined_total #, :positivity
    ];

    @subset(ste, :state .== "MA")

    ## model information

    recordset = load_object(p1)

    model = recordset.model;

    obs = model.observations[model.strata .== 1];
    obs = DataFrame(:running => [ob[1] for ob in obs], :fips => [ob[2] for ob in obs]);

    obdat = innerjoin(
        obs, recordset.matchinfo,
        on = [:running => :timetreated, :fips => :treatedunit]
    );

    obdat[!, :period] = obdat.f .+ obdat.f
    select!(obdat, [:fips, :running, :period, :f])

    obdat = leftjoin(obdat, dat_store; on = [:period => :running, :fips]);
    sort!(obdat, [:running, :fips, :period])

    obdat = leftjoin(
        obdat,
        ste,
        on = [:period => :running, Symbol("State Abbr.") => :state]
    )

    pctΔ(y1, y2) = (y2 .- y1) .* inv.(y1) .* 100

    # calcualte percentage difference
    begin
        gdf = groupby(obdat, [:running, :fips])
        for g in gdf
            # g = gdf[240]
            for v in testvars
                fst = g[1, v] # min for cumulative, not nec. for positivity
                # hcat(g[!, v], pctΔ(fst, g[!, v]))
                g[!, v] = pctΔ(fst, g[!, v])
            end
        end
    end

    findfirst(([keys(gdf)[i][1] for i in 1:length(gdf)] .== 72) .& ([keys(gdf)[i][2] for i in 1:length(gdf)] .== 31005) .== true)

    gdf[240][!, [:fips, :running, :period, :f, testvars...]]

    ob3 = @chain obdat begin
        groupby([:f])
        combine([v => mean∘skipmissing => v for v in [testvars..., :positivity]])
    end

    for v in testvars[end-1:end]
        vn = Symbol(string(v) * "_diff")
        ob3[!, vn] = Vector{Union{Float64, Missing}}(missing, nrow(ob3))
        ob3[2:end, vn] = diff(ob3[!, v])
    end

    ob3


    fg = begin
        f = Figure()
        ax1 = Axis(
            f[1,1];
            ylabel = "Pct. change in total tests",
            xlabel = "Day",
            yticklabelcolor = :cornflowerblue
        )
        ax2 = Axis(
            f[1,1];
            ylabel = "Positivity",
            yticklabelcolor = :goldenrod1
        )

        lines!(
            ax1, ob3.f, ob3.tests_combined_total;
            color = :cornflowerblue,
            label = "Total tests"
        )
        lines!(
            ax2, ob3.f, ob3.positivity .* 100;
            color = :goldenrod1,
            label = "Positivity"
        )
        
        ax2.yaxisposition = :right
        ax2.yticklabelalign = (:left, :center)
        ax2.xticklabelsvisible = false
        ax2.xticklabelsvisible = false
        ax2.xlabelvisible = false

        hidexdecorations!(
            ax1, grid = true, ticks = false, ticklabels = false, label = false
        )
        hidexdecorations!(
            ax2, grid = true, ticks = false, ticklabels = false, label = false
        )
        hideydecorations!(
            ax1, grid = true, ticks = false, ticklabels = false, label = false
        )
        hideydecorations!(
            ax2, grid = true, ticks = false, ticklabels = false, label = false
        )

        linkxaxes!(ax1, ax2)

        # Legend(f[1,2], ax)
        f
    end

    return fg
end
