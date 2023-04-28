# power_sim.jl

using Random
Random.seed!(2019)

push!(ARGS, "nomob")

include("power_sim_base.jl")

include("../parameters.jl")
include("../ga-election/preamble.jl");

refcalmodel = load_object("ga_refcalmodel_" * ARGS[1] * ".jld2")

m = refcalmodel;

##

# this is on the per 10K scale (same as the outcome)
# rate_jump = 0.05;

# jumpdist = Normal(0.05, 0.025)
# jd = rand(jumpdist, 10000);
# quantile(jd, (0.025, 0.2, 0.5, 0.8, 0.975))

sim_results, sim_results_oe = powersimulation(
    m, dat;
    placiterations = 5, randomunit = false,
    rnge = 0.05:0.01:0.07 #0.14
);

sim_results = @chain sim_results begin
    groupby(:jump)
    combine([x => mean => x for x in [:ATT, Symbol("2.5%"), Symbol("97.5%"), :se, :power]])
end

save_object("outname.jld2", [sim_results_out, sim_results_oe])

