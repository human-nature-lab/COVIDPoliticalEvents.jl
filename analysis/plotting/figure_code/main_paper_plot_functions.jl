# new paper plots

using TSCSMethods, COVIDPoliticalEvents, DataFrames, DataFramesMeta, Parameters, Accessors, Dates
import Colors, ColorSchemes
using CairoMakie
using JLD2

## outer functions

function mainfig(
    scenario, modspth, overallmod,
    stratmod, treatment, dat;
    savepth = nothing,
    format = ".png",
    stratifier = nothing
)

    oam = JLD2.load_object(modspth * overallmod);
    sm = JLD2.load_object(modspth * stratmod);

    # don't bother with 5th category for MAIN PAPER ONLY
    # (separate functions will be used for the SI plots)
    @subset!(sm.refcalmodel.results, :stratum .!= 5)
    
    f = Figure(
        backgroundcolor = RGBf(0.98, 0.98, 0.98),
        resolution = (1000, 900)
    );

    G = f[1:3,1:2] = GridLayout();
    gab = G[1:2, 1:2] = GridLayout(); # top row
    glg = gab[2, 1:2] = GridLayout(); # turnout atts
    glg1 = glg[1,1]; glg2 = glg[1,2];
    ga = gab[1, 1] = GridLayout(); # overall att
    gb = gab[1, 2] = GridLayout(); # overall cb
    gc = G[3, 1:2] = GridLayout(); # turnout atts

    ## panel a
    
    # overall att

    axs, rbs, scs = add_att_axis!(ga, oam.refcalmodel)

    # legatt = Legend(
    #     glg[1, 1], axs[1], "Outcome";
    #     framevisible = false,
    #     labelsize = 12,
    #     position = :lt,
    #     margin = (170, 10, 125, 10),
    #     # halign = ha, valign = va,
    #     orientation = :horizontal
    # );

    # overall cb

    axcb, ser = add_cb!(gb[1, 1], oam.refcalmodel);

    legcb = Legend(
        glg2, axcb, "Covariates",
        nbanks = 6;
        framevisible = false,
        labelsize = 12,
        position = :lt,
        margin = (-130, 30, 30, 30),
        # halign = ha, valign = va,
        orientation = :horizontal
    )

    colgap!(glg, 400)
    colgap!(gab, 10)

    rowgap!(gab, -30)
    rowgap!(G, -30)

    # colsize!(gab, 1, Relative(1/2))
    # colsize!(gab, 1, Aspect(1, 1.0))
    # colsize!(ga, 1, Aspect(1, 2.1))

    ## panel c
    
    # turnout atts

    axs2, rbs2, scs2 = add_att_axis!(gc, sm.refcalmodel)

    if length(axs2) > 2
        hideax = Int(ceil(length(axs2)/2));
    else
        hideax = 0
    end
    for a in 1:hideax
        hidexdecorations!(
            axs2[a], grid = false,
            ticks = false, minorticks = false,
            minorgrid = false
        )
    end

    colgap!(gc, 10)
    rowgap!(gc, -50)

    for (label, layout) in zip(["a", "b", "c"], [ga, gb, gc])
        Label(layout[1, 1, TopLeft()], label,
            textsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    if !isnothing(savepth)
        save(
            savepth * scenario * "_panel" * format,
            f
        )

    end

    return f
end

function mainfig_ga_et_gub(
    scenario,
    oa1, oa2;
    savepth = nothing,
    format = ".png"
)

    oa1 = JLD2.load_object(oa1p);
    oa2 = JLD2.load_object(oa2p);
    
    f = Figure(
        backgroundcolor = RGBf(0.98, 0.98, 0.98),
        resolution = (1000, 900)
    );

    G = f[1:2, 1:2] = GridLayout();
    gab = G[1, 1:2] = GridLayout(); # top row
    gcd = G[2, 1:2] = GridLayout(); # bottom row
    glg = gab[2, 1:2] = GridLayout(); # turnout atts
    glg2 = glg[1,2];
    ga = gab[1, 1] = GridLayout(); # overall att
    gb = gab[1, 2] = GridLayout(); # overall cb
    gc = gcd[2, 1] = GridLayout(); # overall att
    gd = gcd[2, 2] = GridLayout(); # overall cb

    ## panel a
    
    # overall att

    axs, rbs, scs = add_att_axis!(ga, oa1.refcalmodel)

    # legatt = Legend(
    #     glg[1, 1], axs[1], "Outcome";
    #     framevisible = false,
    #     labelsize = 12,
    #     position = :lt,
    #     margin = (170, 10, 125, 10),
    #     # halign = ha, valign = va,
    #     orientation = :horizontal
    # );

    # overall cb

    axcb, ser = add_cb!(gb[1, 1], oa1.refcalmodel);

    legcb = Legend(
        glg2, axcb, "Covariates",
        nbanks = 6;
        framevisible = false,
        labelsize = 12,
        position = :lt,
        margin = (-130, 30, 30, 30),
        # halign = ha, valign = va,
        orientation = :horizontal
    )

    colgap!(glg, 400)
    colgap!(gab, 10)

    rowgap!(gab, -30)
    rowgap!(G, -30)

    # colsize!(gab, 1, Relative(1/2))
    # colsize!(gab, 1, Aspect(1, 1.0))
    # colsize!(ga, 1, Aspect(1, 2.1))

    ## panel c
    
    # turnout atts

    axs2, rbs2, scs2 = add_att_axis!(
        gc, oa2.refcalmodel;
        ylabel = "", xlabel = "Day"
    )

    axcb2, ser2 = add_cb!(
        gd[1, 1], oa2.refcalmodel;
        ylabel = "", xlabel = "Day"
    );

    if length(axs2) > 2
        hideax = Int(ceil(length(axs2)/2));
    else
        hideax = 0
    end
    for a in 1:hideax
        hidexdecorations!(
            axs2[a], grid = false,
            ticks = false, minorticks = false,
            minorgrid = false
        )
    end

    rowgap!(gcd, -30)
    colgap!(gc, 10)
    rowgap!(gc, -50)
    rowgap!(G, -250)

    f

    for (label, layout) in zip(["a", "b", "c", "d"], [ga, gb, gc, gd])
        Label(layout[1, 1, TopLeft()], label,
            textsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    if !isnothing(savepth)
        save(
            savepth * scenario * "_panel" * format,
            f
        )

    end

    return f
end

function rallyfig(;
    modspth = "covid-19-political-events-analysis/grace out/rally out/",
    overallmod = "rally nomob_death_rte_exposure.jld2",
    savepth = nothing,
    format = ".png"
)

    sm = JLD2.load_object(modspth * overallmod);
    m = sm.refcalmodel
    
    f = Figure(
        backgroundcolor = RGBf(0.98, 0.98, 0.98),
        resolution = (1000, 900)
    );

    G = f[1:3,1:2] = GridLayout();
    gab = G[1:2, 1:2] = GridLayout(); # top row
    glg = gab[2, 1:2] = GridLayout(); # turnout atts
    glg1 = glg[1,1]; glg2 = glg[1,2];
    ga = gab[1, 1] = GridLayout(); # overall att
    gb = gab[1, 2] = GridLayout(); # overall cb
    gc = G[3, 1:2] = GridLayout(); # turnout atts

    ## panel a
    # overall att

    res1 = deepcopy(m.results)
    # 1 is treatment
    @subset!(res1, :stratum .== 1)
    select!(res1, Not(:stratum))

    axs, rbs, scs = add_att_axis!(ga, res1, m.outcome)

    # legatt = Legend(
    #     glg[1, 1], axs[1], "Outcome";
    #     framevisible = false,
    #     labelsize = 12,
    #     position = :lt,
    #     margin = (170, 10, 125, 10),
    #     # halign = ha, valign = va,
    #     orientation = :horizontal
    # );

    # overall cb

    axcb, ser = add_cb!(gb[1,1], m.balances[1]);

    legcb = Legend(
        glg2, axcb, "Covariates",
        nbanks = 6;
        framevisible = false,
        labelsize = 12,
        position = :lt,
        margin = (-130, 30, 30, 30),
        # halign = ha, valign = va,
        orientation = :horizontal
    )

    colgap!(glg, 400)
    colgap!(gab, 10)

    rowgap!(gab, -30)
    rowgap!(G, -30)

    # colsize!(gab, 1, Relative(1/2))
    # colsize!(gab, 1, Aspect(1, 1.0))
    # colsize!(ga, 1, Aspect(1, 2.1))

    ## panel c
    # exposed but not directly treated atts

    @subset!(m.results, :stratum .!== 1)
    axs2, rbs2, scs2 = add_att_axis!(gc, m)

    hideax = 1;
    for a in 1:hideax
        hidexdecorations!(
            axs2[a], grid = false,
            ticks = false, minorticks = false,
            minorgrid = false
        )
    end

    colgap!(gc, 10)
    rowgap!(gc, -50)

    for (label, layout) in zip(["a", "b", "c"], [ga, gb, gc])
        Label(layout[1, 1, TopLeft()], label,
            textsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    if !isnothing(savepth)
        save(
            savepth * "rally" * "_panel" * format,
            f
        )

    end

    return f
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

    res = m.results;
    fs = res[!, :f]; atts = res[!, :att];
    fmin, fmax = extrema(fs);
    lwr = res[!, lwrlab]; upr = res[!, uprlab];

    varcolors = colorvariables()
    outcome = m.outcome
    outcomecolor = varcolors[outcome]

    axs = [];
    rbs = [];
    scs = [];
    if "stratum" .∈ Ref(names(res))
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
                g[a,b],
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
            xlabel, ylabel,outcomecolor
        );
        push!(axs, axmain)
        push!(rbs, rb)
        push!(scs, sc)
    end
    
    return axs, rbs, scs
end

function add_att_axis!(
    g, res::DataFrame, outcome;
    lwrlab = Symbol("2.5%"),
    uprlab = Symbol("97.5%"),
    intr = 5,
    xlabel = "Day",
    ylabel = "Death rate (per 10,000 persons)",
    label = nothing
)

    varcolors = colorvariables()
    outcomecolor = varcolors[outcome]

    fs = res[!, :f]; atts = res[!, :att];
    fmin, fmax = extrema(fs);
    lwr = res[!, lwrlab]; upr = res[!, uprlab];

    axs = [];
    rbs = [];
    scs = [];
    if "stratum" .∈ Ref(names(res))
        strata = sort(unique(res.stratum));
        labels = nothing
        for (i, s) in enumerate(strata)
            cs = res.stratum .== s;
            a, b = isodd(i) ? (i, 1) : (i-1, 2)
            label = !isnothing(labels) ? labels[s] : nothing;
            axmain, rb, sc = _add_att_axis!(
                g[a,b],
                fs[cs], atts[cs], lwr[cs], upr[cs],
                fmin, fmax, intr,
                xlabel, ylabel,outcomecolor;
                label = label
            );
            push!(axs, axmain)
            push!(rbs, rb)
            push!(scs, sc)
        end
    else
        axmain, rb, sc = _add_att_axis!(
            g[1,1], fs, atts, lwr, upr, fmin, fmax, intr,
            xlabel, ylabel,outcomecolor; label = label
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
    xlabel = "Day", ylabel = "Balance score"
)

    cb = m.balances;
    
        xtcb = collect(
            range(
                minimum(matchwindow), stop = maximum(matchwindow);
                step = intr
            )
        );
    
        axcb = Axis(
            fposition,
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

        # ylims!(axcb, -0.2, 0.2)
        
    return axcb, ser
end

function add_cb!(
    fposition, cb::Dict;
    matchwindow = -30:1:-1, intr = 5,
    xlabel = "Day", ylabel = "Balance score"
)
    
        xtcb = collect(
            range(
                minimum(matchwindow), stop = maximum(matchwindow);
                step = intr
            )
        );
    
        axcb = Axis(
            fposition,
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

        # ylims!(axcb, -0.2, 0.2)
        
    return axcb, ser
end
