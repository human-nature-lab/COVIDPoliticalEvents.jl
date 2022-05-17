# preamble.jl

push!(ARGS, "full")

include("general_parameters.jl")

dat = deepcopy(dat_store)

Random.seed!(2019)

savepath = "combined out/"
scenario = "combined model";

obvars = [vn.pd, vn.ts16, :Exposure];

treatments = [:primary, :gaspecial, :gub, :rallydayunion, :protest]

dat[!, :exclude] .= 0
# remove early primaries
dat[(dat[!, :date] .< Date("2020-03-10")) .& (dat[!, :primary] .== 1), :exclude] .= 1
dat[(dat[!, :prsize] .< 800) .& (dat[!, :protest] .== 1), :exclude] .= 1
dat[(dat[!, :Exposure] .>= 1) .& (dat[!, :rallydayunion] .== 1), :exclude] .= 1

dat[!, :political] = 1 .* (sum([dat[!, trt] for trt in treatments]) .> 0)

# setup exclude variable
# where a unit is a protest or rally,
# but is exposure > 1 or less than 800 persons

model = deathmodel(
  scenario * ARGS[1], :political, Symbol(ARGS[1]) , dat,
  outcome;
  F = F, L = L,
  iterations = iters,
);

dat = dataprep(dat, model);
