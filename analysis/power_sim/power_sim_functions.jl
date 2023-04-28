# placebo_functions.jl
import TSCSMethods:unitcounts, setup_bootstrap, makefblocks, treatedmap, bootstrap!,processunits,att!
using Distributions

## utilities

redproc(overall::Tuple{Dict{Int64, Tuple{Float64, Vector{Float64}}}, Dict{Int64, Float64}}) = [overall[1][1][1], overall[1][1][2][1], overall[1][1][2][3], overall[2][1]]
redproc(coe::Tuple{Float64, Vector{Float64}}) = [coe[1][1], coe[1][2][1], coe[1][2][3], coe[2]]

function interval!(lwr, upr, ses, boots, ptiles)
    for (i, r) in enumerate(eachrow(boots))
        lwr[i], upr[i] = quantile(r, ptiles)
        ses[i] = std(r)
    end
end

#=
function gamma_repar(mu, cv)
    shape = 1 / (cv^2)
    scale = mu * cv^2
  return shape, scale
end

""""
        death_dists()

Infection-to-death distribution to simulate treatments.
"""
function death_dists()
    α1, θ1 = gamma_repar(5.1, 0.86);
    α2, θ2 = gamma_repar(17.8, 0.45);

    d1 = Gamma(α1, θ1);
    d2 = Gamma(α2, θ2);
    return d1, d2
end

# simulate a death
death(d1, d2) = Int(round(rand(d1) + rand(d2); digits = 0))

=#

## setup

function outcomemap(dat)
    dat2 = dat[!, [:running, :fips]];
    dat2[!, :key] .= Vector{Tuple{Int, Int}}(undef, nrow(dat2));
    @floop for (i, (e, r)) in enumerate(zip(dat2.running, dat2.fips))
        dat2.key[i] = (e, r)
    end;

    select!(dat2, :key)
    tb = Table(dat2);
    return TypedTables.groupinds(tb.key)
end

# function makeoutmap(m, dat)
#     outmap = Dict{Tuple{Int, Int, Int, Int}, Int}();

#     for (tt, tu) in m.observations
#         for f in m.F
#             y = findfirst((dat.fips .== tu) .& (dat.running .== (tt + f)))
#             if !isnothing(y)
#                 outmap[(tt, tu, tu, f)] = y
#                 outmap[(tt, tu, tu, m.reference)] = findfirst((dat.fips .== tu) .& (dat.running .== tt + m.reference))                
#             end
#         end
#     end

#     for ((tt, tu), mtch) in zip(m.observations, m.matches)
#         for (col, f) in zip(eachcol(mtch.mus), m.F)
#             for (mdex, cval) in enumerate(col)
#                 if cval == true
#                     mu = m.ids[mdex] # match id                
#                     y = findfirst((dat.fips .== mu) .& (dat.running .== (tt + f)))
#                     if !isnothing(y)
#                         outmap[(tt, tu, mu, f)] = y
#                         outmap[(tt, tu, mu, m.reference)] = findfirst((dat.fips .== mu) .& (dat.running .== tt + m.reference))
#                     end
#                 end
#             end
#         end
#     end
#     return outmap
# end

## main functions

function repeats!(
    attsmat, lwrmat, uprmat, semat, othercounts,
    olwr, oupr,
    treatdex,
    m, outmap, placiterations, rate_jump, dat, ptiles,
    randomunit, jumpdist
)

    @floop for i in 1:placiterations
        @init boots = Matrix{Float64}(undef, length(m.F), m.iterations);
        @init tcountmat = Matrix{Float64}(undef, length(m.F), m.iterations);
        
        fill!(boots, 0.0);
        fill!(tcountmat, 0.0);
        
        atts = @views attsmat[:, i];
        tcounts = @views othercounts[:, i];

        lwr = @views lwrmat[:, i];
        upr = @views uprmat[:, i];
        ses = @views semat[:, i];

        fill!(atts, 0.0);
        fill!(tcounts, 0.0);

        simtreat!(
            dat[!, m.outcome], m, rate_jump, outmap, randomunit, jumpdist
        );

        ## estimation
        
        # estimaton setup

        # this may be the single most time-consuming and 
        # memory-intenstive piece
        X = processunits(
            m.matches, m.observations, m.outcome, m.F, m.ids,
            m.reference, m.t, m.id,
            dat
        );
        
        fblocks = makefblocks(X...);
        
        ##
        
        bootstrap!(boots, tcountmat, fblocks, m.ids, treatdex, m.iterations);
        
        att!(atts, tcounts, fblocks)
        interval!(lwr, upr, ses, boots, ptiles)

        # overall
        olwr[i], oupr[i] = quantile(vec(boots), ptiles)
    end
end

function setup_objects()
    sim_results = DataFrame(
        :ATT => Float64[],
        :f => Int[],
        :jump => Float64[],
        Symbol("2.5%") => Float64[],
        Symbol("97.5%") => Float64[],
        :se => Float64[],
        :power => Float64[]
    );

    sim_results_oe = DataFrame(
        :ATT => Float64[],
        Symbol("2.5%") => Float64[],
        Symbol("97.5%") => Float64[],
        :power => Float64[]
    );
    return sim_results, sim_results_oe
end