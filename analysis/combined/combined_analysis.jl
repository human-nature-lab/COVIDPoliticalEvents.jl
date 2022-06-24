# combined_analysis.jl

include("combined_preamble.jl");

@time match!(model, dat; treatcat = protest_treatmentcategories);

import JLD2; JLD2.save_object(scenario * string(model.outcome) * model.title * "combined_model_matched.jld2", model)

# x = JLD2.load_object(scenario * string(:cases) * model.title * "combined_model_matched.jld2")

@time balance!(model, dat);

using DataFramesMeta

stratdict = Dict{Tuple{Int,Int}, Int}();
for r in eachrow(@subset(dat, :political .== true))
    stratdict[(r[:running], r[:fips])] = r[:exclude] + 1
    # 2 is excluded, # 1 are the actual events
end

model = stratify(customstrat, model, :excluded, stratdict);

import JLD2; JLD2.save_object(scenario * string(model.outcome) * model.title * "combined_model_matched_post_strat.jld2", model)

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

@chain refinedmodel.results begin
    #@subset(:stratum .== 1)
    #select(Not(:stratum))
    groupby(:stratum)
    @combine(
        :att = mean(:att),
        :Σatt = sum(:att)
    )
end

@time calmodel, refcalmodel, overall = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = Dict(vn.cdr => 0.25),
  dooverall = true
);

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

TSCSMethods.save_object(
  savepath * "death_final_model.jld2", [model, refinedmodel, calmodel, refcalmodel]
)

# import Statistics:mean
# @chain refcalmodel.results begin
#     groupby(:stratum)
#     @combine(
#         :att = mean(:att),
#         :Σatt = sum(:att)
#     )
# end

outin = load_object("combined out/combined modelfull_deaths_excluded.jld2");
overall = load_object("combined out/deathscombined modelfull overall_estimate.jld2");

matches = outin.matchinfo;

ares, m_pre, trt_pre = inspection(
  outin.refcalmodel, matches, overall, dat, :running
);

plot_inspection(
    ares, overall, outin.model.outcome;
    stratum = 1, spth = nothing,
    plot_pct = true
)

pretreat = pretreatment(matches, model.outcome)

using Statistics
# variability in pct from before-treatment baseline
mean(100 .* (diff(ares.match_values) .* inv.(m_pre)))
100 .* extrema(diff(ares.match_values) .* inv.(m_pre))
var(100 .* diff(ares.match_values) .* inv.(m_pre))

mean(ares.pct)
var(ares.pct)
mean(ares.pct_lo)
mean(ares.pct_hi)

omod = load_object("combined modeldeathscombined modelfullcombined_model_matched_post_strat.jld2")

omod.observations
omod.matches[1].mus

ob = omod.observations[1]

mintime = 0

if ob[1] + maximum(omod.L) > mintime
adj = max(ob[1] + minimum(omod.L), mintime)
end

import TSCSMethods:@unpack, _estimate!, processunits

@unpack results, matches, observations, outcome, F, ids, reference, t, id, iterations = model

