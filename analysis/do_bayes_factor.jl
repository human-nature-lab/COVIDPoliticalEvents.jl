
using Parameters
import TSCSMethods:_estimate_strat!,applyunitcounts!
using Statistics, StatsBase

import TSCSMethods:processunits, stratifyinputs, setup_bootstrap, makefblocks, treatedmap,bootstrap!

iterations = model.iterations
overall = true
percentiles = [0.025, 0.5, 0.975]

begin
    @unpack results, matches, observations, strata, outcome, F, ids, reference, t, id = model; 
    modeliters = model.iterations;

    if !isnothing(iterations)
        @reset model.iterations = iterations;
    else
        iterations = modeliters
    end

    multiboots = Dict{Int, Matrix{Float64}}();
    multiatts = Dict{Int, Vector{Float64}}();

    _estimate_strat!(
        multiatts, multiboots,
        results, matches, observations, strata, outcome,
        F, ids, reference, t, id, iterations, percentiles,
        dat
    )
end

# begin    
#     applyunitcounts!(model)

#     overalls = Dict{Int, Tuple{Float64, Vector{Float64}}}()
#     if overall
#         for s in sort(unique(strata))
#             overalls[s] = (
#                 mean(multiatts[s]),
#                 quantile(vec(multiboots[s]), percentiles)
#             )
#         end
#         return overalls
#     end
# end

# bootstrap t

α = 0.05
lwr, upr = α/2, (1-α/2)

ests = multiatts[1]
B = multiboots[1];

b1 = B[1, :]
mean(b1)

e1 = ests[1]

# bootstrap distribution looks relatively normal!
qqnorm(b1)

include("bayes–factor-t-stat.jl")

tcounts
