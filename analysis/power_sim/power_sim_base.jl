# power_sim_deps.jl

import TSCSMethods:unitcounts, setup_bootstrap, makefblocks, treatedmap, bootstrap!,processunits,att!
using Distributions
using JLD2:save_object,load_object
using FLoops
using TypedTables

using Statistics, StatsBase
using DataFramesMeta

include("power_sim_functions.jl")
include("simtreat!.jl")
include("power_simulation.jl")


using Accessors
import COVIDPoliticalEvents:filter_treated
"""
    filter_treated(model; keepstratum = s)

remove observations based on stratum
"""
function filter_treated(model; keepstratum = 1)

    obinclude = model.strata .== keepstratum;
    @reset model.observations = model.observations[obinclude];
    @reset model.matches = model.matches[obinclude];
    # @reset model.results = TSCSMethods.DataFrame();

    # @reset model.treatednum = Dict{1 => length(model.observations)}

    return model
end
