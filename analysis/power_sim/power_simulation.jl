# power_simulation.jl

function simulation(
    m, placiterations, dat, rate_jump, outmap;
    randomunit = false,
    jumpdist = nothing
)
    attsmat = Matrix{Float64}(undef, length(m.F), placiterations);
    lwrmat = similar(attsmat);
    uprmat = similar(attsmat);
    semat = similar(attsmat);
    othercounts = similar(attsmat);

    olwr = Vector{Float64}(undef, placiterations);
    oupr = similar(olwr);

    # Ys, Us = unitcounts(m);
    treatdex = treatedmap(m.observations);
    # boots, tcountmat = setup_bootstrap(length(m.F), m.iterations);

    repeats!(
        attsmat, lwrmat, uprmat, semat,
        # boots, tcountmat,
        othercounts,
        olwr, oupr,
        treatdex,
        m, outmap, placiterations, rate_jump, dat, (0.025, 0.975),
        randomunit, jumpdist
    )

    return attsmat, lwrmat, uprmat, semat, olwr, oupr
end

function simulations!(
    sim_results, sim_results_oe,
    m, placiterations, dat, outmap;
    randomunit = false,
    rnge = 0.05:0.005:0.1
)
    for e in rnge
        @time attsmat, lwrmat, uprmat, semat, olwr, oupr = simulation(
            m, placiterations, dat, e, outmap;
            randomunit = randomunit,
            jumpdist = Normal(e, e)
        );

        sim_res = DataFrame(
            :ATT => vec(mean(attsmat, dims = 2)),
            Symbol("2.5%") => vec(mean(lwrmat, dims = 2)),
            Symbol("97.5%") => vec(mean(uprmat, dims = 2)),
            :se => vec(mean(semat, dims = 2)),
            :power => vec(sum(lwrmat .> 0.0, dims = 2) ./ size(lwrmat)[2])
        )

        sim_res[!, :f] .= collect(m.F);
        sim_res[!, :jump] .= e;
        
        sim_res_oe = DataFrame(
            :ATT => mean(sim_res.ATT),
            Symbol("2.5%") => mean(olwr),
            Symbol("97.5%") => mean(oupr),
            :power => sum(olwr .> 0.0) ./ length(olwr)
        )

        append!(sim_results, sim_res)
        append!(sim_results_oe, sim_res_oe)

        if (mean(sim_res[!, :power]) > 0.8) & (mean(sim_res_oe[!, :power]) > 0.8)
            break
        end
    end
    return sim_results, sim_results_oe
end

# @time gb = groupby(dat2, [:running, :fips]);
# @time gb = groupby(dat2, [:key]);

# @time gb[(key = (0, 1001),)].death_rte[1];

# @time dat[gix[(6, 1001)][1], :death_rte]

function powersimulation(
    m, dat;
    placiterations = 1000, randomunit = false,
    rnge = 0.05:0.01:0.14
)

    outmap = outcomemap(dat);

    sim_results, sim_results_oe = setup_objects();

    simulations!(
        sim_results, sim_results_oe, m, placiterations, dat, outmap;
        randomunit = randomunit,
        rnge = rnge
    )

    sim_results, sim_results_oe
end
