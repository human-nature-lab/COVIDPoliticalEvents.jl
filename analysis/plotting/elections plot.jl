# elections plot

function elections_plot(
    xlabel, ylabels, outcomecolors, offsets, savepth, format
)

    # FIGURE

    offsets = (0.15, 0.15)

    size_inches = (180, 180 * 0.75) .* inv(25.4)
    size_pt = 72 * 2 .* size_inches

    f = Figure(
        backgroundcolor = RGB(0.98, 0.98, 0.98),
        resolution = size_pt, fontsize = 12 * 1
    );

    panelA = f[1,1] = GridLayout()
    panelB = f[2,1] = GridLayout()
    panelC = f[3,1] = GridLayout()
    panelD = f[:,2] = GridLayout()

    ylabels = (
        "Death rate (per 10,000)", "Case rate (per 10,000)"
    )
    xlabel = "Day"
    outcomecolors = (
        TSCSMethods.gen_colors(3)[3], TSCSMethods.gen_colors(3)[2]
    );

    ## PANEL A

    modspth = "primary out/"
    overalldeathmod = " primary full_death_rte_.jld2"
    overallcasemod = " primary full_case_rte_.jld2"
    
    primary_dth = load_object(modspth * overalldeathmod).refcalmodel.results;
    primary_cse = load_object(modspth * overallcasemod).refcalmodel.results;

    # stratdeathmod = " primary full_death_rte_In-person Turnout Rate.jld2"
    # stratcasemod = " primary full_case_rte_In-person Turnout Rate.jld2"

    # smd = load_object(modspth * stratdeathmod);
    # smc = load_object(modspth * stratcasemod);


    add_att_axis!(
        panelA, primary_dth, primary_cse, 
        xlabel, ylabels, outcomecolors, offsets
    )

    ## PANEL B

    gamod_case = "ga out/ ga nomob_case_rte_.jld2"
    gamod_death = "ga out/ ga nomob_death_rte_.jld2"
    gubmod_case = "gub out/ gub out nomob_case_rte_.jld2"
    gubmod_death = "gub out/ gub out nomob_death_rte_.jld2"

    ga_dth = load_object(gamod_death).refcalmodel.results;
    ga_cse = load_object(gamod_case).refcalmodel.results;

    add_att_axis!(
        panelB, ga_dth, ga_cse, 
        xlabel, ylabels, outcomecolors, offsets
    )

    ## PANEL C

    gub_dth = load_object(gubmod_death).refcalmodel.results;
    gub_cse = load_object(gubmod_case).refcalmodel.results;

    add_att_axis!(
        panelC, gub_dth, gub_cse, 
        xlabel, ylabels, outcomecolors, offsets
    )

    ## PANEL D

    m1 = smd.refcalmodel.results; m2 = smc.refcalmodel.results;
    labels = smd.refcalmodel.labels;

    strata = if unique(m1.stratum) == unique(m2.stratum)
        unique(m1.stratum)
    else
        error("strata problem")
    end

    panelDpositions = [(1,1), (1,2), (2,1), (2,2)]
    for (s, fCpos) in zip(1:4, panelDpositions) # skip missing turnout counties

        fmin, fmax, fs, atts, lwr, upr = extract(m1, m2, s);
        intr = 5
        xt = collect(fmin:intr:fmax);
        mds, mcs = get_ylims(lwr, upr)

        # stratum-level
        f_i = panelD[fCpos...]

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
            label = ylabels[1]
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
            label = "cases"
        );

        sc_c = scatter!(
            axi_c, fs[2] .- offsets[2], atts[2], markersize = 3, color = :black
        );

        # xlims!(axm1, [8.75, 41.75])
        # xlims!(axm2, [9.25, 42.25])

        xlims!(axi_d, [9.5, 40.5])
        xlims!(axi_c, [9.5, 40.5])

        ylims!(axi_d, (-mds, mds))
        ylims!(axi_c, (-mcs, mcs))

        hlines!(
            axi_d, [0.0], color = :black, linestyle = :dash, linewidth = 0.8
        )

        hidedecorations!(axi_d, ticks = false, ticklabels = false, label = false)
        hidedecorations!(axi_c, ticks = false, ticklabels = false, label = false)

        vlx = collect(9.5:40.5);

        vlines!(
            axi_d, vlx,
            color = :black, linestyle = nothing, linewidth = 0.2
        )
    end

    for (label, layout) in zip(["A", "B"], [panelA, panelB])
        Label(layout[1, 1, TopLeft()], label,
            textsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    rowsize!(f.layout, 1, Auto(0.5))
    rowgap!(f.layout, 5)
    colgap!(panelB, 5)

    save(
        savepth * "primary" * "_panel" * format,
        f,
        pt_per_unit = 1
    )
    
    return f
end
