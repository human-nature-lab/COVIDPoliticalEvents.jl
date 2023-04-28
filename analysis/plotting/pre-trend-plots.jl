# pre-trend-plots.jl

using TSCSMethods, COVIDPoliticalEvents
using DataFrames, DataFramesMeta
using JLD2, Parameters

using Colors, ColorSchemes, CairoMakie

include("figure_code/plot_utilities.jl")
include("figure_code/pre-trend-plot-fn.jl")

savepath = "pre out/"

##
ylabels = ("Death rate (per 10,000)", "Case rate (per 10,000)")
xlabel = "Day"
outcomecolors = (gen_colors(3)[3], gen_colors(3)[2])
offsets = (0.15, 0.15)

##
fg = let
    fg = Figure(
        backgroundcolor = RGB(0.98, 0.98, 0.98),
        resolution = (1000, 1000),
        fontsize = 12 * 1
    );
    
    # overall
    a = "combined full_death_rte_excluded.jld2";
    b = "combined full_case_rte_excluded.jld2";
    m1, m2 = [JLD2.load_object(savepath * x).refcalmodel for x in [a, b]];
    @subset!(m1.results, :stratum .== 1)
    @subset!(m2.results, :stratum .== 1)
    panelA = fg[1, 1] = GridLayout()
    _figure!(panelA, m1, m2, xlabel, outcomecolors, offsets)

    # primaries
    a = "primary full_death_rte_.jld2";
    b = "primary full_case_rte_.jld2";
    m1, m2 = [JLD2.load_object(savepath * x).refcalmodel for x in [a, b]];
    panelB = fg[2, 1] = GridLayout()
    _figure!(panelB, m1, m2, xlabel, outcomecolors, offsets)

    # GA
    a = "ga nomob_death_rte_.jld2"
    b = "ga nomob_case_rte_.jld2"
    m1, m2 = [JLD2.load_object(savepath * x).refcalmodel for x in [a, b]];
    panelC = fg[3, 1] = GridLayout()
    _figure!(panelC, m1, m2, xlabel, outcomecolors, offsets)

    # Gub
    a = " gub out nomob_death_rte_.jld2"
    b = " gub out nomob_case_rte_.jld2"
    m1, m2 = [JLD2.load_object(savepath * x).refcalmodel for x in [a, b]];
    panelD = fg[4, 1] = GridLayout()
    _figure!(panelD, m1, m2, xlabel, outcomecolors, offsets)

    # BLM
    a = "blm nomob_death_rte_.jld2"
    b = "blm nomob_case_rte_.jld2"
    m1, m2 = [JLD2.load_object(savepath * x).refcalmodel for x in [a, b]];
    panelE = fg[5, 1] = GridLayout()
    _figure!(panelE, m1, m2, xlabel, outcomecolors, offsets)

    # Trump 
    a = "trump nomob_death_rte_exposure.jld2"
    b = "trump nomob_case_rte_exposure.jld2"
    m1, m2 = [JLD2.load_object(savepath * x).refcalmodel for x in [a, b]];
    @subset!(m1.results, :stratum .== 1)
    @subset!(m2.results, :stratum .== 1)
    panelF = fg[6, 1] = GridLayout()
    _figure!(panelF, m1, m2, xlabel, outcomecolors, offsets)

    for (label, layout) in zip(["A", "B", "C", "D", "E", "F"], [panelA, panelB, panelC, panelD, panelE, panelF])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    fg
end

save(savepath * "pre-trend.svg", fg)

fg2 = let
    fg = Figure(
        backgroundcolor = RGB(0.98, 0.98, 0.98),
        resolution = (800, 400),
        fontsize = 12 * 1
    );
    
    # overall
    a = "combined full_death_rte_excluded.jld2";
    b = "combined full_case_rte_excluded.jld2";
    m1, m2 = [JLD2.load_object(savepath * x).refcalmodel for x in [a, b]];
    @subset!(m1.results, :stratum .== 1)
    @subset!(m2.results, :stratum .== 1)
    panelA = fg[1, 1] = GridLayout()
    _figure!(panelA, m1, m2, xlabel, outcomecolors, offsets)

    fg
end
