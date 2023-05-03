## PRIMARY FIGURE

"""
        figure3(xlabel, ylabels, outcomecolors, offsets, savepth, format)

Primary panel figure.
"""
function figure3(xlabel, ylabels, outcomecolors, offsets, savepth, format)

    modspth = "primary out/"
    overalldeathmod = " primary full_death_rte_.jld2"
    overallcasemod = " primary full_case_rte_.jld2"

    stratdeathmod = " primary full_death_rte_In-person Turnout Rate.jld2"
    stratcasemod = " primary full_case_rte_In-person Turnout Rate.jld2"

    oamd = JLD2.load_object(modspth * overalldeathmod);
    oamc = JLD2.load_object(modspth * overallcasemod);

    smd = JLD2.load_object(modspth * stratdeathmod);
    smc = JLD2.load_object(modspth * stratcasemod);

    # FIGURE

    size_inches = (180, 180 * 0.75) .* inv(25.4)
    size_pt = 72 * 2 .* size_inches

    f = Figure(
        backgroundcolor = :transparent, # RGBf(0.98, 0.98, 0.98),
        resolution = size_pt,
        fontsize = 12 * 1
    );

    panelA = f[1,1] = GridLayout()
    panelB = f[2,1] = GridLayout()

    ## PANEL A

    # wherever an axis was plotted into a position, we plot two axes into
    # that position

    m1 = oamd.refcalmodel; m2 = oamc.refcalmodel;

    fmin, fmax, fs, atts, lwr, upr = extract(m1, m2);
    intr = 5
    xt = collect(fmin:intr:fmax);

    axm2 = Axis(
        panelA[1,1],
        ylabel = ylabels[2],
        xticks = xt,
        yticklabelcolor = outcomecolors[2],
        yaxisposition = :right,
    );

    hidespines!(axm2)
    hidexdecorations!(axm2)

    axm1 = Axis(
        panelA[1,1];
        xlabel = xlabel,
        ylabel = ylabels[1],
        xticks = xt,
        xminorticks = IntervalsBetween(intr),
        yticklabelcolor = outcomecolors[1]
    );

    rb1 = rangebars!(
        axm1,
        fs[1] .+ offsets[1],
        lwr[1], upr[1],
        color = outcomecolors[1];
        whiskerwidth = 0,
        label = ylabels[1],
        linewidth = 1.5
    );

    sc1 = scatter!(
        axm1, fs[1] .+ offsets[1], atts[1], markersize = 5, color = :black
    );

    rb2 = rangebars!(
        axm2,
        fs[2] .- offsets[2],
        lwr[2], upr[2],
        color = outcomecolors[2];
        whiskerwidth = 0,
        linewidth = 1.5,
        label = "cases"
    );

    sc2 = scatter!(
        axm2, fs[2] .- offsets[2], atts[2], markersize = 5, color = :black
    );

    # xlims!(axm1, [8.75, 41.75])
    # xlims!(axm2, [9.25, 42.25])

    xlims!(axm1, [9.5, 40.5])
    xlims!(axm2, [9.5, 40.5])

    yd, yc = get_ylims(m1, m2)

    ylims!(axm1, (-yd, yd))
    ylims!(axm2, (-yc, yc))

    hlines!(
        axm1, [0.0], color = (:black, 0.6),
        linestyle = :dash, linewidth = 0.8
    )

    hidedecorations!(axm1, ticks = false, ticklabels = false, label = false)
    hidedecorations!(axm2, ticks = false, ticklabels = false, label = false)

    vlx = collect(9.5:40.5);

    vlines!(
        axm1, vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )

    ## PANEL B

    m1b = smd.refcalmodel; m2b = smc.refcalmodel;
    labels = m1b.labels;

    mds, mcs = get_ylims(m2b, m2b)

    strata = if unique(m1b.results.stratum) == unique(m2b.results.stratum)
        unique(m1b.results.stratum)
    else
        error("strata problem")
    end

    panelBpositions = [(1,1), (1,2), (2,1), (2,2)]
    for (s, fCpos) in zip(1:4, panelBpositions) # skip missing turnout counties

        # stratum-level
        f_i = f[2,1][fCpos...]

        fmin, fmax, fs, atts, lwr, upr = extract(m1b, m2b, s);
        intr = 5
        xt = collect(fmin:intr:fmax);

        axi_c = Axis(
            f_i,
            # ylabel = "Case rate (per 10,000 persons)",
            xticks = xt,
            yticklabelcolor = outcomecolors[2],
            yaxisposition = :right,
            title = labels[s]
        );

        hidespines!(axi_c)
        hidexdecorations!(axi_c)

        axi_d = Axis(
            f_i;
            xlabel = (s == 1) | (s == 2) ? "" : xlabel,
            # ylabel = ylabel,
            xticks = xt,
            xminorticks = IntervalsBetween(intr),
            yticklabelcolor = outcomecolors[1]
        );

        rb_d = rangebars!(
            axi_d,
            fs[1] .+ offsets[1],
            lwr[1], upr[1],
            color = outcomecolors[1];
            whiskerwidth = 0,
            label = ylabels[1],
            linewidth = 9/10
        );

        sc_d = scatter!(
            axi_d, fs[1] .+ offsets[1], atts[1], markersize = 3, color = :black
        );

        rb_c = rangebars!(
            axi_c,
            fs[2] .- offsets[2],
            lwr[2], upr[2],
            color = outcomecolors[2];
            whiskerwidth = 0,
            linewidth = 9/10,
            label = "cases"
        );

        sc_c = scatter!(
            axi_c, fs[2] .- offsets[2], atts[2], markersize = 3, color = :black
        );

        # xlims!(axm1, [8.75, 41.75])
        # xlims!(axm2, [9.25, 42.25])

        xlims!(axi_d, [9.5, 40.5])
        xlims!(axi_c, [9.5, 40.5])

        ylims!(axi_d, (-mds[s], mds[s]))
        ylims!(axi_c, (-mcs[s], mcs[s]))

        hlines!(
            axi_d, [0.0], color = (:black, 0.6),
            linestyle = :dash, linewidth = 0.8
        )

        hidedecorations!(axi_d, ticks = false, ticklabels = false, label = false)
        hidedecorations!(axi_c, ticks = false, ticklabels = false, label = false)

        vlx = collect(9.5:40.5);

        vlines!(
            axi_d, vlx,
            color = :black, linestyle = nothing, linewidth = 0.2
        )
    end

    for (label, layout) in zip(["a", "b"], [panelA, panelB])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26, # updated from text size
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    rowsize!(f.layout, 1, Auto(0.5))
    rowgap!(f.layout, 5)
    colgap!(panelB, 5)

    save(
        savepth * "Figure 3" * format,
        f,
        pt_per_unit = 1
    )

    oac = outcomes_counts(m1.results, m2.results);
    sac = outcomes_counts(m1b.results, m2b.results, m1b.labels);

    oac.stratum .= "";
    oac.label .= "overall";
    counts = vcat(oac, sac);

    vbles = [:treated_deaths, :matches_deaths, :treated_cases, :matches_cases];
    av_counts = @chain counts begin
        groupby([:stratum, :label])
        combine([v => mean => v for v in vbles])
    end;

    CSV.write(savepth * "Figure 3 counts.csv", counts)
    CSV.write(savepth * "Figure 3 average counts.csv", av_counts)

    return f
end
