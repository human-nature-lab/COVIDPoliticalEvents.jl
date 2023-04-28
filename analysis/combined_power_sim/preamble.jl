# preamble.jl

Random.seed!(2019)

scenario = "combined "

vn = VariableNames();
scenario = ""

# setup

model, dat = preamble(
    outcome, F, L, dat, scenario, covarspec, iters;
    borderexclude=false
);

using DataFramesMeta

# assign treatment types events

evs = [
    :primary,
    :gaspecial,
    :gub,
    :protest,
    :rallyday0,
    :rallyday1,
    :rallyday2,
    :rallyday3
];

dp = @subset(dat, :political .== 1);
dps = select(dp, [:fips, :running, evs...])

dps = stack(
    dps,
    evs, value_name=:held, variable_name=:event
)

@subset!(dps, :held .== 1)

# (tt, tu)
treatcats = Dict{Tuple{Int,Int},Int}()
evs = string.(evs)
for (tt, tu, ev) in zip(dps.running, dps.fips, dps.event)
    treatcats[(tt, tu)] = findfirst(ev .== evs)
end
