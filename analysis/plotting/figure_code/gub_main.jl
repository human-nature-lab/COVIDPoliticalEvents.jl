## GUB FIGURE

function gub_main(xlabel, ylabels, outcomecolors, offsets, savepth, format)

    gamod_case = "ga out/ ga nomob_case_rte_.jld2"
    gamod_death = "ga out/ ga nomob_death_rte_.jld2"
    gubmod_case = "gub out/ gub out nomob_case_rte_.jld2"
    gubmod_death = "gub out/ gub out nomob_death_rte_.jld2"

    gad = JLD2.load_object(gamod_death);
    gac = JLD2.load_object(gamod_case);

    gud = JLD2.load_object(gubmod_death);
    guc = JLD2.load_object(gubmod_case);

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

    hlines!(axm1, [0.0], color = :black, linestyle = :dash, linewidth = 0.8)

    hidedecorations!(axm1, ticks = false, ticklabels = false, label = false)
    hidedecorations!(axm2, ticks = false, ticklabels = false, label = false)

    vlx = collect(9.5:40.5);

    vlines!(
        axm1, vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )

    ## PANEL B

    m1 = gud.refcalmodel; m2 = guc.refcalmodel;

    fmin, fmax, fs, atts, lwr, upr = extract(m1, m2);
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

    for (label, layout) in zip(["a", "b"], [panelA, panelB])
        Label(layout[1, 1, TopLeft()], label,
            textsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    # rowsize!(f.layout, 1, Auto(0.5))
    rowgap!(f.layout, 5)
    colgap!(panelB, 5)

    save(
        savepth * "gub" * "_panel" * format,
        f,
        pt_per_unit = 1
    )
    return f
end
