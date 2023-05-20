# vaccine data

using DataFrames, DataFramesMeta, CSV
using Downloads
using Dates

vax = CSV.read("data/data/cdc_vax_state.csv", DataFrame)

vax.Date = Date.(vax.Date, dateformat"m/d/y");

sort!(vax, [:Date, :MMWR_week, :Location])

ga = @subset(vax, :Location .== "GA");

gabefore = @views ga[ga.Date .<= Date("2021-01-05"), :]

gapop = 10799566

(ga[ga.Date .== Date("2021-01-05"), :Distributed][1] ./ gapop) * 100
(ga[ga.Date .== Date("2021-01-05"), :Administered][1] ./ gapop) * 100

njva = @subset(vax, :Location .∈ Ref(["NJ", "VA"]), :Date .== Date("2021-11-02"))

njpop = 9267130
vapop = 8642274

njva[!, "Administered"]
njva[!, "Series_Complete_Yes"] ./ [njpop, vapop]

## county-level

vax = CSV.read("data/data/cdc_vax_county.csv", DataFrame)

vax.Date = Date.(vax.Date, dateformat"m/d/y");
sort!(vax, [:Date, :MMWR_week, :FIPS])

select!(
    vax,
    :Date, :FIPS, :Recip_County, :Recip_State, :Completeness_pct, :Series_Complete_Yes, :Booster_Doses
)

CSV.write("vax_county_proc.csv", vax)