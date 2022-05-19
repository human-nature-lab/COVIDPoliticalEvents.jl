# multiple outcome plotting

function extract(oc, results)
    est_name = "att_" * string(oc);
    ci_names = (string(oc) * "_2.5%", string(oc) * "_97.5%")

    att = results[!, Symbol(est_name)]
    lwr = results[!, Symbol(ci_names[1])]
    upr = results[!, Symbol(ci_names[2])]

    return att, lwr, upr
end

function colorvariables()

    vn = VariableNames()

    pal = TSCSMethods.gen_colors(13)

    variablecolors = Dict(
        vn.cdr => pal[3],
        vn.ccr => ColorSchemes.mk_8[8],
        vn.fc => pal[11],
        vn.pd => pal[4],
        vn.res => pal[5],
        vn.groc => pal[7],
        vn.rec => pal[2],
        vn.pbl => pal[12],
        vn.phi => pal[8],
        vn.ts16 => pal[9],
        vn.mil => pal[10],
        vn.p65 => pal[6],
        vn.rare => pal[13],
    );
    return variablecolors
end

function mobility_plots(
    modelpath,
    xlabel, ylabel;
    selected = nothing,
    savepath = "", format = ".svg", scenario = ""
)

    modelobject = JLD2.load_object(modelpath);
    m1 = modelobject.refcalmodel;
    
    if isnothing(selected)
        selected = m1.outcome;
    end

    # COLORS

    variablecolors = colorvariables()

    # FIGURE
    f = Figure(
        backgroundcolor = RGBf(0.98, 0.98, 0.98),
        resolution = (1500, 900)
    );

    panelA = f[1,1:2] = GridLayout()
    pa1 = panelA[1,1]
    panelB = f[2,1:2] = GridLayout()
    pb1 = panelB[1,1]; pb2 = panelB[1,2]

    ## PANEL A

    # wherever an axis was plotted into a position, we plot N axises into
    # that position

    @unpack F, results, covariates, balances = m1
    fmin, fmax = F[1], F[end]
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
            pa1,
            ylabel = ylabel,
            xlabel = xlabel,
            xticks = xt,
            # yticklabelcolor = variablecolors[oc],
            yaxisposition = :left,
            grid = false,
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
            whiskerwidth = 8,
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
    yl += 100;

    for ax in axises; ylims!(ax, (-yl, yl)) end
    for ax in axises; xlims!(ax, (-0.5, 40.5)) end

    hlines!(axises[1], [0.0], color = :black, linestyle = :dash, linewidth = 1.5)

    vlx = collect(-0.5:40.5);

    vlines!(
        axises[1], vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )

    ## PANEL B

    matchwindow = -30:1:-1;

    xtcb = collect(
        range(
            minimum(matchwindow), stop = maximum(matchwindow);
            step = intr
        )
    );

    axcb = Axis(
        pb1,
        xlabel = xlabel,
        ylabel = "Balance Score",
        xticks = xtcb,
        xgridvisible = false,
        ygridvisible = false,
        xminorgridvisible = false,
        xminorticksvisible = false,
        xminorticks = IntervalsBetween(intr)
    );

    covariates = sort([k for k in keys(balances)]);

    # covals = Vector{Vector{Float64}}(undef, length(covariates));
    covals = Matrix{Float64}(
        undef, length(covariates), length(matchwindow)
    );

    for (c, covar) in enumerate(covariates)
        vals = balances[covar];
        if length(vals) == 1
            covals[c, :] = fill(vals, length(matchwindow))
        else
            covals[c, :] = vals;
        end
    end

    ser = series!(
        axcb,
        collect(matchwindow),
        covals,
        labels = [string(covar) for covar in covariates],
        markersize = 5,
        color = [variablecolors[covar] for covar in covariates]
    );

    hlines!(
        axcb, [-0.1, 0.1],
        color = :black, linestyle = :dash, linewidth = 0.2
    )

    ylims!(axcb, (-0.2, 0.2))
    xlims!(axcb, (-30,-1))

    legcb = Legend(
        pb2, axcb, "Covariates",
        nbanks = 6;
        framevisible = false,
        labelsize = 12,
        position = :left,
        tellheight = false,
        # margin = (-130, 30, 30, 30),
        # halign = ha, valign = va,
        orientation = :horizontal
    )
    
    colsize!(pb1.layout, 1, Auto(1.75))

    if !isnothing(savepath)
        save(savepath * scenario * "_panel" * format, f)
    end

    return f
end

function mobility_stratified(
    modelpath,
    xlabel, ylabel;
    selected = nothing,
    savepath = "", format = ".svg", scenario = ""
)

    modelobject = JLD2.load_object(modelpath);
    m1 = modelobject.refcalmodel;
    
    if isnothing(selected)
        selected = m1.outcome;
    end

    # COLORS

    variablecolors = colorvariables()

    # FIGURE
    f = Figure(
        backgroundcolor = RGBf(0.98, 0.98, 0.98),
        resolution = (1600, 900)
    );

    panelA = f[1:2,1:2] = GridLayout()
    panelB = f[3,1:2] = GridLayout()
    pb = panelB[3,1]
    # pa1 = panelA[1,1]
    # pa2 = panelA[1,2]
    # pa3 = panelA[2,1]
    # pa4 = panelA[2,2]

    pas = [panelA[1,1], panelA[1,2], panelA[2,1], panelA[2,2]];

    # panelB = f[2,1:2] = GridLayout()
    # pb1 = panelB[1,1]; pb2 = panelB[1,2]

    ## PANEL A

    # wherever an axis was plotted into a position, we plot N axes into
    # that position

    @unpack F, results, covariates, balances = m1
    fmin, fmax = F[1], F[end]
    intr = 5
    xt = collect(fmin:intr:fmax);

    stratums = sort(unique(results.stratum))

    Ax = []
    for (pa, s) in zip(pas, stratums)

        subresults = @views results[results.stratum .== s, :]

        axises = []; sctrs = []; rbs = [];
        mn, mx = Inf, -Inf
        offsetvals = [-0.25, 0, 0.25]
        # ocols = TSCSMethods.gen_colors(3);
        for (i, oc) in enumerate(selected)

            att, lo, hi = extract(oc, subresults);
            fs = subresults.f
            offsets = zeros(Int, length(fs)) .+ offsetvals[i]

            ax = Axis(
                pa,
                title = m1.labels[s],
                ylabel = ylabel,
                xlabel = xlabel,
                xticks = xt,
                # yticklabelcolor = variablecolors[oc],
                yaxisposition = :left,
                grid = false,
                xgridvisible = false,
                ygridvisible = false,
                xminorgridvisible = false
            )
            
            if i == 1
                push!(Ax, ax)
            end

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
                whiskerwidth = 4,
                label = ylabel
            );

            sctr = scatter!(
                ax, fs .+ offsets, att, markersize = 3, color = :black
            );

            mn = min(mn, minimum(lo))
            mx = max(mx, maximum(hi))

            push!(axises, ax);
            push!(rbs, rb);
            push!(sctrs, sctr);
        end

        yl = max(abs(mn), abs(mx))
        yl += 100;

        for ax in axises; ylims!(ax, (-yl, yl)) end
        for ax in axises; xlims!(ax, (-0.5, 40.5)) end

        hlines!(axises[1], [0.0], color = :black, linestyle = :dash, linewidth = 1.5)

        vlx = collect(-0.5:40.5);

        vlines!(
            axises[1], vlx,
            color = :black, linestyle = nothing, linewidth = 0.2
        )
    end

    elem_1 = [LineElement(color = variablecolors[vn.rec], linestyle = nothing)]
    elem_2 = [LineElement(color = variablecolors[vn.res], linestyle = nothing)]
    elem_3 = [LineElement(color = variablecolors[vn.groc], linestyle = nothing)]

    Legend(
        f[3,1],
        [elem_1, elem_2, elem_3],
        [string(vn.res), string(vn.rec), string(vn.groc)];
        framevisible = false,
        labelsize = 12,
        position = :left,
        tellheight = false,
        orientation = :horizontal
    )

    rowsize!(f.layout, 2, Auto(20))

    if !isnothing(savepath)
        save(savepath * scenario * "_panel" * format, f)
    end


    return f
end
