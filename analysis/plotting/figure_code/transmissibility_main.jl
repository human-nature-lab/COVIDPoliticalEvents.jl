# transmissibility_main.jl

function rt_main(;
    savepath = nothing,
    format = ".svg",
    basepath = "Rt out/"
)

    xlabel = "Day"; ylabel = L"R_{t}";

    models = [
        "primary full_Rt_.jld2",
        "ga epi_Rt_.jld2",
        "gub nomob_Rt_.jld2",
        "rally nomob_Rt_exposure.jld2",
        "protest nomob_Rt_.jld2"
    ];

    ms = Vector{Any}(undef, 5)
    for (i, m) in enumerate(models)
        ms[i] = JLD2.load_object(basepath * m).refcalmodel;
    end

    # COLORS

    variablecolors = colorvariables();

    size_inches = (180 * 3, 180 * 2) .* inv(25.4) .* 1
    size_pt = 72 .* size_inches

    # FIGURE

    size_inches = (180, 180 * 0.75) .* inv(25.4)
    size_pt = 72 * 2 .* size_inches

    f = Figure(
        backgroundcolor = RGB(0.98, 0.98, 0.98),
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
        axises[1], [0.0], color = :black, linestyle = :dash, linewidth = 0.8
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
        axises[1], [0.0], color = :black, linestyle = :dash, linewidth = 0.8
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
            textsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    rowsize!(f.layout, 3, Auto(0.2))
    rowgap!(f.layout, 5)
    colgap!(panelB, 5)

    if !isnothing(savepath)
        save(savepath * "Rt" * "_panel" * format, f, pt_per_unit = 1)
    end

    return f
end
