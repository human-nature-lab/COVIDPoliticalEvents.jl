# si_paper_plot_functions.jl

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

    recordset = JLD2.load_object(p1)

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
