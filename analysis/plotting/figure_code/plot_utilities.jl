# plot utilities

function extract(m1, m2; lwrlab = Symbol("2.5%"), uprlab = Symbol("97.5%"))
    res_d = m1.results;
    fs_d = res_d[!, :f];
    atts_d = res_d[!, :att];
    fmin, fmax = extrema(fs_d);
    lwr_d = res_d[!, lwrlab];
    upr_d = res_d[!, uprlab];

    res_c = m2.results;
    fs_c = res_c[!, :f];
    atts_c = res_c[!, :att];
    # fmin, fmax = extrema(fs);
    lwr_c = res_c[!, lwrlab]; upr_c = res_c[!, uprlab];
    return fmin, fmax, (fs_d, fs_c), (atts_d, atts_c), (lwr_d, lwr_c), (upr_d, upr_c)
end

function extract(m1, m2, s; lwrlab = Symbol("2.5%"), uprlab = Symbol("97.5%"))
    res_d = m1.results[m1.results.stratum .== s, :];
    fs_d = res_d[!, :f];
    atts_d = res_d[!, :att];
    fmin, fmax = extrema(fs_d);
    lwr_d = res_d[!, lwrlab];
    upr_d = res_d[!, uprlab];

    res_c = m2.results[m2.results.stratum .== s, :];
    fs_c = res_c[!, :f];
    atts_c = res_c[!, :att];
    # fmin, fmax = extrema(fs);
    lwr_c = res_c[!, lwrlab]; upr_c = res_c[!, uprlab];
    return fmin, fmax, (fs_d, fs_c), (atts_d, atts_c), (lwr_d, lwr_c), (upr_d, upr_c)
end

function get_ylims(m1, m2)

    if m1.stratifier == Symbol("")
        res_d = m1.results;
        res_c = m2.results;

        exd = minimum(res_d[!, Symbol("2.5%")]), maximum(res_d[!, Symbol("97.5%")])
        exc = minimum(res_c[!, Symbol("2.5%")]), maximum(res_c[!, Symbol("97.5%")])

        md = maximum(abs.(exd))
        md = md + md * inv(10)
        # md = exd[findfirst(abs.(exd) .== md)]
        mc = maximum(abs.(exc))
        mc = mc + mc * inv(10)
        # mc = exd[findfirst(abs.(exc) .== mc)]
        return md, mc
    else

        mds = []
        mcs = []
        for s in unique(m1.results.stratum)
            res_d = m1.results[m1.results.stratum .== s, :];
            res_c = m2.results[m2.results.stratum .== s, :];

            exd = minimum(res_d[!, Symbol("2.5%")]), maximum(res_d[!, Symbol("97.5%")])
            exc = minimum(res_c[!, Symbol("2.5%")]), maximum(res_c[!, Symbol("97.5%")])

            md = maximum(abs.(exd))
            md = md + md * inv(10)
            # md = exd[findfirst(abs.(exd) .== md)]
            mc = maximum(abs.(exc))
            mc = mc + mc * inv(10)
            # mc = exd[findfirst(abs.(exc) .== mc)]

            push!(mds, md)
            push!(mcs, mc)
        end
        return mds, mcs
    end
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

function extract(oc::Symbol, results::DataFrame; factor = 1000)
    est_name = "att_" * string(oc);
    ci_names = (string(oc) * "_2.5%", string(oc) * "_97.5%")

    att = results[!, Symbol(est_name)] .* inv(factor)
    lwr = results[!, Symbol(ci_names[1])] .* inv(factor)
    upr = results[!, Symbol(ci_names[2])] .* inv(factor)

    return att, lwr, upr
end

function extract(results::DataFrame)
    est_name = :att
    ci_names = ("2.5%", "97.5%")

    att = results[!, est_name]
    lwr = results[!, Symbol(ci_names[1])]
    upr = results[!, Symbol(ci_names[2])]

    return att, lwr, upr
end

function eventcolors(election)
    return if election
        ColorSchemes.Set1_5[[1, 3, 4]]
    else
        ColorSchemes.Set1_5[[2, 5]]
    end
end

function eventcolorinfo()

    events = [
        "Primaries", "GA special",
        "NJ & VA gubernatorial",
        "Trump rallies",
        "BLM protests"
    ]

    colvec = [eventcolors(true)...,eventcolors(false)...]

    return events, colvec
end

function colorvariables()

    vn = VariableNames();
    pal = TSCSMethods.gen_colors(15);

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
