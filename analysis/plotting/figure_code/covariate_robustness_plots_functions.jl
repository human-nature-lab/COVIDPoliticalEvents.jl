using Colors

function gen_colors(n)
    cs = Colors.distinguishable_colors(
        n,
        [colorant"#FE4365", colorant"#eca25c"],
        lchoices = Float64[58, 45, 72.5, 90],
        transform = c -> deuteranopic(c, 0.1),
        cchoices = Float64[20,40],
        hchoices = [75,51,35,120,180,210,270,310]
    )
    return convert(Vector{Color}, cs)
end

function colorvariables()

    vn = VariableNames();
    pal = gen_colors(15);

    variablecolors = Dict(
        vn.cdr => pal[3],
        vn.ccr => pal[2],
        vn.deathoutcome => pal[3],
        vn.caseoutcome => pal[2],
        vn.fc => pal[11],
        vn.pd => pal[4],
        vn.res => pal[5],
        vn.groc => pal[7],
        vn.rec => pal[1],
        vn.pbl => pal[12],
        vn.phi => pal[8],
        vn.ts16 => pal[9],
        vn.mil => pal[10],
        vn.p65 => pal[6],
        vn.rare => pal[13],
        vn.rt => pal[15],
        :deaths => pal[3],
        :cases => pal[2]
    );
    return variablecolors
end

function assign_ylabel(outcome)
    return if outcome == :case_rte
        "Case rate (per 10K pers.)"
    elseif outcome == :death_rte
        "Death rate (per 10K pers.)"
    elseif outcome == :deaths
        "Deaths"
    elseif outcome == :cases
        "Cases"
    else "ATT"
    end
end

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

function add_cb!(
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

function add_cb!(
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

            axcb, ln = add_cb!(
                g[i, 1], gb[s];
                matchwindow = -30:1:-1, intr = 5,
                xlabel = "Day", ylabel = yl, title = lab
            )

            push!(axs, axcb)
            push!(lns, ln)
        end
    else
        axcb, ln = add_cb!(
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
        backgroundcolor = RGBf(0.98, 0.98, 0.98),
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
        axcb, ln = add_cb!(
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

    for (label, layout) in zip(["A", "B"], [fa, fb])
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
