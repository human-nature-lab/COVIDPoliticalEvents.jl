# inspection functions.jl

function dict_mk(dat, variable)
    odict = Dict{Tuple, Union{Float64, Missing}}();
    for r in eachrow(dat)
        odict[(r.running, r.fips)] = r[variable]
    end
    return odict
end

"""
Impute Y(0).
"""
function impute_results(m, matches, dat; stratum = 1)

    res = m.results;
    oc = m.outcome;
    
    if m.stratifier != Symbol("")
        @subset!(res, :stratum .== 1)
    end

    odict = dict_mk(dat, m.outcome);

    sf = if m.stratifier != Symbol("")
        DataFrame(
            :timetreated => [e[1] for e in m.observations],
            :treatedunit => [e[2] for e in m.observations],
            :stratum => m.strata
        );
    else
        DataFrame(
            :timetreated => [e[1] for e in m.observations],
            :treatedunit => [e[2] for e in m.observations],
        );
    end
    
    mfo = leftjoin(matches, sf, on = [:timetreated, :treatedunit]);

    if m.stratifier != Symbol("")
        # toss out the excluded observations
        @subset!(mfo, :stratum .== stratum)
    end

    mfo = @transform(mfo, $(vn.t) = :timetreated + :f);
    mfo[!, oc] .= 0.0;
    mfo[!, :match_values] .= 0.0;
    for r in eachrow(mfo)
        τ = r[:running]
        r[oc] = odict[(τ, r[:treatedunit])]
        mus = r[:matchunits]
        r[:match_values] = mean([odict[(τ, mu)] for mu in mus])
    end

    tobs = unique(mfo[!, [:timetreated, :treatedunit]]);
    mobs = unique(flatten(mfo, :matchunits)[!, [:timetreated, :matchunits]]);
    mobs[!, :τ] = mobs.timetreated .- 1;
    tobs[!, :τ] = tobs.timetreated .- 1;

    mobs[!, oc] .= 0.0;
    tobs[!, oc] .= 0.0;

    for u in eachrow(mobs)
        u[oc] = odict[(u[:τ], u[:matchunits])]
    end

    for u in eachrow(tobs)
        u[oc] = odict[(u[:τ], u[:treatedunit])]
    end

    mfosmy = @chain mfo begin
    groupby(:f)
    combine(
        oc => mean => oc,
        :match_values => mean => :match_values
    )
    end

    augres = leftjoin(res, mfosmy, on = :f);
    augres[!, :counter_post] = augres[!, oc] .- augres.att;

    # this needs to be fixed for abs
    mn, mx = sort([augres[!, oc] .- augres[!, Symbol("2.5%")], augres[!, oc] .- augres[!, Symbol("97.5%")]])

    augres[!, :counter_post_lwr] = mn
    augres[!, :counter_post_upr] = mx

    match_outcome_avg_pre = mean(mobs[!, m.outcome]);
    treated_outcome_avg_pre = mean(tobs[!, m.outcome]);

    augres[!, :pct] .= 0.0;
    augres[!, :pct_lo] .= 0.0;
    augres[!, :pct_hi] .= 0.0;

    for r in eachrow(augres)
        r[:pct] = change_pct(r[oc], r[:att])
        r[:pct_lo] = change_pct(r[oc], r[Symbol("2.5%")])
        r[:pct_hi] = change_pct(r[oc], r[Symbol("97.5%")])
    end

    return augres, match_outcome_avg_pre, treated_outcome_avg_pre
end

function change_pct(val, attval)
    return 100 * attval * inv(val - attval)
end

function pctδ(preval, ocval, attval)
    impval = ocval - attval
    return 100 * (impval - preval) * inv(preval + impval)
end

## plotting

using CairoMakie
import JLD2

function fill_axis!(ax1, t, dm, variables)
    lines!(ax1, t, dm[!, variables[1]], color = :blue)
    lines!(ax1, t, dm[!, variables[2]], color = :black)
    band!(t, dm[!, variables[3]], dm[!, variables[4]], color = (:grey, 0.3)) 
end

function fill_att!(ax2, t, dm; msize = 8)
    scatter!(ax2, t, dm[!, :att], color = :black, markersize= msize)
    rangebars!(ax2, t, dm[!, Symbol("2.5%")], dm[!, Symbol("97.5%")])
end

function figure_6(dm, overall, oc, stratum; msize = 8, plot_pct = false)
    fig = Figure();
    oe = overall[stratum];

    treated_observed_mean = mean(dm[!, oc]);
    overall_att = oe[1];
    lo_att = oe[2][1]; hi_att = oe[2][3];

    variables = [oc, :counter_post, :counter_post_lwr, :counter_post_upr];
    t = sort(unique(dm.f));

    ftop = fig[1, 1:2] = GridLayout();
    fbot = fig[2, 1:2] = GridLayout();
    if plot_pct
        fbotbot = fig[3,1:2] = GridLayout();
    end

    ax1 = Axis(fbot[1,1], ylabel = string(oc), xlabel = "Day");
    fill_axis!(ax1, t, dm, variables)
    mn, mx = extrema(t)
    xlims!(ax1, [mn - 0.75, mx + 0.25])

    ax2 = Axis(ftop[1,1], ylabel = string(oc));
    fill_att!(ax2, t, dm)
    xlims!(ax2, [mn - 0.75, mx + 0.25])

    ax3 = Axis(ftop[1,2]);

    scatter!(ax3, [9], [overall_att], color = :black, markersize = msize)
    rangebars!(ax3, [9], lo_att, hi_att)

    linkyaxes!(ax2, ax3)
    
    hideydecorations!(ax3, grid = false)
    hidexdecorations!(ax3)
    
    ## overall

    # mean
    # mean(treated outcome values) - mean(att estimate)
    # att > 0 -> treated values would be higher
    # att < 0 -> treated values would be lower
    br = treated_observed_mean - overall_att
    
    # 95% CI
    # mean(treated outcome value) - [lwr att est, upr att est]
    br_lo = treated_observed_mean - lo_att
    br_hi = treated_observed_mean - hi_att

    ax4 = Axis(fbot[1,2]);

    # blue: average for the treated counties
    # black: counterfactual average if they had not been tretaed
    scatter!(
        ax4, [3.25, 2.75], [br, treated_mean],
        color = [:black, :blue], markersize = msize
    )
    # add counterfactual at CI bounds
    rangebars!(ax4, [3.25], br_lo, br_hi)
    xlims!(ax4, [2.5, 3.5])

    hideydecorations!(ax4, grid = false)
    hidexdecorations!(ax4)

    linkyaxes!(ax1, ax4)

    colsize!(ftop, 2, Auto(0.04))
    colsize!(fbot, 2, Auto(0.04))

    for (label, layout) in zip(["a", "b"], [ftop, fbot])
        Label(layout[1, 1, TopLeft()], label,
            textsize = 26,
            padding = (0, 5, 5, 0),
            halign = :right)
    end


    if plot_pct
        ax5 = Axis(fbotbot[1,1], ylabel = "Pct. difference");
        scatter!(ax5, t, dm[!, :pct], color = :black, markersize = msize)
        rangebars!(ax5, t, dm[!, :pct_lo], dm[!, :pct_hi])

        ax6 = Axis(fbotbot[1,2]);
        cm = mean(dm.pct) # == change_pct(treated_observed_mean, oe[1])
        clo = change_pct(treated_observed_mean, oe[2][1])
        chi = change_pct(treated_observed_mean, oe[2][2])

        scatter!(
            ax6, [9], [cm],
            color = [:black], markersize = msize
        )
        # add counterfactual at CI bounds
        rangebars!(ax6, [9], clo, chi)
        # xlims!(ax6, [2.5, 3.5])

        linkyaxes!(ax5, ax6)
    
        hideydecorations!(ax6, grid = false)
        hidexdecorations!(ax6)

        colsize!(fbotbot, 2, Auto(0.04))
    end

    return fig
end

## balance

## balance

function fill_baxis!(bax, d_gb, t)
    for (k, v) in sort(d_gb[1])
        bl = if typeof(v) <: Vector
            v
        else
            fill(v, length(t))
        end
        lines!(bax, bl, label = string(k))
    end
end

function model_balance_plot(d_gb)

    bfig = Figure();
    bax = Axis(bfig[1,1], xlabel = "Day", ylabel = "Balance score");

    fill_baxis!(bax, d_gb, 10:40)
    Legend(bfig[1,2], bax, "Covariates", framevisible = false);
    ylims!(bax, -0.15, 0.15)

    hlines!(bax, [-0.1, 0.1]; linestyle = :dash, color = :black)
    hideydecorations!(bax, ticks = false, ticklabels = false, label = false)
    hidexdecorations!(bax, ticks = false, ticklabels = false, label = false)

    bax.xticks = (1:5:30, string.(collect(-30:5:-1)))

    return bfig
end

###

function inspection(fpth, fpth_oe)
    # fpth = death_rte_models[1]
    # fpth_oe = oe_death_rte[1]
    objet = load_object(fpth);
    ares, mcd_pre, tcd_pre, d_gb = impute_results(objet, dat);
    oe = load_object(fpth_oe);
    if typeof(oe) <: Dict
        oe = oe[1]
    end

    fig = figure_6(ares, oe, objet.refcalmodel.outcome)
    save(split(fpth, ".jld2")[1] * ".svg", fig)
    return fig, ares, oe, mcd_pre, tcd_pre, d_gb
end

function inspection(m, matches, overall)

    ares, mcd_pre, tcd_pre = impute_results(m, matches, dat);
    if typeof(overall) <: Dict
        overall = overall[1]
    end

    return ares, mcd_pre, tcd_pre
end

function plot_inspection(
    ares, overall, outcome;
    stratum = 1, spth = nothing,
    plot_pct = false
)
    fig = figure_6(ares, overall, outcome, stratum; plot_pct = plot_pct)
    if !isnothing(spth)
        save(split(spth, ".jld2")[1] * ".svg", fig)
    end
    return fig
end
