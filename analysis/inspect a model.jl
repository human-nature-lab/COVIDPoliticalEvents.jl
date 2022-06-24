# inspect a model



# death_models = [
#     "primary out/ primary full_deaths_.jld2",
#     "ga out/ ga nomob_deaths_.jld2",
#     "gub out/ gub out nomob_deaths_.jld2",
#     "rally out/ rally nomob_deaths_exposure.jld2",
#     "protest out/ protest full_deaths_.jld2"
# ];



# md, mdw = [load_object(out * models[i]) for i in 1:2];

infos = DataFrame(:treated => Bool[], vn.cd => Float64[], :scenario => String[])
(model, nm) = collect(zip(models, scenarios))[1]
for (model, nm) in zip(models, scenarios)

    md = load_object(model)
    push!(results, md.refcalmodel.results)
    # mdw.refcalmodel.results

    info = begin
        info = flatten(md.matchinfo, :matchunits)
        Y = unique(info[!, [:timetreated, :treatedunit]])
        Y[!, :treated] .= true
        rename!(Y, :treatedunit => :unit)
        X = unique(info[!, [:timetreated, :matchunits]])
        rename!(X, :matchunits => :unit)
        X[!, :treated] .= false
        info = vcat(X, Y)
        info[!, :ref] .= info.timetreated .- 1
        info
    end

    info = leftjoin(
        info, dat,
        on = [:ref => :running, :unit => :fips]
    )

    infoout = @chain info begin
        groupby(:treated)
        combine(
            vn.cd => mean => vn.cd
        )
    end
    infoout[!, :scenario] .= nm
    infos = vcat(infos, infoout)
end

# deaths
oe_deathmod, mcd_pre, tcd_pre, d_gb = impute_results(overall_models[1], dat); 

fig = figure_6(oe_deathmod, :deaths)
save("combined out/overall_deaths.svg", fig)

### paper values

# mean att
round.([doe[1], doe[2][1], doe[2][3]]; digits = 4)

# mean P.O. vs. observed
mean_po = begin
    br = mean(dm.deaths) - doe[1]
    ptiles = br .- doe[2]
    br, ptiles[1], ptiles[3]
end
mean_observed = mean(dm.deaths)

round.(mean_po; digits = 6)
round.(mean_observed; digits = 6)

## sum att
round.([doe[1], doe[2][1], doe[2][3]] .* 31; digits = 4)

# sum P.O. vs. observed

round(sum(dm.deaths); digits = 4)
round.(
    [sum(dm.counter_post), sum(dm.counter_post_lwr), sum(dm.counter_post_upr)];
    digits = 4
)

### end paper values

bcfig = Figure();
bcax = Axis(bcfig[1,1]);

fill_baxis!(bcax, c_gb, 10:40)
Legend(bcfig[1,2], bcax, "Covariates", framevisible = false);

bcfig

## output

## means

oes = [JLD2.load_object(e) for e in overall_oes];

# daily values
doe = oes[1][1];
coe = oes[2][1];

# potential outcomes

mean(dm.deaths)
mean(dm.counter_post)
mean(dm.counter_post_lwr), mean(dm.counter_post_upr)

mean(cm.cases)
mean(cm.counter_post)
mean(cm.counter_post_lwr), mean(cm.counter_post_upr)


## sums (over outcome window)

doe .* 40
coe .* 40 # this is over 50 though

# total impacts
doe .* (40 * mean(dm.treated))
coe .* (40 * mean(cm.treated)) # this is over 50 though

sum(dm.att)
sum(dm.deaths)
sum(dm.counter_post)
sum(dm.counter_post_lwr), sum(dm.counter_post_upr)

sum(cm.att[11:end])
sum(cm.cases[11:end])
sum(cm.counter_post[11:end])
sum(cm.counter_post_lwr[11:end]), sum(cm.counter_post_upr[11:end])

## other
# differences
mean(dm.deaths) - mean(dm.match_values)
dm.deaths[1] - dm.match_values[1]

mean(cm.cases) - mean(cm.match_values)
cm.cases[1] - cm.match_values[1]

ram_oe = load_object("rally out/case_rte rally nomoboverall_estimate.jld2");
ram_oe

# check cases trump rally
ram = load_object("rally out/ rally nomob_case_rte_exposure.jld2");
mean(@subset(ram.refcalmodel.results, :stratum .== 1).att)