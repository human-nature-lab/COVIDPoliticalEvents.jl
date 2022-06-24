# combined_analysis.jl

include("combined_preamble.jl");

@time match!(model, dat; treatcat = protest_treatmentcategories);

import JLD2; JLD2.save_object(savepath * scenario * string(model.outcome) * model.title * "combined_model_matched.jld2", model);

# x = JLD2.load_object(scenario * string(:cases) * model.title * "combined_model_matched.jld2")

@time balance!(model, dat);

using DataFramesMeta

stratdict = Dict{Tuple{Int,Int}, Int}();
for r in eachrow(@subset(dat, :political .== true))
    stratdict[(r[:running], r[:fips])] = r[:exclude] + 1
    # 2 is excluded, # 1 are the actual events
end

model = stratify(customstrat, model, :excluded, stratdict);

import JLD2; JLD2.save_object(savepath * scenario * string(model.outcome) * model.title * "combined_model_matched_post_strat.jld2", model)

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

using Statistics

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
  savepath * "Rt_final_model.jld2", [model, refinedmodel, calmodel, refcalmodel]
)


TSCSMethods.save_object(
    savepath * string(model.outcome )* model.title * " overall_estimate.jld2", overall
);

import Statistics:mean
@chain refcalmodel.results begin
    groupby(:stratum)
    @combine(
        :att = mean(:att),
        :att50th = mean($(Symbol("50.0%"))),
        :Σatt = sum(:att)
    )
end

matches = matchinfo(model);

ares, m_pre, trt_pre = inspection(refcalmodel, matches, overall);

fg = plot_inspection(ares, overall, model.outcome; stratum = 1, plot_pct = true)
