# combined analysis
# main and SI plots for the combined model

include("combined_plots_functions.jl")

Random.seed!(2019)

# parameters


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
format = ".pdf";
f = combined_case_death_plot(dth, cse, dbal, cbal)

# plotpath = "combined plots/case_death_rte.svg";
save(savepth * "Figure 2.pdf", f)

# ## overall imputed

# #= practically, the only parameter that changes across models
# is the outcome. for the paper, everything else stays the same
# =#
# covarspec = "full" # = ARGS[]
# outcome = :case_rte; # rates only here
# scenario = "combined ";
# F = 10:40; L = -30:-1
# refinementnum = 5; iters = 10000;
# prefix = ""

# # setup

# dat, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath = dataload(
#     "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/cvd_dat_use.jld2",
#     "combined out/"
# );

# oes[oes.outcome .== :deaths, :];
# oes[oes.outcome .== :cases, [:lwr, :upr]];

# ## SI plots

# using DataFramesMeta
# import TSCSMethods:@unpack

# # just change the outcome below (e.g., to "death_rte)
# m_dr = load_object(par * "/" * files[contains.(files, "case_rte")][1])
# @subset!(m_dr.model.results, :stratum .== 1)
# select!(m_dr.model.results, Not(:stratum))
# @subset!(m_dr.refinedmodel.results, :stratum .== 1)
# select!(m_dr.refinedmodel.results, Not(:stratum))
# @subset!(m_dr.calmodel.results, :stratum .== 1)
# select!(m_dr.calmodel.results, Not(:stratum))
# @subset!(m_dr.refcalmodel.results, :stratum .== 1)
# select!(m_dr.refcalmodel.results, Not(:stratum))
# @reset m_dr.model.stratifier = Symbol("")
# @reset m_dr.refinedmodel.stratifier = Symbol("")
# @reset m_dr.calmodel.stratifier = Symbol("")
# @reset m_dr.refcalmodel.stratifier = Symbol("")
# @reset m_dr.model.balances = m_dr.model.balances[1]
# @reset m_dr.refinedmodel.balances = m_dr.refinedmodel.balances[1]
# @reset m_dr.calmodel.balances = m_dr.calmodel.balances[1]
# @reset m_dr.refcalmodel.balances = m_dr.refcalmodel.balances[1]

# modelfigure(m_dr, dat, scenario, plotpath, ".svg")

# counts for Figure 2 caption

combined_counts = let
    sort!(dth, :f)
    sort!(cse, :f)

    x1 = select(dth, [:f, :treated, :matches])
    rename!(x1, :treated => :treated_deaths, :matches => :matches_deaths)
    
    x2 = select(cse, [:treated, :matches])
    rename!(x2, :treated => :treated_cases, :matches => :matches_cases)

    hcat(x1, x2)
end

CSV.write(savepth * "Figure 2 counts.csv", combined_counts)

vbles = [:treated_deaths, :matches_deaths, :treated_cases, :matches_cases];
av_counts = @chain combined_counts begin
    combine([v => mean => v for v in vbles])
end;

CSV.write(savepth * "Figure 2 average counts.csv", av_counts)
