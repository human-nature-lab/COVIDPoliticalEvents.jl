# combined analysis

include("postmortem_functions.jl")

Random.seed!(2019)

# parameters

#= practically, the only parameter that changes across models
is the outcome. for the paper, everything else stays the same
=#
covarspec = "full" # = ARGS[]
outcome = :case_rte; # rates only here
scenario = "combined ";
F = 10:40; L = -30:-1
refinementnum = 5; iters = 10000;
prefix = ""

# setup

dat, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath = dataload(
    "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/cvd_dat_use.jld2",
    "combined out/"
);

# extract info

par = "combined out/grace combined out";
drs = readdir(par);
files = drs[contains.(drs, "excluded")]

bals, matching = getmatchbal(par, files);

imp, oes = load_object("combined out/grace combined out/imputesets.jld2")
for e in imp; rename!(e, e.outcome[1] => :observed) end
imp = reduce(vcat, imp);
select!(imp, Not(:stratum))

# plots

## case-death rate plot
dth = imp[imp.outcome .== :death_rte, :];
cse = imp[imp.outcome .== :case_rte, :];

odth = oes[oes.outcome .== :death_rte, :];
ocse  = oes[oes.outcome .== :case_rte, :];

dbal = bals[:death_rte];
cbal = bals[:case_rte];

## execute plots
format = ".svg";
f = combined_case_death_plot(dth, cse, dbal, cbal)

plotpath = "combined plots/case_death_rte.svg";
save(plotpath , f)

## overall imputed

oes[oes.outcome .== :deaths, :];
oes[oes.outcome .== :cases, [:lwr, :upr]];

## SI plots

using DataFramesMeta
import TSCSMethods:@unpack

# just change the outcome below (e.g., to "death_rte)
m_dr = load_object(par * "/" * files[contains.(files, "case_rte")][1])
@subset!(m_dr.model.results, :stratum .== 1)
select!(m_dr.model.results, Not(:stratum))
@subset!(m_dr.refinedmodel.results, :stratum .== 1)
select!(m_dr.refinedmodel.results, Not(:stratum))
@subset!(m_dr.calmodel.results, :stratum .== 1)
select!(m_dr.calmodel.results, Not(:stratum))
@subset!(m_dr.refcalmodel.results, :stratum .== 1)
select!(m_dr.refcalmodel.results, Not(:stratum))
@reset m_dr.model.stratifier = Symbol("")
@reset m_dr.refinedmodel.stratifier = Symbol("")
@reset m_dr.calmodel.stratifier = Symbol("")
@reset m_dr.refcalmodel.stratifier = Symbol("")
@reset m_dr.model.balances = m_dr.model.balances[1]
@reset m_dr.refinedmodel.balances = m_dr.refinedmodel.balances[1]
@reset m_dr.calmodel.balances = m_dr.calmodel.balances[1]
@reset m_dr.refcalmodel.balances = m_dr.refcalmodel.balances[1]

modelfigure(m_dr, dat, scenario, plotpath, ".svg")
