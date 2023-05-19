# figure_code.jl

# main figures

"""
        figure3(xlabel, ylabels, outcomecolors, offsets, savepth, format)

Primary panel figure.
"""
function figure3(
    xlabel, ylabels, outcomecolors, offsets, savepth, format;
    overalldeathmod = "primary out/ primary full_death_rte_.jld2",
    overallcasemod = "primary out/ primary full_case_rte_.jld2",
    stratdeathmod = "primary out/ primary full_death_rte_In-person Turnout Rate.jld2",
    stratcasemod = "primary out/ primary full_case_rte_In-person Turnout Rate.jld2"
)

    oamd = load_object(overalldeathmod);
    oamc = load_object(overallcasemod);

    smd = load_object(stratdeathmod);
    smc = load_object(stratcasemod);

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

function figure4(
    xlabel, ylabels, outcomecolors, offsets, savepth, format;
    gamod_case = "ga out/ ga nomob_case_rte_.jld2",
    gamod_death = "ga out/ ga nomob_death_rte_.jld2",
    gubmod_case = "gub out/ gub out nomob_case_rte_.jld2",
    gubmod_death = "gub out/ gub out nomob_death_rte_.jld2"
)

    gad = load_object(gamod_death);
    gac = load_object(gamod_case);

    gud = load_object(gubmod_death);
    guc = load_object(gubmod_case);

    # FIGURE

    size_inches = (180, 180 * 0.75) .* inv(25.4)
    size_pt = 72 * 2 .* size_inches

    f = Figure(
        backgroundcolor = :transparent,
        resolution = size_pt, fontsize = 12 * 1
    );

    panelA = f[1,1] = GridLayout()
    panelB = f[2,1] = GridLayout()

    ## PANEL A

    m1 = gad.refcalmodel; m2 = gac.refcalmodel;

    fmin, fmax, fs, atts, lwr, upr = extract(m1, m2);
    intr = 5
    xt = collect(fmin:intr:fmax);

    axm2 = Axis(
        panelA[1,1],
        ylabel = ylabels[2],
        xticks = xt,
        yticklabelcolor = outcomecolors[2],
        yaxisposition = :right
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
        label = ylabels[1]
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
        axm1, [0.0], color = (:black, 0.6), linestyle = :dash, linewidth = 0.8
    )

    hidedecorations!(axm1, ticks = false, ticklabels = false, label = false)
    hidedecorations!(axm2, ticks = false, ticklabels = false, label = false)

    vlx = collect(9.5:40.5);

    vlines!(
        axm1, vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )

    ## PANEL B

    m3 = gud.refcalmodel; m4 = guc.refcalmodel;

    fmin, fmax, fs, atts, lwr, upr = extract(m3, m4);
    intr = 5
    xt = collect(fmin:intr:fmax);

    axm2 = Axis(
        panelB[1,1],
        # ylabel = ylabels[2],
        xticks = xt,
        yticklabelcolor = outcomecolors[2],
        yaxisposition = :right
    );

    hidespines!(axm2)
    hidexdecorations!(axm2)

    axm1 = Axis(
        panelB[1,1];
        xlabel = xlabel,
        # ylabel = ylabels[1],
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
        label = ylabels[1]
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
        label = "cases"
    );

    sc2 = scatter!(
        axm2, fs[2] .- offsets[2], atts[2], markersize = 5, color = :black
    );

    # xlims!(axm1, [8.75, 41.75])
    # xlims!(axm2, [9.25, 42.25])

    xlims!(axm1, [9.5, 40.5])
    xlims!(axm2, [9.5, 40.5])

    yd, yc = get_ylims(m3, m4)

    ylims!(axm1, (-yd, yd))
    ylims!(axm2, (-yc, yc))

    hlines!(
        axm1, [0.0], color = (:black, 0.6), linestyle = :dash, linewidth = 0.8
    )

    hidedecorations!(axm1, ticks = false, ticklabels = false, label = false)
    hidedecorations!(axm2, ticks = false, ticklabels = false, label = false)

    vlx = collect(9.5:40.5);

    vlines!(
        axm1, vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )

    for (label, layout) in zip(["a", "b"], [panelA, panelB])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    # rowsize!(f.layout, 1, Auto(0.5))
    rowgap!(f.layout, 5)
    colgap!(panelB, 5)

    save(
        savepth * "Figure 4" * format,
        f,
        pt_per_unit = 1
    )

    oac1 = outcomes_counts(m1.results, m2.results)
    oac2 = outcomes_counts(m3.results, m4.results);

    oac1.label .= "ga";
    oac2.label .= "nj";
    counts = vcat(oac1, oac2);

    vbles = [:treated_deaths, :matches_deaths, :treated_cases, :matches_cases];
    av_counts = @chain counts begin
        groupby(:label)
        combine([v => mean => v for v in vbles])
    end;

    CSV.write(savepth * "Figure 4 counts.csv", counts)
    CSV.write(savepth * "Figure 4 average counts.csv", av_counts)

    return f
end

function figure6(
    xlabel, ylabels, outcomecolors, offsets, savepth, format;
    overalldeathmod = "protest out/ protest nomob_death_rte_.jld2",
    stratdeathmod = "protest out/ protest nomob_death_rte_prsize.jld2",
    overallcasemod = "protest out/ protest nomob_case_rte_.jld2",
    stratcasemod = "protest out/ protest nomob_case_rte_prsize.jld2",
)

    oamd = load_object(overalldeathmod);
    oamc = load_object(overallcasemod);

    smd = load_object(stratdeathmod);
    smc = load_object(stratcasemod);

    # FIGURE

    size_inches = (180, 180 * 0.75) .* inv(25.4)
    size_pt = 72 * 2 .* size_inches

    f = Figure(
        backgroundcolor = RGBf(0.98, 0.98, 0.98),
        resolution = size_pt, fontsize = 12 * 1
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
        yaxisposition = :right
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
        label = ylabels[1]
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

    hlines!(axm1, [0.0], color = :black, linestyle = :dash, linewidth = 0.8)

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

    mds, mcs = get_ylims(m1b, m2b)

    strata = if unique(m1b.results.stratum) == unique(m2b.results.stratum)
        unique(m1b.results.stratum)
    else
        error("strata problem")
    end

    panelBpositions = [(1,1), (1,2), (2,1), (2,2)]
    for (s, fCpos) in zip(1:3, panelBpositions) # skip missing turnout counties

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
            xlabel = xlabel,
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

        hlines!(axi_d, [0.0], color = :black, linestyle = :dash, linewidth = 1)

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
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    rowsize!(f.layout, 1, Auto(0.5))
    rowgap!(f.layout, 5)
    colgap!(panelB, 5)

    save(
        savepth * "Figure 6" * format,
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

    CSV.write(savepth * "Figure 6 counts.csv", counts)
    CSV.write(savepth * "Figure 6 average counts.csv", av_counts)

    return f
end

function figure5(
    xlabel, ylabels, outcomecolors, offsets, savepth, format;
    stratdeathmod = "rally out/ rally nomob_death_rte_exposure.jld2",
    stratcasemod = "rally out/ rally nomob_case_rte_exposure.jld2"
)

    smd = load_object(stratdeathmod);
    smc = load_object(stratcasemod);

    # FIGURE
    
    size_inches = (180, 180 * 0.75) .* inv(25.4)
    size_pt = 72 * 2 .* size_inches

    f = Figure(
        backgroundcolor = :transparent,
        resolution = size_pt, fontsize = 12 * 1
    );

    panelA = f[1,1] = GridLayout()
    panelB = f[2,1] = GridLayout()

    ## PANEL A

    # wherever an axis was plotted into a position, we plot two axes into
    # that position

    m1 = smd.refcalmodel; m2 = smc.refcalmodel;

    fmin, fmax, fs, atts, lwr, upr = extract(m1, m2, 1);

    intr = 5
    xt = collect(fmin:intr:fmax);

    axm2 = Axis(
        panelA[1,1],
        ylabel = ylabels[2],
        xticks = xt,
        yticklabelcolor = outcomecolors[2],
        yaxisposition = :right
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
        label = ylabels[1]
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
        label = "cases"
    );

    sc2 = scatter!(
        axm2, fs[2] .- offsets[2], atts[2], markersize = 5, color = :black
    );

    # xlims!(axm1, [8.75, 41.75])
    # xlims!(axm2, [9.25, 42.25])

    xlims!(axm1, [9.5, 40.5])
    xlims!(axm2, [9.5, 40.5])

    yd, yc = get_ylims(lwr, upr)

    ylims!(axm1, (-yd, yd))
    ylims!(axm2, (-yc, yc))

    hlines!(
        axm1, [0.0], color = (:black, 0.6), linestyle = :dash, linewidth = 0.8
    )

    hidedecorations!(axm1, ticks = false, ticklabels = false, label = false)
    hidedecorations!(axm2, ticks = false, ticklabels = false, label = false)

    vlx = collect(9.5:40.5);

    vlines!(
        axm1, vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )

    ## PANEL B

    m1 = smd.refcalmodel; m2 = smc.refcalmodel;
    labels = m1.labels;

    mds, mcs = get_ylims(m1, m2)

    strata = if unique(m1.results.stratum) == unique(m2.results.stratum)
        unique(m1.results.stratum)
    else
        error("strata problem")
    end

    panelBpositions = [(1,1), (1,2), (2,1), (2,2)]
    for (s, fCpos) in zip(2:4, panelBpositions) # skip missing turnout counties

        # stratum-level
        f_i = f[2,1][fCpos...]

        fmin, fmax, fs, atts, lwr, upr = extract(m1, m2, s);
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
            xlabel = xlabel,
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
            axi_d, [0.0], color = (:black, 0.6), linestyle = :dash, linewidth = 0.8
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
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    rowsize!(f.layout, 1, Auto(0.5))
    rowgap!(f.layout, 5)
    colgap!(panelB, 5)

    save(
        savepth * "Figure 5" * format,
        f,
        pt_per_unit = 1
    )

    counts = outcomes_counts(m1.results, m2.results, m1.labels);

    vbles = [:treated_deaths, :matches_deaths, :treated_cases, :matches_cases];
    av_counts = @chain counts begin
        groupby([:stratum, :label])
        combine([v => mean => v for v in vbles])
    end;

    CSV.write(savepth * "Figure 5 counts.csv", counts)
    CSV.write(savepth * "Figure 5 average counts.csv", av_counts)

    return f
end

function figure7(;
    savepath = nothing,
    format = ".svg",
    models = [
        "Rt out/primary full_Rt_.jld2",
        "Rt out/ga epi_Rt_.jld2",
        "Rt out/gub nomob_Rt_.jld2",
        "Rt out/rally nomob_Rt_exposure.jld2",
        "Rt out/protest nomob_Rt_.jld2"
    ]
)

    xlabel = "Day"; ylabel = L"R_{t}";


    ms = Vector{Any}(undef, 5)
    for (i, m) in enumerate(models)
        ms[i] = load_object(m).refcalmodel;
    end

    # COLORS

    variablecolors = colorvariables();

    size_inches = (180 * 3, 180 * 2) .* inv(25.4) .* 1
    size_pt = 72 .* size_inches

    # FIGURE

    size_inches = (180, 180 * 0.75) .* inv(25.4)
    size_pt = 72 * 2 .* size_inches

    f = Figure(
        backgroundcolor = :transparent,
        resolution = size_pt, fontsize = 12 * 1
    );

    panelA = f[1,1] = GridLayout()
    panelB = f[2,1] = GridLayout()

    pa = panelA[1,1];
    pb = panelB[1,1];
    pc = f[3,1]

    fmin, fmax = ms[1].F[[1, end]]
    
    intr = 5
    xt = collect(fmin:intr:fmax);

    ## PANEL A

    # wherever an axis was plotted into a position, we plot N axises into
    # that position

    elections = @views ms[1:3];

    axises = []; sctrs = []; rbs = [];
    mn, mx = Inf, -Inf
    offsetvals = [-0.25, 0, 0.25]
    colors = eventcolors(true);

    (i, mi) = collect(enumerate(elections))[1]
    for (i, mi) in enumerate(elections)

        @unpack results, covariates, balances = mi
        # @subset!(results, :f .<= 20)

        att, lo, hi = extract(results);
        fs = results.f
        offsets = zeros(Int, length(fs)) .+ offsetvals[i]

        ax = Axis(
            pa,
            ylabel = ylabel,
            xlabel = xlabel,
            xticks = xt,
            # yticklabelcolor = variablecolors[oc],
            yaxisposition = :left,
            xgridvisible = false,
            ygridvisible = false,
            xminorgridvisible = false
        )
        
        if i == 1
            hidedecorations!(
                ax, ticks = false, ticklabels = false, label = false
            )
            hidedecorations!(
                ax, ticks = false, ticklabels = false, label = false
            )
        else
            hidespines!(ax)
            hidexdecorations!(ax)
            hideydecorations!(ax)
        end

        rb = rangebars!(
            ax,
            fs .+ offsets,
            lo, hi,
            color = colors[i],
            whiskerwidth = 0,
            label = ylabel
        );

        sctr = scatter!(
            ax, fs .+ offsets, att, markersize = 5, color = :black
        );

        mn = min(mn, minimum(lo))
        mx = max(mx, maximum(hi))

        push!(axises, ax);
        push!(rbs, rb);
        push!(sctrs, sctr);
    end

    yl = max(abs(mn), abs(mx))
    yl += yl * 0.10;

    for ax in axises; ylims!(ax, (-yl, yl)) end
    for ax in axises; xlims!(ax, (-0.5, 20.5)) end

    hlines!(
        axises[1], [0.0],
        color = (:black, 0.6), linestyle = :dash, linewidth = 0.8
    )

    vlx = collect(-0.5:20.5);

    vlines!(
        axises[1], vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )

    ## PANEL B

    rallies = ms[4:5];
    axises = []; sctrs = []; rbs = [];
    mn, mx = Inf, -Inf
    offsetvals = [-0.15, 0.15];
    colors = eventcolors(false);
    
    for (i, mi) in enumerate(rallies)

        @unpack results, covariates, balances = mi

        if i == 1
            results = results[results[!, :stratum] .== 1, :];
        end

        att, lo, hi = extract(results);

        fs = results.f
        offsets = zeros(Int, length(fs)) .+ offsetvals[i]

        ax = Axis(
            pb,
            ylabel = ylabel,
            xlabel = xlabel,
            xticks = xt,
            # yticklabelcolor = variablecolors[oc],
            yaxisposition = :left,
            xgridvisible = false,
            ygridvisible = false,
            xminorgridvisible = false
        )
        
        if i == 1
            hidedecorations!(
                ax, ticks = false, ticklabels = false, label = false
            )
            hidedecorations!(
                ax, ticks = false, ticklabels = false, label = false
            )
        else
            hidespines!(ax)
            hidexdecorations!(ax)
            hideydecorations!(ax)
        end

        rb = rangebars!(
            ax,
            fs .+ offsets,
            lo, hi,
            color = colors[i],
            whiskerwidth = 0,
            label = ylabel
        );

        sctr = scatter!(
            ax, fs .+ offsets, att, markersize = 5, color = :black
        );

        mn = min(mn, minimum(lo))
        mx = max(mx, maximum(hi))

        push!(axises, ax);
        push!(rbs, rb);
        push!(sctrs, sctr);
    end

    yl = max(abs(mn), abs(mx))
    yl += yl * 0.10;

    for ax in axises; ylims!(ax, (-yl, yl)) end
    for ax in axises; xlims!(ax, (-0.5, 20.5)) end

    hlines!(
        axises[1], [0.0],
        color = (:black, 0.6), linestyle = :dash, linewidth = 0.8
    )

    vlx = collect(-0.5:20.5);

    vlines!(
        axises[1], vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )

    elems = Vector{LineElement}()
    evs, colrs = eventcolorinfo();

    for c in colrs
        le = LineElement(color = c, linestyle = nothing)
        push!(elems, le)
    end

    Legend(
        pc,
        elems,
        evs, "Events";
        framevisible = false,
        # labelsize = 12,
        # position = :left,
        tellheight = false,
        tellwidth = false,
        orientation = :horizontal,
        nbanks = 1
    )
    
    for (label, layout) in zip(["a", "b"], [panelA, panelB])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    rowsize!(f.layout, 3, Auto(0.2))
    rowgap!(f.layout, 5)
    colgap!(panelB, 5)

    if !isnothing(savepath)
        save(savepath * "Figure 7" * format, f, pt_per_unit = 1)
    end

    ms2 = Vector{DataFrame}(undef, length(ms));
    for (i, m) in enumerate(ms)
        res = m.results
        if "stratum" ∈ names(res)
            res.label .= [get(m.labels, e, "") for e in res.stratum]
        else
            res.stratum .= ""
            res.label .= "overall"
        end
        ms2[i] = if "stratum" ∈ names(res)
            select(res, [:stratum, :f, :treated, :matches, :label])
        else
            select(res, [:f, :treated, :matches])
        end
    end

    ms3 = reduce(vcat, ms2)

    vbles = [:treated, :matches];
    av_counts = @chain ms3 begin
        groupby([:stratum, :label])
        combine([v => mean => v for v in vbles])
    end;

    CSV.write(savepth * "Figure 7 counts.csv", ms3);
    CSV.write(savepth * "Figure 7 average counts.csv", av_counts);

    return f
end

function figure8(;
    maxwindow = 20,
    format = ".svg",
    savepath = nothing,
    modelpaths = [
        "mobility out/mobility primary full_multiple_Full-Service Restaurants_.jld2",
        "mobility out/mobility ga full_multiple_Full-Service Restaurants_.jld2",
        "mobility out/mobility gub full_multiple_Full-Service Restaurants_.jld2",
        "mobility out/mobility rally full_multiple_Full-Service Restaurants_exposure.jld2",
        "mobility out/mobility protest full_multiple_Full-Service Restaurants_.jld2"
    ]
)

    xlabel = "Day"; ylabel = "Adjusted total visits (per 1,000)";

    vn = VariableNames();

    # Colors
    variablecolors = colorvariables();

    # Figure

    size_inches = (180*0.5, 180) .* inv(25.4)
    size_pt = 72 * 2 .* size_inches

    f = Figure(
        backgroundcolor = :transparent,
        resolution = size_pt, fontsize = 12 * 1
    );

    panels = []; subpanels = [];
    # ijs = [[1,1], [1,2], [1,3], [2,1], [2,2]]
    ijs = [[j, 1] for j in 1:length(modelpaths)]
    for ij in ijs
        pnl = f[ij...] = GridLayout()
        push!(panels, pnl)
        push!(subpanels, pnl[1,1])
    end

    push!(subpanels, f[length(panels)+1, 1])

    for (j, modelpath) in enumerate(modelpaths)
        modelobject = load_object(modelpath);
        m1 = modelobject.refcalmodel;

        if j == 3
            xlabel2 = ""
            ylabel2 = ylabel
        elseif j == 5
            xlabel2 = xlabel
            ylabel2 = ""
        else
            xlabel2 = ""; ylabel2 = ""
        end

        mobility_plot(
            subpanels[j],
            m1,
            xlabel2, ylabel2,
            variablecolors;
            maxwindow = maxwindow,
            selected = nothing
        )
    end

    elems = Vector{LineElement}()
    vars = [vn.res, vn.groc, vn.rec]
    evs = [string(v) for v in vars]

    for v in vars
        le = LineElement(color = variablecolors[v], linestyle = nothing)
        push!(elems, le)
    end

    Legend(
        subpanels[length(modelpaths)+1],
        elems,
        evs, "Events";
        framevisible = false,
        # labelsize = 12,
        tellheight = false,
        tellwidth = false,
        orientation = :horizontal,
        nbanks = 1
    )

    for (label, layout) in zip(["a", "b", "c", "d", "e"], panels)
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    # rowsize!(f.layout, 1, Auto(0.5))
    rowsize!(f.layout, 6, Auto(0.3))
    rowgap!(f.layout, 5)

    if !isnothing(savepath)
        save(savepath * "Figure 8" * format, f, pt_per_unit = 1)
    end

    counts = DataFrame();
    for modelpath in modelpaths
        m1 = load_object(modelpath).refcalmodel;
        res = m1.results

        res.title .= m1.title

        append!(counts, select(res, [:f, :treated, :matches, :title]))
    end

    vbles = [:treated, :matches];
    av_counts = @chain counts begin
        groupby([:title])
        combine([v => mean => v for v in vbles])
    end;

    CSV.write(savepath * "Figure 8 counts.csv", counts);
    CSV.write(savepath * "Figure 8 average counts.csv", av_counts);

    return f
end

function mobility_plot(
    sp,
    m1,
    xlabel, ylabel,
    variablecolors;
    maxwindow = nothing,
    selected = nothing,
)
    
    if isnothing(selected)
        selected = m1.outcome;
    end

    ## PANEL A

    # wherever an axis was plotted into a position, we plot N axises into
    # that position

    @unpack F, results, covariates, balances = m1

    if !isnothing(maxwindow)
        results = results[results.f .<= maxwindow, :]
    end

    if "stratum" .∈ Ref(names(results))
        results = results[results.stratum .== 1, :]
    end

    Fmax = if isnothing(maxwindow)
        F[end]
    else
        maxwindow
    end

    fmin, fmax = F[1], Fmax
    intr = 5
    xt = collect(fmin:intr:fmax);

    axises = []; sctrs = []; rbs = [];
    mn, mx = Inf, -Inf
    offsetvals = [-0.25, 0, 0.25]
    # ocols = TSCSMethods.gen_colors(3);
    for (i, oc) in enumerate(selected)

        att, lo, hi = extract(oc, results);
        fs = results.f
        offsets = zeros(Int, length(fs)) .+ offsetvals[i]

        ax = Axis(
            sp,
            ylabel = ylabel,
            xlabel = xlabel,
            xticks = xt,
            # yticklabelcolor = variablecolors[oc],
            yaxisposition = :left,
            xgridvisible = false,
            ygridvisible = false,
            xminorgridvisible = false
        )
        
        if i == 1
            hidedecorations!(
                ax, ticks = false, ticklabels = false, label = false
            )
            hidedecorations!(
                ax, ticks = false, ticklabels = false, label = false
            )
        else
            hidespines!(ax)
            hidexdecorations!(ax)
            hideydecorations!(ax)
        end

        rb = rangebars!(
            ax,
            fs .+ offsets,
            lo, hi,
            color = variablecolors[oc],
            whiskerwidth = 0,
            label = ylabel,
            linewidth = 1.5*(4/5)
        );

        sctr = scatter!(
            ax, fs .+ offsets, att, markersize = 4, color = :black
        );

        mn = min(mn, minimum(lo))
        mx = max(mx, maximum(hi))

        push!(axises, ax);
        push!(rbs, rb);
        push!(sctrs, sctr);
    end

    yl = max(abs(mn), abs(mx))
    yl += yl * 0.1;

    xlmax = Fmax + 0.5

    for ax in axises; ylims!(ax, (-yl, yl)) end
    for ax in axises; xlims!(ax, (-0.5, xlmax)) end

    hlines!(
        axises[1], [0.0],
        color = (:black, 0.6), linestyle = :dash, linewidth = 0.8
    )

    vlx = collect(-0.5:40.5);

    vlines!(
        axises[1], vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )

end
