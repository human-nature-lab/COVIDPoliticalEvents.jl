# base_model.jl

pth = "ga-election/"

push!(ARGS, "nomob")
push!(ARGS, "death_rte")

include("../parameters.jl")
include("preamble.jl");

@time match!(model, dat);

@time balance!(model, dat);

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

ibs = Dict(
  balvar => 0.25,
  # vn.rare => 0.1,
  # vn.fc => 0.15
);

Random.seed!(2019)
@time calmodel, refcalmodel, overall = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = ibs,
  dooverall = true,
  dobayesfactor = true,
  doestimate = true,
  dopvalue = true,
);

overall

#

# JSON3.write(
#   pth * refcalmodel.title * "_" * string(today()) * ".json", refcalmodel
# )

res = refcalmodel.results;
mean(res.att), mean(res[!, Symbol("2.5%")]), mean(res[!, Symbol("97.5%")])
mean(res.treated)

sum(res[!, Symbol("2.5%")] .> 0)

fg = covrob_plot(refcalmodel)
save("ga_refcal_other.svg", fg)

# save_object(pth * "ga_"  * string(refcalmodel.outcome) * "_refcalmodel_" * ARGS[1] * ".jld2", refcalmodel)

