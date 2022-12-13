# model inspection.jl

using Statistics, DataFramesMeta

include("inspection functions.jl")

mods = [
    # combined
    (
        "combined out/grace combined out/combined full_death_rte_excluded.jld2" ,
        "Combined"
    ),
    (
        "combined out/grace combined out/combined full_case_rte_excluded.jld2","Combined",
    ),
    (
        "combined Rt out/combined Rt modelfull_Rt_excluded.jld2",
        "Combined",
    ),
    # primary
    (
        "primary out/ primary full_death_rte_.jld2",
        "Primary"
    ),
    (
        "primary out/ primary full_case_rte_.jld2",
        "Primary"
    ),
    (
        "Rt out/primary full_Rt_.jld2",
        "Primary"
    ),
    # ga
    ("ga out/ ga nomob_death_rte_.jld2", "GA"),
    ("ga out/ ga nomob_case_rte_.jld2", "GA"),
    ("Rt out/ga nomob_Rt_.jld2", "GA"),
    # gub
    ("gub out/ gub out full_death_rte_.jld2", "NJ and VA"),
    ("gub out/ gub out full_case_rte_.jld2", "NJ and VA"),
    ("Rt out/gub full_Rt_.jld2", "NJ and VA"),
    # blm
    ("protest out/ protest full_death_rte_.jld2", "BLM"),
    ("protest out/ protest full_case_rte_.jld2", "BLM"),
    ("Rt out/protest full_Rt_.jld2", "BLM"),
    # trump
    ("rally out/ rally nomob_death_rte_exposure.jld2", "Rally"),
    ("rally out/ rally nomob_case_rte_exposure.jld2", "Rally"),
    ("Rt out/rally full_Rt_exposure.jld2", "Rally")
]

nmes = [a[2] for a in mods];

df = DataFrame()

for (a, b) in mods
    m = JLD2.load_object(a)
    @unpack matchinfo, obsinfo = m
    matchinfo[!, :m] = [length(e) for e in matchinfo.ranks];
    matchinfo[!, :outcome] .= m.refcalmodel.outcome
    matchinfo[!, :event] .= b

    append!(df, matchinfo)
end

using Parameters
using CairoMakie
using Statistics, StatsBase

function stringot(x)
    return if x == :death_rte
        "death rate"
    elseif x == :case_rte
        "case rate"
    else string(x)
    end
end

nmset = unique(df[!, [:outcome, :event]]);
sort!(df, [:event, :outcome])

fg1 = let
    fg = Figure(resolution = (800, 850))

    ga = fg[1, 1:3] = GridLayout()
    gb = fg[2, 1:3] = GridLayout()
    gc = fg[3, 1:3] = GridLayout()
    gd = fg[4, 1:3] = GridLayout()
    ge = fg[5, 1:3] = GridLayout()
    gf = fg[6, 1:3] = GridLayout()

    grdf = groupby(df, :event)
    for (j, (df2, gi)) in enumerate(zip(grdf, [ga, gb, gc, gd, ge, gf]))
        for (i, ot) in enumerate(unique(nmset.outcome))
            dfi = @subset(df2, :outcome .== ot)
            ax = Axis(
                gi[1, i];
                ygridvisible = false,
                xgridvisible = false,
            )
            if j == 1
                ax.title = stringot(ot)
            end
            if j == length(grdf)
                ax.xlabel = "matches"
            end
            if i == 1
                ax.ylabel = "probability"
            end

            ylims!(ax, 0, 1)
            hist!(ax, dfi.m; normalization = :probability)
            vlines!(ax, [mean(dfi.m)]; color = :black)
        end
    end

    for (label, layout) in zip(
        ["A", "B", "C", "D", "E", "F"], [ga, gb, gc, gd, ge, gf]
    )
        Label(layout[1, 1, TopLeft()], label,
            fontsiz = 26,
            font = :bold,
            padding = (0, 5, 5, 0),
            halign = :right)
    end

    fg
end

@chain df begin 
    groupby([:event, :outcome])
    combine(:m => mean => :m)
    groupby([:event])
    combine(:m => mean => :m)

end
