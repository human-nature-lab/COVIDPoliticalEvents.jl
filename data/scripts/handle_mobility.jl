# handle_mobility.jl

#=
takes safegraph poi file (Ben gives this to you) and outputs clean, categorized locations data

as-is, creates a wide dataframe with visits per capita
=#

using DataFrames, DataFramesMeta, Dates, StatsBase
import RData, CSVFiles, CSV, JLD2

#=
list of individual places under each naics code (without county info)
=#
# plac = RData.load("places.rds");

# may missing
#= 
date, fips, naics_code, visits

sum of visits to each naics code at county level
=#

pat = RData.load("data/patterns_2020-01-01_2021-02-28.rds");

pat.date = Date.(pat.date);

@subset!(
  pat,
  :date .>= Date("2020-03-01"),
  ismissing.(:naics_code) .== false,
  :fips .!= ""
);

pat.naics_code = convert(Vector{Int64}, pat.naics_code);

pat.fips = parse.(Int64, pat.fips);

#=
top categories to exclude
"Electric Power Generation, Transmission and Distribution",

focus categories
"Drinking Places (Alcoholic Beverages)"
"Colleges, Universities, and Professional Schools"

"Community Food and Housing, and Emergency and Other Relief Services"
- sub: "Temporary Shelters", "Community Food Services"

potential focus
"Health and Personal Care Stores"
"Beer, Wine, and Liquor Stores" (as index of gatherings?)
"Child Day Care Services" (work index?)

"Gasoline Stations" (remember, mostly outdoors?)

=#

# high level classifications
# <https://www.census.gov/naics/?58967?yearbck=2017>

naics_org = CSV.read("data/naics_codes_organized.csv", DataFrame);

select!(naics_org, [:naics_code, :high_level]);

pat = leftjoin(pat, naics_org, on = :naics_code);

dropmissing!(pat, :high_level);

pat = @linq pat |>
  groupby([:date, :fips, :high_level]) |>
  combine(visits = sum(:visits));

pat = begin

  dato = CSV.File(
    "data/setup_data.csv";
    missingstrings = ["missing", "NA", ""], delim = ","
  ) |> DataFrame;

  pdict = Dict(dato.fips .=> dato.pop);

  pat.vispc =  get.(Ref(pdict), pat.fips, 0);

  @subset!(pat, :vispc .> 0);

  pat.vispc = pat.visits ./ pat.vispc;

  select!(pat, Not(:visits))

  nrow(pat)
  nrow(unique(pat))

  pat = unstack(
    unique(pat),
    [:date, :fips],
    :high_level,
    :vispc;
    allowduplicates = true
  );
end;

for cn in setdiff(names(pat), ["date", "fips"])
  pat[ismissing.(pat[!, cn]), cn] .= 0.0
  pat[!, cn] = convert(Vector{Float64}, pat[!, cn])
end

JLD2.save_object("data/safegraph_places_hlcat.jld2", pat);
