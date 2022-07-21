# examine_imputation.jl

using TSCSMethods, COVIDPoliticalEvents
import JLD2.load_object

# load a refcalmodel, overall est, and modelrecord
packets = [
    ("combined cases out/rate/combined model case_rte combined modelfullrefcalmodel.jld2", "combined cases out/rate/case_rtecombined modelfulloverall_estimate.jld2", )
]

matches = recordset.matchinfo;

# countydists = match_distances(matches)

ares, m_pre, trt_pre = inspection(
  refcalmodel, matches, overall, dat, :running
);

plot_inspection(
    ares, overall, refcalmodel.outcome;
    stratum = 1, spth = nothing,
    plot_pct = true
)

# sum(actual - would have) = total increase

# the CI ones aren't necessarily right
rx = ares[!, refcalmodel.outcome];
DataFrame(
    :lwr => sum(rx - ares[!, :counter_post_lwr]) * mean(ares.treated),
    :mean => sum(rx - ares[!, :counter_post]) * mean(ares.treated),
    :upr => sum(rx - ares[!, :counter_post_upr]) * mean(ares.treated),
);

overall[1][2][1] * 31 * mean(ares.treated)
overall[1][1] * 31 * mean(ares.treated)
overall[1][2][3] * 31 * mean(ares.treated)