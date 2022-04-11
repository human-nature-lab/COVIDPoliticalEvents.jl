# process the csv data

using CSV, DataFrames, DataFramesMeta, Dates
import JLD2

t = :running
id = :fips

dpth = "data/setup_data.csv";

dat = CSV.File(
    dpth; missingstrings = ["missing", "NA", ""], delim = ","
) |> DataFrame;

# dd = describe(dat);
# hcat(dd.variable, dd.eltype)

# sort!(dat, [t, id]);

#= temporary cleaning to deal with incomplete data
remove dates outside range
change missing that are left to zeros =#

pat = JLD2.load_object("data/safegraph_places_hlcat.jld2");

# Date("2021-02-28")
# trim to most recent mobility data
@subset!(dat, :date .<= maximum(pat.date))

# gives all (date, fips) combinations in data
datobs = select(dat, [:date, :fips]);

datobs = leftjoin(datobs, pat, on = [:date, :fips]);

for cn in setdiff(names(datobs), ["date", "fips"])
  datobs[ismissing.(datobs[!, cn]), cn] .= 0.0
  datobs[!, cn] = convert(Vector{Float64}, datobs[!, cn])
end

dat = leftjoin(dat, datobs, on = [:date, :fips]);

# import ShiftedArrays
# dt = @linq dat |>
#   groupby(:fips) |>
#   combine(rdif = :running - ShiftedArrays.lag(:running));

rename!(
  dat,
  :hispanic => Symbol("Pct. Hispanic"),
  :black => Symbol("Pct. Afr. American"),
  :cum_case_rte => Symbol("Cum. Case Rate"),
  :cum_death_rte => Symbol("Cum. Death Rate"),
  :state => :State,
  :abbr => Symbol("State Abbr."),
  :firstcase => Symbol("Date of First Case"),
  :bacc => Symbol("Pct. with Bacc. Deg."),
  :median_inc_ln => Symbol("Median Income (log)"),
  :tot_reg => Symbol("Tot. Registered Voters"),
  :trn_rte => Symbol("In-person Turnout Rate"),
  :pop_density => Symbol("Pop. Density"),
  :trump_share_2016 => Symbol("Trump 2016 Vote Share"),
  :perc_65_up => Symbol("Pct. 65 yrs and Above")
);

#=
turnout data corrections

Nebraska counties that satisfy criteria below, should be not treated as 

KY counties should be made missing

too early anyway:
CA (four rural, very small pop. counties)
ID (two counties)
ND (39/50, caucuses)
TX (12 counties)

KY -- state data not reliale, make missing
NE (11 counties) -- checked that these have no in-person votes, so de-treat
=#

# @linq td0 = subdat |>
#   where(
#     (:"In-person Turnout Rate") .== 0.0,
#     :primary .== 1,
#     :State .== "Kentucky"
#   ) |>
#   select(:fips, :State, :county)

# @linq tdky = subdat |>
#   where(
#     :primary .== 1,
#     :State .== "Kentucky"
#   ) |>
#   select(:fips, :State, :county, :"In-person Turnout Rate")

# unique(td0.State)

# KY data is not reliable, so make turnout missing for whole state
dat[(dat.primary .== 1) .& (dat.State .== "Kentucky"), Symbol("In-person Turnout Rate")] .= missing;

subdat = @views(dat[dat.primary .== 1, :]);
for i in 1:nrow(subdat)
  if !ismissing(subdat[i, Symbol("In-person Turnout Rate")])
    c1 = subdat[i, Symbol("In-person Turnout Rate")] == 0.0;
    c2 = subdat[i, :primary] == 1;
    c3 = subdat[i, :State] == "Nebraska";
    # c4 = subdat[i, :State] == "Kentucky";
    if c1 & c2 & c3
      subdat[i, :primary] = 0
    end
  end
end

JLD2.save_object("data/cvd_dat.jld2", dat);
