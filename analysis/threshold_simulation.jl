# threshold_simulation.jl

import Pkg
Pkg.activate(".")

using Random
Random.seed!(2019)

pth = "combined_power_sim/"
push!(ARGS, "nomob")

include("../parameters.jl")
include("preamble.jl");

## functions

redproc(overall::Tuple{Dict{Int64, Tuple{Float64, Vector{Float64}}}, Dict{Int64, Float64}}) = [overall[1][1][1], overall[1][1][2][1], overall[1][1][2][3], overall[2][1]]
redproc(coe::Tuple{Float64, Vector{Float64}}) = [coe[1][1], coe[1][2][1], coe[1][2][3], coe[2]]
mx(results) = mean.([results.treated, results.matches])

function mxstrat(results)
    x = results.treated[results.stratum .== 1]
    y = results.matches[results.stratum .== 1]
    mean.([x, y])
end

function setup()
    ttl = ["ATT", "2.5%", "97.5%", "Bayes Factor", "Avg. Treated", "Avg. Matches", "Caliper"]

    df = DataFrame([x => Float64[] for x in ttl])
    df[!, "Model"] = String[]
    return df
end

## setup

model = load_object(pth * "overall_" * string(outcome) * "_model_" * ARGS[1] * ".jld2")

df = setup()

## do

for c in [0.15, 0.1, 0.05, 0.025, 0.01] # [0.5, 0.25, 

  ibs = Dict(
    balvar => c #, vn.fc => 0.25,
    # vn.pbl => 0.25, vn.ts16 => 0.25
  )

  @time calmodel, refcalmodel, overall = autobalance(
    model, dat;
    calmin = 0.08, step = 0.00025,
    initial_bals = ibs,
    dooverall = true,
    bayesfactor = true
  );

  coe = estimate!(calmodel, dat; overall = true)
  push!(df, [redproc(coe)..., mxstrat(calmodel.results)..., c, "Caliper"])
  push!(df, [redproc(overall)..., mxstrat(refcalmodel.results)..., c, "Refined caliper"])
  # df[!, "Model"] = reduce(vcat, fill(["Caliper", "Refined caliper"], Int(nrow(df) / 2)))
end

save_object(pth * "thresh_sim" * ARGS[1] * ".jld2", df)
