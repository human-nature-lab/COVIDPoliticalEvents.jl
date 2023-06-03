# figure_code_combined.jl
# Functions to generate the combined figures

"""
    makeseries(cbi; variablecolors::Union{Dict, Nothing} = nothing)
Convert a grandbalances dictionary into a series, with labels and colors, to plot. Output goes into series!(), inputs a grandbalances object for a non-stratified analysis, or a single stratum.
variablecolors allows input of a custom color set.
"""
function makeseries(cbi; variablecolors = nothing)
  # length of time-varying coeff
  clen = maximum([length(v) for v in values(cbi)]);
  rlen = length(keys(cbi));
  labs = sort([k for k in keys(cbi)]);
  
  servals = Matrix{Float64}(undef, rlen, clen);
  for (r, lab) in enumerate(labs)
    vals = cbi[lab]
    if length(vals) == 1
      servals[r, :] .= vals;
    else
      servals[r, :] = vals
    end
  end

  if isnothing(variablecolors)
    varcol = mk_covpal(variablecolors)
  else
    varcol = variablecolors
  end
  
  sercols = [varcol[lab] for lab in labs];
  
  return servals, string.(labs), sercols
end

function getmatchbal(par, files)
    bals = Dict{Symbol, Dict}();
    matching = Dict{Symbol, DataFrame}();

    for file in files
        x = load_object(par * "/" * file);
        bals[x.refcalmodel.outcome] = x.refcalmodel.balances[1]
        obs = x.refcalmodel.observations[x.refcalmodel.strata .== 1]
        tus = DataFrame(:timetreated => [ob[1] for ob in obs], :treatedunit => [ob[2] for ob in obs]);
        tus = leftjoin(tus, x.matchinfo, on = [:timetreated, :treatedunit]);
        matching[x.refcalmodel.outcome] = tus
    end
    return bals, matching
end

function extract(
    dth::DataFrame, cse::DataFrame, s;
    lwrlab = Symbol("2.5%"), uprlab = Symbol("97.5%")
)
    
    didx = dth.stratum .== s

    res_d = dth[didx, :]
    fs_d = res_d[!, :f];
    atts_d = res_d[!, :att];
    fmin, fmax = extrema(fs_d);
    lwr_d = res_d[!, lwrlab];
    upr_d = res_d[!, uprlab];

    cidx = cse.stratum .== s

    res_c = cse[cidx, :];
    fs_c = res_c[!, :f];
    atts_c = res_c[!, :att];
    # fmin, fmax = extrema(fs);
    lwr_c = res_c[!, lwrlab]; upr_c = res_c[!, uprlab];
    return fmin, fmax, (fs_d, fs_c), (atts_d, atts_c), (lwr_d, lwr_c), (upr_d, upr_c)
end

function extract(
    dth::DataFrame, cse::DataFrame;
    lwrlab = Symbol("2.5%"), uprlab = Symbol("97.5%")
)

    res_d = dth[!, :]
    fs_d = res_d[!, :f];
    atts_d = res_d[!, :att];
    fmin, fmax = extrema(fs_d);
    lwr_d = res_d[!, lwrlab];
    upr_d = res_d[!, uprlab];

    res_c = cse[!, :];
    fs_c = res_c[!, :f];
    atts_c = res_c[!, :att];
    # fmin, fmax = extrema(fs);
    lwr_c = res_c[!, lwrlab]; upr_c = res_c[!, uprlab];
    return fmin, fmax, (fs_d, fs_c), (atts_d, atts_c), (lwr_d, lwr_c), (upr_d, upr_c)
end

function get_ylims(lwr::Tuple, upr::Tuple)

    exd = minimum(lwr[1]), maximum(upr[1])
    exc = minimum(lwr[2]), maximum(upr[2])

    md = maximum(abs.(exd))
    md = md + md * inv(10)
    # md = exd[findfirst(abs.(exd) .== md)]
    mc = maximum(abs.(exc))
    mc = mc + mc * inv(10)
    # mc = exd[findfirst(abs.(exc) .== mc)]
    return md, mc
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

function add_att_axis!(panel, dth, cse, xlabel, ylabels, outcomecolors, offsets)

    fmin, fmax, fs, atts, lwr, upr = extract(dth, cse);
    intr = 5
    xt = collect(fmin:intr:fmax);

    axm2 = Axis(
        panel[1,1],
        ylabel = ylabels[2],
        xticks = xt,
        yticklabelcolor = outcomecolors[2],
        yaxisposition = :right,
    );

    hidespines!(axm2)
    hidexdecorations!(axm2)

    axm1 = Axis(
        panel[1,1];
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
        axm1, [0.0],
        color = (:black, 0.6), linestyle = :dash, linewidth = 0.8
    )

    hidedecorations!(axm1, ticks = false, ticklabels = false, label = false)
    hidedecorations!(axm2, ticks = false, ticklabels = false, label = false)

    vlx = collect(9.5:40.5);

    vlines!(
        axm1, vlx,
        color = :black, linestyle = nothing, linewidth = 0.2
    )
end

function add_balance_axis!(
    panel, bal, title, pomin, pomax, step, variablecolors, oc
)
    
    servals, serlabs, sercols = makeseries(
        bal; variablecolors = variablecolors
    );

    axcb = Axis(
        panel[1,1],
        title = title,
        xticks = collect(range(pomin, stop = pomax; step = step)), # generalize
        xlabel = "Day",
        ylabel = "Balance Score",
        # yticklabelcolor = oc,
        xminorgridvisible = false,
        yminorgridvisible = false,
        # ymajorgridvisible = false,
        xminorticksvisible = false,
        xminorticks = IntervalsBetween(step)
    );

    ylims!(axcb, -0.15, 0.15)
    xlims!(axcb, pomin, pomax)
    hlines!(
        axcb, [-0.1, 0.1]; linestyle = :dot, linewidth = 0.8,
        color = :black
    )

    ser = series!(
        axcb,
        collect(range(pomin, pomax; step = 1)), # generalize
        servals,
        labels = serlabs,
        markersize = 5,
        color = sercols,
        linewidth = 1.5
    )
    hidexdecorations!(
        axcb, grid = true, ticks = false, ticklabels = false, label = false
    )

    return axcb
end

function combined_case_death_plot(dth, cse, dbal, cbal)

    ylabels = ("Death rate (per 10,000)", "Case rate (per 10,000)")
    xlabel = "Day"
    outcomecolors = (gen_colors(3)[3], gen_colors(3)[2]);

    # offset for death and case outcomes, relative to day in the center
    offsets = (0.15, 0.15)

    size_inches = (180, 180 * 0.75) .* inv(25.4)
    size_pt = 72 * 2 .* size_inches

    f = Figure(
        backgroundcolor = :transparent,
        resolution = size_pt, fontsize = 12 * 1
    );

    panelA = f[1,1:2] = GridLayout();
    panelB = f[2,1] = GridLayout();
    panelC = f[2,2] = GridLayout();

    ## PANEL A
    add_att_axis!(panelA, dth, cse, xlabel, ylabels, outcomecolors, offsets)

    ## Balance
    variablecolors = colorvariables()
    pomin = -30; pomax = -1; step = 2
 
    ### PANEL B
    axcb1 = add_balance_axis!(
        panelB, dbal, "Death rate", pomin, pomax, step,
        variablecolors, outcomecolors[1]
    )
    ### PANEL C
    axcb2 = add_balance_axis!(
        panelC, cbal, "Case rate", pomin, pomax, step,
        variablecolors, outcomecolors[2]
    )

    legcb = Legend(
        f[3,:], axcb1, "Matching covariates",
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
    
    for (label, layout) in zip(["a", "b", "c"], [panelA, panelB, panelC])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end
    return f
end
