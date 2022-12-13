# treatmentplot.jl
# import Pkg; Pkg.activate(".")

import Pkg; Pkg.activate(".")

using Random, TSCSMethods, COVIDPoliticalEvents, Dates, DataFrames
import JLD2:load_object,save_object
import CSV
import TSCSMethods:@reset

using StatsBase, Statistics

using DataFramesMeta

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

trt = @subset(
    dat, :political .== 1,
    :rallyday1 .== 0, :rallyday2 .== 0, :rallyday3 .== 0
)

tn = names(trt)
trt.pop;

tr = Symbol("In-person Turnout Rate");
gatr = Symbol("In-Person Turnout Rate (GA)");

trt.prsize
trt[!, tr] .* trt.pop
trt[!, gatr] .* trt.pop

# do not have data for
# rallies
# NJ, VA

trt[!, :size] = Vector{Union{Float64, Missing}}(missing, nrow(trt));
# trt[!, :event] = Vector{Union{String, Missing}}(missing, nrow(trt));
trt[!, :event] = Vector{String}(undef, nrow(trt));

events = [:primary, :rallyday0, :gub, :gaspecial, :protest]

eventnames = Dict(
    :primary => "Primary", :rallyday0 => "Rally",
    :gub => "Gubernatorial", :gaspecial => "GA Special",
    :protest => "Protest"
);

eventsize = Dict(
    :primary => tr,
    # :rallyday0 => "Rally",
    # :gub => "Gubernatorial",
    :gaspecial => gatr,
    :protest => :prsize
)

let
    for rw in eachrow(trt)
        for vbl in events
            if rw[vbl] == 1
                rw[:event] = eventnames[vbl]
                rw[:size] = if (vbl == :primary) | (vbl == :gaspecial)
                    round(rw[get(eventsize, vbl, missing)] * rw[:pop]; digits = 0)
                else
                    if !ismissing(get(eventsize, vbl, missing))
                        rw[get(eventsize, vbl, missing)]
                    else missing
                    end
                end
            end
        end
    end
end

using CairoMakie

clrs = Makie.wong_colors(length(unique(trt.event)));

function assigneventcolor(x)
    return if x == "Primary"
        clrs[1]
    elseif x == "GA Special"
        clrs[5]
    elseif x == "Rally"
        clrs[2]
    elseif x == "Gubernatorial"
        clrs[3]
    elseif x == "Protest"
        clrs[4]
    end
end

## add nj
let
    nj = CSV.read(
        "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/nj_turnout.csv",
        DataFrame
    )

    va = CSV.read(
        "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/va_turnout.csv",
        DataFrame
    )

    nj[!, :in_person] = nj.total_ballots - nj.ballots_by_mail;

    gubturnout = Dict(
        vcat(nj.fips, va.fips) .=> vcat(nj.in_person, va.election_day)
    )

    for (i, (fps, ev)) in enumerate(zip(trt.fips, trt.event))
        if ev == "Gubernatorial"
            trt.size[i] = get(gubturnout, fps, missing)
        end
    end
end

let
    trmp = CSV.read("/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/trump_rallies.csv", DataFrame)

    trmp.date = Date.(trmp.date, "m/d/y") + Dates.Year(2000);
    trmp.size = sqrt.(trmp.crowd_lwr .* trmp.crowd_upr)

    dd = Dict{Tuple{Date, Int}, Union{Float64, Missing}}()
    for r in eachrow(trmp)
        dd[(r.date, r.fips)] = r.size
    end

    for (i, (dte, fps, ev)) in enumerate(zip(trt.date, trt.fips, trt.event))
        if ev == "Rally"
            trt.size[i] = get(dd, (dte, fps), missing)
        end
    end
end

@subset!(trt, :size .> 1)

## xlabels
dtlab = Date("2020-03-01"):Month(4):maximum(trt.date) |> collect
dtdf = dtlab .- Date("2020-03-01")
dtlab = string.(dtlab)
dtval = [Dates.value(e) for e in dtdf]

## ylabels
# maximum(skipmissing(trt.size))

fg1 = let

    fg = Figure()
    ga = fg[1, 1] = GridLayout()
    gb = fg[2, 1:2] = GridLayout()

    slab = (Int.(round.(exp.([2.5,5,7.5,10,12.5]); digits = 0)));
    ords = floor.(Int, log10.(slab))
    slab = Int.([round(e; digits = r*-1) for (e, r) in zip(slab, ords)])
    svals = log.(slab);
    slab = string.(slab)

    ax1 = Axis(
        ga[1,1];
        xticks = (svals, slab),
        title = "Event sizes"
    )
    hist!(ax1, log.(trt.size); bins = 100, color = :grey)

# @subset(trt, :size .> 500000)
# the large event in LA County primary election

    ax2 = Axis(
        gb[1,1];
        title = "Event sizes over time",
        ylabel = "persons",
        xgridvisible = false,
        ygridvisible = false,
        xticks = (dtval, dtlab),
        yticks = (svals, slab)
    )

    # eclrs = [(:transparent, 0.8) for e in trt.event]

    scs = []

    for e in unique(trt.event)
        ti = @subset(trt, :event .== e)
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
            fg[1, 2],
            group_color,
            string.(unique(trt.event)),
            "Event"
        )

    for (label, layout) in zip(["A", "B"], [ga, gb])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            font = :bold,
            padding = (0, 5, 5, 0),
            halign = :right)
    end

    fg
end

# include these in figure
mean(trt.size), std(trt.size)