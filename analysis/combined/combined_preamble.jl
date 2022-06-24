# preamble.jl

push!(ARGS, "full")

include("../general_parameters.jl")

dat = deepcopy(dat_store)

Random.seed!(2019)

savepath = "combined out/"
scenario = "combined model";

obvars = [vn.pd, vn.ts16, :Exposure];

treatments = [:primary, :gaspecial, :gub, :rallydayunion, :protest]

# setup exclude variable
# where a unit is a protest or rally,
# but is exposure > 1 or less than 800 persons
dat[!, :exclude] .= 0

# remove early primaries
dat[(dat[!, :date] .< Date("2020-03-10")) .& (dat[!, :primary] .== 1), :exclude] .= 1
# remove big-enough-to-be-treated protests
dat[(dat[!, :prsize] .< 800) .& (dat[!, :protest] .== 1), :exclude] .= 1

# remove rally exposures less than direct treatment
dat[(dat[!, :Exposure] .>= 1) .& (dat[!, :rallydayunion] .== 1), :exclude] .= 1

# adj mat, fips => row / col, row / col => fips
adjmat, id2rc, rc2id = COVIDPoliticalEvents.getneighbordat();

# adjacent to GA
trtment = :gaspecial;

# for each county-timetreated
# look for the set of adjacent counties, if not treated already
# treat and mark as excluded (these will necessarily be in other states)

# combine the treated into `political`
dat[!, :political] = 1 .* (sum([dat[!, trt] for trt in treatments]) .> 0)




model = deathmodel(
  scenario * ARGS[1], :political, Symbol(ARGS[1]) , dat,
  outcome;
  F = F, L = L,
  iterations = iters,
);

dat = dataprep(dat, model);
