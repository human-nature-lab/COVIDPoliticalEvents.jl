# unit counts.jl

using TSCSMethods, COVIDPoliticalEvents, DataFrames, DataFramesMeta, Parameters, Accessors, Dates
import Colors, ColorSchemes
using CairoMakie
using JLD2

vn = VariableNames();

primpth = "primary out/"
gapth = "ga out/"
rlpth = "rally out/"
prpth = "protest out/"
savepth = "plotting/si_figures/"

# main paper diagnostics

main_diagnostic = [
    primpth * " primary full_death_rte_.jld2",
    primpth * " primary full_death_rte_In-person Turnout Rate.jld2",
    gapth * " ga nomob_death_rte_.jld2",
    gapth * " ga nomob_death_rte_In-person Turnout Rate.jld2",
    rlpth * " rally nomob_death_rte_exposure.jld2",
    prpth * " protest nomob_death_rte_.jld2",
    prpth * " protest nomob_death_rte_prsize.jld2"
];

si_primary = [
    primpth * " primary full_death_rte_Pop. Density.jld2",
    primpth * " primary full_death_rte_date.jld2",
    primpth * " primary nomob_death_rte_Region.jld2",
    primpth * " primary full_death_rte_Trump 2016 Vote Share.jld2",
    primpth * " primary full_death_rte_firstcase.jld2",
    primpth * " primary full_death_rte_Cum. Case Rate.jld2",
    primpth * " primary full_death_rte_Cum. Death Rate.jld2",    
];

si_other = [
    gapth * " ga nomob_death_rte_Trump 2016 Vote Share.jld2",
    gapth * " ga nomob_death_rte_Rarely Mask.jld2",
    prpth * " protest nomob_death_rte_Recent Protests.jld2",
];

main_case = [
    primpth * " primary full_case_rte_.jld2",
    primpth * " primary full_case_rte_In-person Turnout Rate.jld2",
    gapth * " ga nomob_case_rte_.jld2",
    gapth * " ga nomob_case_rte_In-person Turnout Rate.jld2",
    rlpth * " rally nomob_case_rte_exposure.jld2",
    prpth * " protest nomob_case_rte_.jld2",
    prpth * " protest nomob_case_rte_prsize.jld2"
];

gubs = [
    "gub out/ gub out nomob_case_rte_.jld2",
    "gub out/ gub out nomob_death_rte_.jld2"
];

rtmodels = [
    "primary full_Rt_.jld2",
    "ga nomob_Rt_.jld2",
    "gub nomob_Rt_.jld2",
    "rally nomob_Rt_exposure.jld2",
    "protest nomob_Rt_.jld2"
];

modelset = [
    main_diagnostic..., si_primary..., si_other...,
    "rally out/rally nomob_death_rte_Exposure x Trump Share > 50%.jld2",
    main_case..., gubs..., "Rt out/" .* rtmodels...,
    "combined out/combined modelfull_deaths_excluded.jld2"
];

import TSCSMethods.mean
function unitcounts(modelset)

    infos = DataFrame(
        :model => String[],
        :outcome => Symbol[],
        :stratifier => Symbol[],
        :stratum => Int[],
        :label => String[],
        :N_trt => Float64[],
        :N_mtch => Float64[],
        :n_trt => Float64[],
        :n_mtch => Float64[]
    );

    for e in modelset
        objet = load_object(e)
        mname = split(split(e, "/")[2], ".jld2")[1]
        Res = objet.model.results;
        rename!(Res, :treated => :Treated, :matches => :Matches)
        res = objet.refcalmodel.results;
        oc = objet.refcalmodel.outcome;
        if "stratum" .∈ Ref(names(res))
            select!(Res, :stratum, :f, :Treated, :Matches)
            res = leftjoin(res, Res, on = [:stratum, :f])
        else
            select!(Res, :f, :Treated, :Matches)
            res = leftjoin(res, Res, on = :f)
        end

        smry = if "stratum" .∈ Ref(names(res))
            @chain res begin
                groupby(:stratum)
                combine(
                    :Treated => mean => :N_trt,
                    :Matches => mean => :N_mtch,
                    :treated => mean => :n_trt,
                    :matches => mean => :n_mtch
                )
                @transform(:stratifier = objet.refcalmodel.stratifier, :label = "")
            end
        else
            @chain res begin
                combine(
                    :Treated => mean => :N_trt,
                    :Matches => mean => :N_mtch,
                    :treated => mean => :n_trt,
                    :matches => mean => :n_mtch
                )
                @transform(:stratum = 0, :stratifier = Symbol(""), :label = "")
            end
        end;

        if "stratum" .∈ Ref(names(res))
            for r in eachrow(smry)
                r[:label] = get(objet.refcalmodel.labels, r[:stratum], "?")
            end
        end

        smry[!, :model] .= mname
        smry[!, :outcome] .= oc

        infos = vcat(infos, smry)
    end

    infos[!, :N_trt] = round.(infos[!, :N_trt]; digits = 1)
    infos[!, :N_mtch] = round.(infos[!, :N_mtch]; digits = 1)
    infos[!, :n_trt] = round.(infos[!, :n_trt]; digits = 1)
    infos[!, :n_mtch] = round.(infos[!, :n_mtch]; digits = 1)
    return infos
end

infos = unitcounts(modelset)

import CSV
CSV.write("unitcounts.csv", infos)
