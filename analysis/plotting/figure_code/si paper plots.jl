# SI plots

using TSCSMethods, COVIDPoliticalEvents, DataFrames, DataFramesMeta, Parameters, Accessors, Dates
import Colors, ColorSchemes
using CairoMakie
using JLD2

include("plot_utilities.jl")
include("main_paper_plot_functions.jl")
include("si_paper_plot_functions.jl")

vn = VariableNames();

dat = JLD2.load_object("covid-19-data/data/cvd_dat.jld2")
dat[!, :gaspec] .= 0;
dat[(dat.State .== "Georgia") .& (dat.running .== 310), :gaspec] .= 1;

add_recent_events!(dat, vn.t, vn.id, :protest; recency = 30)

# add GA turnout data, as variable `gaout`
ga_election = COVIDPoliticalEvents.ga_turnout(dat)
ed = Dict(ga_election[!, vn.id] .=> ga_election[!, vn.tout]);
dat[!, :gaout] .= 0.0;
tochng = @views dat[dat.State .== "Georgia", [vn.id, :gaout]];
for r in eachrow(tochng)
    r[:gaout] = ed[r[vn.id]]
end

primpth = "primary out/"
gapth = "ga out/"
rlpth = "rally out/"
prpth = "protest out/"
savepth = "covid-political-events-paper (working)/si_figures/"

# main paper diagnostics

main_diagnostic = [
    primpth * "primary full_death_rte_.jld2",
    primpth * "primary full_death_rte_In-person Turnout Rate.jld2",
    gapth * "ga full_death_rte_.jld2",
    gapth * "ga nomob_death_rte_In-person Turnout Rate.jld2",
    rlpth * "rally nomob_death_rte_exposure.jld2",
    prpth * "protest full_death_rte_.jld2",
    prpth * "protest nomob_death_rte_prsize.jld2"
];

plot_si_set(main_diagnostic, dat, savepth)

## primary models

si_primary = [
    primpth * "primary full_death_rte_Pop. Density.jld2",
    primpth * "primary full_death_rte_date.jld2",
    primpth * "primary full_death_rte_Region.jld2",
    primpth * "primary full_death_rte_Trump 2016 Vote Share.jld2",
    primpth * "primary full_death_rte_firstcase.jld2",
    primpth * "primary full_death_rte_Cum. Case Rate.jld2",
    primpth * "primary full_death_rte_Cum. Death Rate.jld2",    
]

si_other = [
    gapth * "ga nomob_death_rte_Trump 2016 Vote Share.jld2",
    gapth * "ga nomob_death_rte_Rarely Mask.jld2",
    prpth * "protest nomob_death_rte_Recent Protests.jld2",
]

plot_si_set([si_primary..., si_other...], dat, savepth)

# plot_si_set([primpth * "primary full_death_rte_firstcase.jld2"], dat, savepth)

## exposure x ts share rally

rx = rlpth * "rally nomob_death_rte_Exposure x Trump Share > 50%.jld2";

begin
    X = load_object(rx);

    better_labels = Dict(
        1 => "Degree 1, Trump Share > 50%",
        2 => "Degree 3, Trump Share > 50%",
        3 => "Degree 2, Trump Share > 50%",
        4 => "Treatment, Trump Share > 50%",
        5 => "Degree 1, Trump Share < 50%",
        6 => "Degree 3, Trump Share < 50%",
        7 => "Degree 2, Trump Share < 50%",
        8 => "Treatment, Trump Share < 50%"
    )

    @reset X.model.labels = better_labels;
    @reset X.refinedmodel.labels = better_labels;
    @reset X.calmodel.labels = better_labels;
    @reset X.refcalmodel.labels = better_labels;
   
    str = X.model.stratifier != Symbol("") ? string(X.model.stratifier) : ""
    scenario = X.model.title * " " * str;
    
    rally_ts_x_exposure_fig(
        X, scenario;
        savepth = "covid-political-events-paper (working)/si_figures/",
        format = ".svg"
    )
end

# case models

main_case = [
    primpth * "case primary full_case_rte_.jld2",
    primpth * "case primary full_case_rte_In-person Turnout Rate.jld2",
    gapth * "case ga full_case_rte_.jld2",
    gapth * "case ga nomob_case_rte_In-person Turnout Rate.jld2",
    rlpth * "case rally nomob_case_rte_exposure.jld2",
    prpth * "protest full_case_rte_.jld2",
    prpth * "protest nomob_case_rte_prsize.jld2"
];

plot_si_set(main_case, dat, savepth)

gubs = [
    "gub out/gub full_case_rte_.jld2",
    "gub out/gub full_death_rte_.jld2"
]

plot_si_set(gubs, dat, savepth)

# R_t models

basepath = "Rt out/"

rtmodels = [
    "primary full_Rt_.jld2",
    "ga epi_Rt_.jld2",
    "gub full_Rt_.jld2",
    "rally nomob_Rt_exposure.jld2",
    "protest full_Rt_.jld2"
];

rtmodels = basepath .* rtmodels

plot_si_set(rtmodels, dat, savepth)

# mobility models