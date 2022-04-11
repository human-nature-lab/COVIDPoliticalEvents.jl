# preamble.jl

using Random, TSCSMethods, COVIDPoliticalEvents, DataFrames
import JLD2:load_object

Random.seed!(2019)

savepath = "protest out/";
datapath = "data/";
scenario = "protest "

refinementnum = 5; iters = 10000;

dat = load_object(datapath * "cvd_dat.jld2");
protest_dat = load_object(datapath * "final_protest_data.jld2")
select!(dat, Not([:protest, :prsize, :prcount]))
dat = leftjoin(dat, protest_dat, on = [:fips, :date => :pr_event_date]);

pr_vars = [:protest, :prsize, :prcount, :pr_blm, :pr_bluetrump, :pr_covid];
for v in pr_vars
  c1 = ismissing.(dat[!, v])
  x = if eltype(skipmissing(dat[!, v])) == Bool
    false
  else 0
  end
  dat[c1, v] .= x
  dat[!, v] = disallowmissing(dat[!, v])
end

sort!(dat, [:fips, :date])

vn = VariableNames();

obvars = [vn.pd, vn.ts16, :prsize];

model = casemodel(
  scenario * ARGS[1], :protest, Symbol(ARGS[1]), dat; iterations = iters
);

#=
check the number and types of events
N.B. that event types are overlapping, since we aggregate to county level,
and since some events have multiple categorizations

xf = @chain dat begin
  @subset(:protest .== 1, :prsize .>= 800)
  combine([pv => sum => pv for pv in pr_vars]...)
end

[round(100 * e * inv(xf.protest[1]); digits = 0) for e in xf[1,4:end]]
=#