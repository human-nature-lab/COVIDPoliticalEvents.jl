# disag protest

using DataFrames, DataFramesMeta, StatsBase
import CSV

# check data
function checkworkds!(prout, col, words)
    for (i, (e1, e2)) in enumerate(zip(prout[!, :pr_actor_type], prout[!, :pr_notes]))
        c1 = any([occursin(word, e1) for word in words])
        c2 = any([occursin(word, e2) for word in words])
        prout[i, col] = c1 | c2
    end
    return prout
end

prout = CSV.read("covid-19-data/data/disag_proc.csv", DataFrame)

blm_words = [
    "BLM", "Black Lives Matter", "African", "NAACP", "brutality",
    "racial justice", "social justice", "Floyd", "Taylor", "color"
]
cvd_words = ["Coronavirus", "coronavirus", "COVID", "COVID-19", "COVID19", "covid"]
blue_words = ["Trump", "Back the Blue", "Pro-Police Group (United States)", "Blue Lives Matter"]

# create protest categories
prout[!, :pr_blm] = fill(false, nrow(prout))
prout[!, :pr_bluetrump] = fill(false, nrow(prout))
prout[!, :pr_covid] = fill(false, nrow(prout))

cols = [:pr_blm, :pr_bluetrump, :pr_covid]

checkworkds!(prout, :pr_blm, blm_words)
checkworkds!(prout, :pr_bluetrump, blue_words)
checkworkds!(prout, :pr_covid, cvd_words)

sum(@subset(prout, :size .>= 800).pr_covid)
sum(prout.pr_covid)

agg = @chain prout begin
    groupby([:fips, :pr_event_date])
    combine(
        :size => sum => :size,
        :event_count => sum => :event_count,
        [col => any => col for col in cols]...
    )
end

info = @chain agg begin
    @subset(:size .>= 800)
    combine(
        [col => sum => col for col in cols]...
    )
end

# breakdown of protest types
nr = nrow(@subset(agg, :size .>= 800));
hcat(cols, [round(c * inv(nr) * 100; digits = 1) for c in info[1,:]]);

rename!(agg, :event_count => :prcount, :size => :prsize)

@subset!(agg, :prsize .>= 400)

# create event_variable
agg[!, :protest] .= 1

import JLD2.save_object
save_object("covid-19-data/data/final_protest_data.jld2", agg)
