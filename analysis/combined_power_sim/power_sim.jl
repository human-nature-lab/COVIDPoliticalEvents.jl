# power_sim.jl

import Pkg
Pkg.activate(".")

using Random
Random.seed!(2019)

pth = "combined_power_sim/"
push!(ARGS, "nomob")

include("../power_sim/power_sim_base.jl")

include("../parameters.jl");
include("preamble.jl");

m = refcalmodel = load_object(pth * "overall_refcalmodel_" * ARGS[1] * ".jld2");

m = filter_treated(m; keepstratum = 1)

##

# this is on the per 10K scale (same as the outcome)
# rate_jump = 0.05;

# jumpdist = Normal(0.05, 0.025)
# jd = rand(jumpdist, 10000);
# quantile(jd, (0.025, 0.2, 0.5, 0.8, 0.975))

sim_results, sim_results_oe = powersimulation(
    m, dat;
    placiterations = 5, randomunit = false,
    rnge = 0.00 # 0.05:0.01:0.14
)

save_object(
    pth * "overall_refcalmodel_pwr_" * ARGS[1] * ".jld2",
    [sim_results, sim_results_oe]
)

using JLD2, DataFrames, Statistics, StatsBase

sim_results, sim_results_oe = load_object(pth * "overall_refcalmodel_pwr_" * ARGS[1] * ".jld2")

sim_results

@chain sim_results begin
    groupby(:jump)
    combine(:ATT => mean, :power => mean)
end
