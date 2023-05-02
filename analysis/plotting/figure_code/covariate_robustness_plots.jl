# covariate_robustness_plots.jl

using DataFrames, DataFramesMeta, CairoMakie, JLD2
using TSCSMethods
import COVIDPoliticalEvents:VariableNames

include("covariate_robustness_plots_functions.jl")

models = [
    "ga-election/ga_death_rte_refcalmodel_epi.jld2",
    "gub-elections/gub_death_rte_refcalmodel_epi.jld2",
    "primary-elections/primary_death_rte_refcalmodel_epi.jld2",
    "primary-elections/primary_death_rte_refcalmodel_nomob.jld2",
    "blm-protests/blm_death_rte_refcalmodel_epi.jld2",
    "trump-rallies/rally_death_rte_refcalmodel_epi.jld2",
    "combined_power_sim/overall_death_rte_refcalmodel_epi.jld2",
    "combined_power_sim/overall_death_rte_refcalmodel_nomob.jld2"
];

outpth = "covariate_robust_plots/"

for modelfile in models
    m = load_object(modelfile)

    fg = covrob_plot(m)
    mf = split(modelfile, ".jld2")[1]
    mf = split(mf, "/")[2]
    save(outpth * mf * ".svg", fg)
end

##

casemodels = [
    "ga-election/ga_case_rte_refcalmodel_epi.jld2",
    "gub-elections/gub_case_rte_refcalmodel_epi.jld2",
    "primary-elections/primary_case_rte_refcalmodel_epi.jld2",
    "primary-elections/primary_case_rte_refcalmodel_nomob.jld2",
    "blm-protests/blm_case_rte_refcalmodel_nomob.jld2",
    "trump-rallies/rally_case_rte_refcalmodel_epi.jld2",
    "combined_power_sim/overall_case_rte_refcalmodel_epi.jld2",
    "combined_power_sim/overall_case_rte_refcalmodel_nomob.jld2"
]

outpthc = "covariate_robust_plots_case/"

for modelfile in casemodels
    m = load_object(modelfile)

    fg = covrob_plot(m)
    mf = split(modelfile, ".jld2")[1]
    mf = split(mf, "/")[2]
    save(outpthc * mf * ".svg", fg)
end
