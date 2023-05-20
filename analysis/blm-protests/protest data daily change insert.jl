# protest data daily change insert
cd("packages/COVIDPoliticalEvents.jl/analysis/")
import Pkg; Pkg.activate(".")

using Dates, Random, TSCSMethods, COVIDPoliticalEvents, DataFramesMeta, Statistics
import JLD2:load_object



dat = JLD2.load_object(datapath * "cvd_dat.jld2")
@subset!(dat, :date .>= Date("2020-03-01"))
sort!(dat, [:fips, :date])

p25(x) = quantile(x, 0.025)
p975(x) = quantile(x, 0.975)

function make_info(dat)
  info = @chain dat begin
    groupby(:date)
    combine(
      :deaths => mean => :deathsbar,
      :deaths .=> p25 .=> :dp25,
      :deaths .=> p975 .=> :dp975,
      :death_rte => mean => :death_rtebar,
      :death_rte .=> p25 .=> :drp25,
      :death_rte .=> p975 .=> :drp975,
    )
    sort(:date)
  end

  # create dummy variable for each event type
  dat[!, :primaryind] .= false;
  dat[!, :gaind] .= false;
  dat[!, :gubind] .= false;
  dat[!, :trumpind] .= false;
  dat[!, :blmind] .= false;
  return info
end

modelfiles = [
  "primary out/primary full_death_rte_.jld2",
  "ga out/ga full_death_rte_.jld2",
  "gub out/gub full_death_rte_.jld2",
  "rally out/rally nomob_death_rte_exposure.jld2",
  "protest out/protest full_death_rte_.jld2",
];

otherfiles = [
    "primary out/primary full_Cum. Deaths_.jld2"
]

mf = otherfiles[1]
m = load_object(mf);
m.refcalmodel.results
m.refcalmodel.covariates

m.matchinfo.reference = m.matchinfo.timetreated .- 1;
tfo = @chain m.matchinfo begin
    select([:reference, :treatedunit]...)
    unique([:reference, :treatedunit])
    leftjoin(
        dat,
        on = [:reference => :running, :treatedunit => :fips]
    )
end

mfo = @chain m.matchinfo begin
    flatten(:matchunits)
    leftjoin(
        dat,
        on = [:reference => :running, :matchunits => :fips]
    );
    unique([:matchunits, :reference])
end

cdr = Symbol("Cum. Death Rate")

mus = unique(mfo.matchunits)
tus = unique(mfo.treatedunit)
xx = @chain dat begin
    @subset(:running .>= 310-20, :running .<= 310+40)
    @transform(:pre = ifelse.(:running .<= 310, true, false))
    @transform(:post = ifelse.(:running .>= 310+10, true, false))
    @transform(:ref = ifelse.(:running .== 310-1, true, false))
    @transform(:tu = ifelse.(:fips .∈ Ref(tus), true, false))
    @transform(:mu = ifelse.(:fips .∈ Ref(mus), true, false))
    groupby([:tu, :mu, :pre, :post, :ref])
    @combine(
        :dr = mean(:death_rte),
        :cdr = mean($cdr)
        )
    sort([:tu, :mu])
end
    
@subset(xx, :ref .== true)

for mf in modelfiles
  m = load_object(mf);

  # m.refcalmodel.results
  mus = unique(reduce(vcat, m.matchinfo.matchunits))
  tus = unique(reduce(vcat, m.matchinfo.treatedunit))
  units = vcat(mus, tus)

end

using CairoMakie

fd = Figure()
Axis(fd[1, 1])

lines!(1:nrow(info), info.deathsbar)
band!(1:nrow(info), info.dp25, info.dp975)

fd

function skipdiff(A::AbstractVector, interval)
  [A[i+interval] - A[i] for i = 1:length(A)-interval]
end

function changecalcs(bar, lwr, upr, F)
  ln = length(bar) - maximum(F)

  accums = fill(0, ln)
  aclwr = fill(0, ln)
  acupr = fill(0, ln)

  for (c,  f) in enumerate(F)
    adjust = (1 + (length(F)-c))
    accums += skipdiff(bar, f)[adjust:end]
    aclwr += skipdiff(lwr, f)[adjust:end]
    acupr += skipdiff(upr, f)[adjust:end]
  end

  fact = inv(length(F))
  return accums .* fact, aclwr .* fact, acupr .* fact
end

F = 10:40;
death_series = changecalcs(
  info[!, :deathsbar], info[!, :dp25], info[!, :dp975], F
);

death_rate_series = changecalcs(
  info[!, :death_rtebar], info[!, :drp25], info[!, :drp975], F
);

b = 1000
Δfig = Figure(resolution = (1*b, 2*b));
ax_d = Axis(Δfig[1, 1]);
ax_dr = Axis(Δfig[2, 1]);

lines!(ax_d, 1:length(death_series[1]), death_series[1]; color = :black);
band!(
  ax_d, 1:length(death_series[1]), death_series[2], death_series[3],
  color = (:slategray, 0.4)
);

lines!(ax_dr, 1:length(death_rate_series[1]), death_rate_series[1]; color = :black);
band!(
  ax_dr, 1:length(death_rate_series[1]), death_rate_series[2], death_rate_series[3],
  color = (:slategray, 0.4)
);

Δfig

(mean(death_rate_series[1]), [mean(death_rate_series[i]) for i in 2:3])

# the average change, across counties, over the 2 year period, from a day to 10 to 40 days later, is 0.0025, with percentiles 2.5 and 97.5 at [-1.48, 0.025]

dtes = sort(info.date)[1+maximum(F):end];

overall_daily_val = [mean(death_rate_series[i]) for i in 1:3]

primary_est = [0.003, -0.011, 0.02];
mn, mx = Date("2020-04-10"), Date("2021-01-01")
rnge = (dtes .>= mn) .& (dtes .<= mx);
primary_val = [mean(death_rate_series[i][rnge]) for i in 1:3]
# restrict to treated unit + matches

ga_est = [0.105, -0.116, 0.318];
mn, mx = Date("2021-01-05") + [-Day(80), Day(80)];
rnge = (dtes .>= mn) .& (dtes .<= mx);
ga_val = [mean(death_rate_series[i][rnge]) for i in 1:3]

gub_est = [-0.144, -0.333, 0.008];
mn, mx = Date("2021-11-02") + [-Day(80), Day(80)];
rnge = (dtes .>= mn) .& (dtes .<= mx);
gub_val = [mean(death_rate_series[i][rnge]) for i in 1:3]

trump_est = [0.015, -0.11, 0.119];
mn, mx = [Date("2020-06-20") + -Day(80), Date("2020-09-13") + Day(80)];
rnge = (dtes .>= mn) .& (dtes .<= mx);
trump_val = [mean(death_rate_series[i][rnge]) for i in 1:3]

blm_est = [0.004, -0.019, 0.026];
mn, mx = [Date("2020-06-01") + -Day(80), Date("2020-09-01") + Day(80)];
rnge = (dtes .>= mn) .& (dtes .<= mx);
blm_val = [mean(death_rate_series[i][rnge]) for i in 1:3]

X = permutedims(
  hcat(
    overall_daily_val,
    primary_val, primary_est,
    ga_val, ga_est,
    gub_val, gub_est,
    trump_val, trump_est,
    blm_val, blm_est,
  )
);

ts = [0.75, 1.25, 1.75, 2.25, 2.75, 3.25, 3.75, 4.25, 4.75, 5.25, 5.75]
barcolors = [:blue, repeat([:blue, :darkred], 5)...]

errfig = Figure()
ax1 = Axis(errfig[1,1])

rb = rangebars!(
  ax1,
  ts,
  X[:, 2], X[:, 3],
  color = barcolors;
  whiskerwidth = 0
)

scatter!(ax1, ts, X[:, 1], markersize = 5, color = :black)

vlines!(ax1, [1:5...])

errfig

#