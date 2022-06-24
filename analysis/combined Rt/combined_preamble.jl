# preamble.jl

push!(ARGS, "full")

include("../general_parameters.jl")

dat_store = begin
  epidat = CSV.read(
    "../../../covid-19-data/data/covidestim_estimates_2022-03-05.csv",
    DataFrame
  );

  select!(epidat, :fips, :date, Symbol("Rt")) #, Symbol("Rt.hi"), Symbol("Rt.lo"))
  dat_store = leftjoin(dat_store, epidat, on = [:fips, :date]);
end

dat = deepcopy(dat_store);

Random.seed!(2019)

savepath = "combined Rt out/"
scenario = "combined Rt model";

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

model = rtmodel(
  scenario * ARGS[1], :political, Symbol(ARGS[1]) , dat; iterations = iters,
);

dat = dataprep(dat, model, t_start = 0, convert_missing = false);
