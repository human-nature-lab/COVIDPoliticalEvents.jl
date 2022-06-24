# model inspection.jl

include("general_parameters.jl")
dat = deepcopy(dat_store);
using Statistics, DataFramesMeta

death_rte_models = [
    "primary out/ primary full_death_rte_.jld2",
    "ga out/ ga nomob_death_rte_.jld2",
    "gub out/ gub out nomob_death_rte_.jld2",
    "rally out/ rally nomob_death_rte_exposure.jld2",
    "protest out/ protest nomob_death_rte_.jld2"
];

oe_death_rte = [
    "primary out/death_rte primary fulloverall_estimate.jld2",
    "ga out/death_rte ga nomoboverall_estimate.jld2",
    "gub out/death_rte gub out nomoboverall_estimate.jld2",
    "rally out/death_rte rally nomoboverall_estimate.jld2",
    "protest out/death_rte protest nomoboverall_estimate.jld2",
];

overall_models = [
    "combined out/combined modelfull_deaths_excluded.jld2",
    "combined out/combined modelfull_cases_excluded.jld2"
];

overall_oes = [
    "combined out/deathscombined modelfull overall_estimate.jld2",
    "combined out/casescombined modelfull overall_estimate.jld2"
];

scenarios = ["primary", "ga", "gub", "trump", "blm"];
# results = [];

include("inspection functions.jl")

i = 5

fpth = death_rte_models[i]
fpth_oe = oe_death_rte[i]
fig, ares, oe, mcd_pre, tcd_pre, d_gb = inspection(fpth, fpth_oe)

round(oe[1]; digits = 3)
round(oe[2][1]; digits = 3)
round(oe[2][3]; digits = 3)

## overall models

fig, ares, oe, mcd_pre, tcd_pre, d_gb = inspection(
    overall_models[1], overall_oes[1]
);

bfig = model_balance_plot(d_gb)