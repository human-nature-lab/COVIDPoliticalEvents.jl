# si_paper_plot_functions.jl

function plot_si_set(fileset, dat, savepth)

    for e in fileset
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
            X, dat, scenario,
            savepth, ".svg"
        )
    end
end

function modelfigure(
    X, dat, scenario,
    savepth, format
)

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

# plot a whole model result, in the SI
function _modelfigure_nostrat(models)

    f = Figure(
        backgroundcolor = RGBf(0.98, 0.98, 0.98),
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
    end

    legcb = Legend(
        f[5,:], axcb, "Covariates",
        nbanks = 3;
        framevisible = false,
        labelsize = 12,
        position = :lt,
        tellwidth = false,
        tellheight = false,
        # margin = (30, 30, 300, 30),
        # halign = ha, valign = va,
        # orientation = :horizontal
    )

    for (label, layout) in zip(["a", "b", "c", "d"], [ga, gb, gc, gd])
        Label(layout[1, 1, TopLeft()], label,
            textsize = 26,
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
        backgroundcolor = RGBf(0.98, 0.98, 0.98),
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
        # zip(subpanels, models, 1:2)
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
    end

    legcb = Legend(
        f[(length(S)+2), :], axcb, "Covariates",
        nbanks = 6;
        framevisible = false,
        labelsize = 12,
        position = :lt,
        tellwidth = false,
        tellheight = false,
        margin = (-130, 30, 30, 30),
        # halign = ha, valign = va,
        orientation = :horizontal
    )

    for (label, layout) in zip(["a", "b"], [G1, G2])
        Label(layout[1, 1, TopLeft()], label,
            textsize = 26,
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

    # (o, m) = collect(enumerate([model, refinedmodel, calmodel, refcalmodel]))[1]

    for (o, m) in enumerate([model, refinedmodel, calmodel, refcalmodel])
  
        f = Figure(
            backgroundcolor = RGBf(0.98, 0.98, 0.98),
            resolution = (1000*1.5, 900*1.5)
            );
            
        G = f[1:4, 1:4] = GridLayout();
        gleg = f[5,:]
        Gx = f[1:5, 1:4] = GridLayout();

        # (s, k) = collect(zip(S, 1:length(S)))[1]
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
            
            cbi = m.balances[s];

            axcb, ser = add_cb!(
                f[fpk2...], cbi;
                xlabel = xlabel, ylabel = ylabelcb
            )
        end

        legcb = Legend(
            f[4+1, :], axcb, "Covariates",
            nbanks = 6;
            framevisible = false,
            labelsize = 12,
            position = :lt,
            tellwidth = false,
            tellheight = false,
            margin = (130, 30, 100, 30),
            # halign = ha, valign = va,
            # orientation = :horizontal
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
