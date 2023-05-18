# inner_functions.jl

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
