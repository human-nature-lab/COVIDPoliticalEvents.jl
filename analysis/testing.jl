# testing.jl
# check the average testing trends in the outcome window, using state-level data

using Downloads

# COUNTY
# tst = CSV.read(download("https://raw.githubusercontent.com/govex/COVID-19/master/data_tables/testing_data/county_time_series_covid19_US.csv"), DataFrame)
# data only available after 2021-08-01

using DataFramesMeta
using Dates

# STATE

ste = CSV.read(
    download("https://raw.githubusercontent.com/govex/COVID-19/master/data_tables/testing_data/time_series_covid19_US.csv"),
    DataFrame
)

begin
    dates = Vector{Date}(undef, nrow(ste));
    for i in 1:nrow(ste)
        dates[i] = Date(ste.date[i], dateformat"m/d/y")
    end
    ste.date = dates;
    ste[!, :running] = [Dates.value(s - Date("2020-03-01")) for s in ste.date];
end

sort!(ste, [:state, :running])
select!(ste, Not(:date))

ste[!, :positivity] = ste[!, :cases_conf_probable] .* inv.(ste[!, :tests_combined_total])

testvars = [
    :cases_conf_probable, :cases_confirmed, :cases_probable,
    :tests_combined_total #, :positivity
];

# begin
#     # want daily counts instead of cumulative
#     gdf = groupby(ste, [:state])
#     for g in gdf
#         for v in testvars
#             g[!, v] = [missing, diff(g[!, v])...]
#         end
#     end
# end


@subset(ste, :state .== "MA")

obs = model.observations[model.strata .== 1];
obs = DataFrame(:running => [ob[1] for ob in obs], :fips => [ob[2] for ob in obs]);

obdat = innerjoin(
    obs, recordset.matchinfo,
    on = [:running => :timetreated, :fips => :treatedunit]
);

obdat[!, :period] = obdat.f .+ obdat.f
select!(obdat, [:fips, :running, :period, :f])

obdat = leftjoin(obdat, dat_store; on = [:period => :running, :fips]);
sort!(obdat, [:running, :fips, :period])

obdat = leftjoin(
    obdat,
    ste,
    on = [:period => :running, Symbol("State Abbr.") => :state]
)

using ShiftedArrays

pctΔ(y1, y2) = (y2 .- y1) .* inv.(y1) .* 100

# calcualte percentage difference
begin
    gdf = groupby(obdat, [:running, :fips])
    for g in gdf
        # g = gdf[240]
        for v in testvars
            fst = g[1, v] # min for cumulative, not nec. for positivity
            # hcat(g[!, v], pctΔ(fst, g[!, v]))
            g[!, v] = pctΔ(fst, g[!, v])
        end
    end
end

findfirst(([keys(gdf)[i][1] for i in 1:length(gdf)] .== 72) .& ([keys(gdf)[i][2] for i in 1:length(gdf)] .== 31005) .== true)

gdf[240][!, [:fips, :running, :period, :f, testvars...]]

using Statistics

ob3 = @chain obdat begin
    groupby([:f])
    combine([v => mean∘skipmissing => v for v in [testvars..., :positivity]])
end

for v in testvars[end-1:end]
    vn = Symbol(string(v) * "_diff")
    ob3[!, vn] = Vector{Union{Float64, Missing}}(missing, nrow(ob3))
    ob3[2:end, vn] = diff(ob3[!, v])
end

ob3

using CairoMakie

fg = begin
    f = Figure()
    ax1 = Axis(
        f[1,1];
        ylabel = "Pct. change in total tests",
        xlabel = "Day",
        yticklabelcolor = :cornflowerblue
    )
    ax2 = Axis(
        f[1,1];
        ylabel = "Positivity",
        yticklabelcolor = :goldenrod1
    )

    lines!(
        ax1, ob3.f, ob3.tests_combined_total;
        color = :cornflowerblue,
        label = "Total tests"
    )
    lines!(
        ax2, ob3.f, ob3.positivity .* 100;
        color = :goldenrod1,
        label = "Positivity"
    )
    
    ax2.yaxisposition = :right
    ax2.yticklabelalign = (:left, :center)
    ax2.xticklabelsvisible = false
    ax2.xticklabelsvisible = false
    ax2.xlabelvisible = false

    hidexdecorations!(
        ax1, grid = true, ticks = false, ticklabels = false, label = false
    )
    hidexdecorations!(
        ax2, grid = true, ticks = false, ticklabels = false, label = false
    )
    hideydecorations!(
        ax1, grid = true, ticks = false, ticklabels = false, label = false
    )
    hideydecorations!(
        ax2, grid = true, ticks = false, ticklabels = false, label = false
    )

    linkxaxes!(ax1, ax2)

    # Legend(f[1,2], ax)
    f
end

fg
