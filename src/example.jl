# example.jl

using tscsmethods, COVIDPoliticalEvents
using Dates, DataFrames, DataFramesMeta

using Random
Random.seed!(2019)

dat = load_object("/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/cvd_dat.jld2");

# base model

cc = deathmodel("test", :primary, :epi);

dataprep!(
  dat, cc;
  remove_incomplete = false,
  incomplete_cutoff = nothing
)

@time match!(cc, dat; distances = true);

@time balance!(cc, dat);

chk = balancecheck(cc);

@time estimate!(cc, dat; iter = 500);

ccr = make_refined(cc; refinementnum = 5);

@time estimate!(ccr, dat; iter = 500);

## caliper model

caliper = Dict(
  covariates[1] => 0.5,
  covariates[2] => 0.5,
  covariates[3] => 0.5
);

@time cal = make_caliper(cc, caliper);

@time estimate!(cal, dat; iter = 500);

@time calr = make_refined(cal; refinementnum = 5);

@time estimate!(calr, dat; iter = 500);

# stratification model

@time cc, labels = stratify!(datestrat!, [cc]);

ccr_chk = balancecheck(ccr);

@time estimate!(cc, dat; iter = 500);

ccr = make_refined(cc; refinementnum = 5);

@time estimate!(ccr, dat; iter = 500);

## caliper

caliper = Dict(
  covariates[1] => 0.5,
  covariates[2] => 0.5,
  covariates[3] => 0.5
);

@time cal = make_caliper(cc, caliper);

@time estimate!(cal, dat; iter = 500);

@time calr = make_refined(cal; refinementnum = 5);

@time estimate!(calr, dat; iter = 500);
