# mobility_main.jl

function mobility_main(;
    maxwindow = 20,
    format = ".svg",
    savepath = nothing
)

    xlabel = "Day"; ylabel = "Adjusted total visits (per 1,000)";

    basepath = "mobility out/"
    modelpaths = [
        "mobility primary full_multiple_Full-Service Restaurants_.jld2",
        "mobility ga full_multiple_Full-Service Restaurants_.jld2",
        "mobility gub full_multiple_Full-Service Restaurants_.jld2",
        "mobility rally full_multiple_Full-Service Restaurants_exposure.jld2",
        "mobility protest full_multiple_Full-Service Restaurants_.jld2"
    ];

    modelpaths = basepath .* modelpaths

    vn = VariableNames();

    # Colors
    variablecolors = colorvariables();

    # Figure

    size_inches = (180*0.5, 180) .* inv(25.4)
    size_pt = 72 * 2 .* size_inches

    f = Figure(
        backgroundcolor = RGBf(0.98, 0.98, 0.98),
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
        modelobject = JLD2.load_object(modelpath);
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
        position = :left,
        tellheight = false,
        tellwidth = false,
        orientation = :horizontal,
        nbanks = 1
    )

    for (label, layout) in zip(["a", "b", "c", "d", "e"], panels)
        Label(layout[1, 1, TopLeft()], label,
            textsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    # rowsize!(f.layout, 1, Auto(0.5))
    rowsize!(f.layout, 6, Auto(0.3))
    rowgap!(f.layout, 5)

    if !isnothing(savepath)
        save(savepath * "mobility" * "_panel" * format, f, pt_per_unit = 1)
    end

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
            whiskerwidth = 0,
            label = ylabel
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

    hlines!(axises[1], [0.0], color = :black, linestyle = :dash, linewidth = 1.5)

    vlx = collect(-0.5:40.5);

    vlines!(
        axises[1], vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )

end
