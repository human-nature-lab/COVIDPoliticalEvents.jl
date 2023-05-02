# pre-trend-plot-fn.jl

function _figure!(panelA, m1, m2, xlabel, outcomecolors, offsets)

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