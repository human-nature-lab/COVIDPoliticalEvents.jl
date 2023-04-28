# power_sim.jl

import Pkg
Pkg.activate(".")

using Random
Random.seed!(2019)

pth = "ga_power_sim/"
push!(ARGS, "nomob")

include("../power_sim/power_sim_base.jl")

include("../parameters.jl")
include("../ga-election/preamble.jl");

refcalmodel = JLD2.load_object("ga_refcalmodel_" * ARGS[1] * ".jld2");

m = refcalmodel;

##

# this is on the per 10K scale (same as the outcome)
# rate_jump = 0.05;

# jumpdist = Normal(0.05, 0.025)
# jd = rand(jumpdist, 10000);
# quantile(jd, (0.025, 0.2, 0.5, 0.8, 0.975))

sim_results, sim_results_oe = powersimulation(
    m, dat;
    placiterations = 50, randomunit = false,
    rnge = 0.05:0.025:0.1 # 0.05:0.01:0.14
)

@chain sim_results begin
    groupby(:jump)
    combine(:ATT => mean, :power => mean)
end

sim_results[!, :ATT] .< sim_results[!, Symbol("97.5%")]

save_object(
    pth * "ga_refcalmodel_pwr_" * ARGS[1] * ".jld2",
    [sim_results, sim_results_oe]
)

sim_results, sim_results_oe = load_object(pth * "ga_refcalmodel_pwr_" * ARGS[1] * ".jld2")
