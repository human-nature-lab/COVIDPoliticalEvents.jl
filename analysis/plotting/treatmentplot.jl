# treatmentplot.jl
# import Pkg; Pkg.activate(".")

import Pkg; Pkg.activate(".")

using Random, TSCSMethods, COVIDPoliticalEvents, Dates, DataFrames
import JLD2:load_object,save_object
import CSV
import TSCSMethods:@reset

using StatsBase, Statistics

using DataFramesMeta

using CairoMakie

using EasyFit

Random.seed!(2019)

# parameters
#= practically, the only parameter that changes across models
is the outcome. for the paper, everything else stays the same
=#
covarspec = "full" # = ARGS[]
outcome = :Rt;
scenario = "combined ";
F = 0:20; L = -30:-1
refinementnum = 5; iters = 10000;
prefix = ""

# setup
dat_store, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath = dataload(
    "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/cvd_dat_use.jld2",
    "combined out/"
)

dat = deepcopy(dat_store);

model, dat = preamble(
    outcome, F, L, dat, scenario, covarspec, iters;
    borderexclude = false, convert_missing = false
);

trt = sizeprocess(dat);
trt.lpop = log.(trt.pop);
trt.lsize = log.(trt.size);
trt.pct = trt.size ./ trt.pop

trt2 = trt;

## xlabels
dtlab = Date("2020-03-01"):Month(4):maximum(trt.date) |> collect
dtdf = dtlab .- Date("2020-03-01")
dtlab = string.(dtlab)
dtval = [Dates.value(e) for e in dtdf]

## ylabels
# maximum(skipmissing(trt.size))

fg1 = let

    fg = Figure(resolution = (900, 800))
    ga = fg[1, 1:2] = GridLayout()
    gx = ga[1,2] = GridLayout()
    gb = fg[2, 1:2] = GridLayout()

    slab = (Int.(round.(exp.([2.5,5,7.5,10,12.5]); digits = 0)));
    ords = floor.(Int, log10.(slab))
    slab = Int.([round(e; digits = r*-1) for (e, r) in zip(slab, ords)])
    svals = log.(slab);
    slab = string.(slab)

    ax1 = Axis(
        ga[1,1];
        xticks = (svals, slab),
        title = "Event sizes",
        ylabel = "frequency"
    )
    hist!(ax1, log.(trt2.size); bins = 100, color = :grey)

    ax3 = Axis(
        ga[1,2];
        # xticks = (svals, slab),
        title = "Event sizes (as pct. of population)"
    )
    hist!(ax3, trt2.pct; bins = 100, color = :grey)

    ax2 = Axis(
        gb[1, 1];
        title = "Event sizes over time",
        ylabel = "persons",
        xgridvisible = false,
        ygridvisible = false,
        xticks = (dtval, dtlab),
        yticks = (svals, slab)
    )

    # eclrs = [(:transparent, 0.8) for e in trt.event]

    scs = []

    for e in unique(trt2.event)
        ti = @subset(trt2, :event .== e)
        sci = scatter!(
            ax2, ti.running, log.(ti.size);
            color = :transparent,
            label = e,
            strokecolor = [assigneventcolor.(e) for e in ti.event],
            strokewidth = 1
        )
        push!(scs, sci)
    end

    eclr = [assigneventcolor(x) for x in unique(trt.event)]

    group_color = [
        MarkerElement(
            marker = :circle,
            color = :transparent, strokecolor = color,
            strokewidth = 1,
            markersize = 15
        ) for color in eclr
    ]

    lg = Legend(
            gb[1, 2],
            group_color,
            string.(unique(trt.event)),
            "Event"
        )

    for (label, layout) in zip(["A", "B", "C"], [ga, gx, gb])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            font = :bold,
            padding = (0, 5, 5, 0),
            halign = :right)
    end

    fg
end

# include these in figure
mean(trt2.size), std(trt2.size)
mean(trt2.pct), std(trt2.pct)

##


fg2 = let

    fg = Figure(resolution = (900, 800))
    ga = fg[1, 1:2] = GridLayout()
    gx = ga[1,2] = GridLayout()
    gb = fg[2, 1:2] = GridLayout()

    slab = (Int.(round.(exp.([2.5,5,7.5,10,12.5]); digits = 0)));
    ords = floor.(Int, log10.(slab))
    slab = Int.([round(e; digits = r*-1) for (e, r) in zip(slab, ords)])
    svals = log.(slab);
    slab = string.(slab)

    ax1 = Axis(
        ga[1,1];
        xticks = (svals, slab),
        title = "Event sizes",
        ylabel = "frequency"
    )
    hist!(ax1, log.(trt2.size); bins = 100, color = :grey)

    ax3 = Axis(
        ga[1,2];
        # xticks = (svals, slab),
        title = "Event sizes (as pct. of population)"
    )
    hist!(ax3, trt2.pct; bins = 100, color = :grey)

    ax2 = Axis(
        gb[1, 1];
        title = "Event sizes over time",
        ylabel = "persons",
        xgridvisible = false,
        ygridvisible = false,
        xticks = (dtval, dtlab),
        yticks = (svals, slab)
    )

    # eclrs = [(:transparent, 0.8) for e in trt.event]

    scs = []

    for e in unique(trt2.event)
        ti = @subset(trt2, :event .== e)
        sci = scatter!(
            ax2, ti.running, log.(ti.size);
            color = :transparent,
            label = e,
            strokecolor = [assigneventcolor.(e) for e in ti.event],
            strokewidth = 1
        )
        push!(scs, sci)
    end

    epidat = @chain dat begin
        groupby(:running)
        combine(
            :death_rte => mean => :death_rte,
            :case_rte => mean => :case_rte,
            :Rt => mean => :Rt,
        )
        sort(:running)
    end

    epidat[!, :dr_smooth] = movavg(epidat.death_rte, 7).x
    epidat[!, :cr_smooth] = movavg(epidat.case_rte, 7).x

    ax2o = Axis(
        gb[1, 1];
        # title = "Event sizes over time",
        yaxisposition = :right,
        ylabel = "death rate",
        xgridvisible = false,
        ygridvisible = false,
        xticklabelsvisible = false
    )

    lines!(ax2o, epidat.running, epidat.dr_smooth; color = :black)
    lines!(ax2o, epidat.running, epidat.cr_smooth; color = :darkgoldenrod1)
    # lines!(ax2o, epidat.running, epidat.Rt; color = :firebrick)

    eclr = [assigneventcolor(x) for x in unique(trt.event)]

    group_color = [
        MarkerElement(
            marker = :circle,
            color = :transparent, strokecolor = color,
            strokewidth = 1,
            markersize = 15
        ) for color in eclr
    ]

    lg = Legend(
            gb[1, 2],
            group_color,
            string.(unique(trt.event)),
            "Event"
        )

    for (label, layout) in zip(["A", "B", "C"], [ga, gx, gb])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            font = :bold,
            padding = (0, 5, 5, 0),
            halign = :right)
    end

    fg
end