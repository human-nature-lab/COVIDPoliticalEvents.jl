# power explore.jl

using DataFrames, DataFramesMeta, JLD2
using Statistics

pth = "power out/" 
rd = readdir("power out");
rd = rd[occursin.(".jld2", rd)];
rd = rd[occursin.("epi", rd)];

rd = sort(rd)
rd = rd[[4, 5, 2, 3, 6,1]]

using PrettyTables

allres = DataFrame()
oeallres = DataFrame()

for rx in rd
    res, oe = load_object(pth * rx)

    ares = @chain res begin
        groupby(:jump)
        combine(:power => mean => :power)
    end

    ares[!, :name] .= rx

    append!(allres, ares)

    oe[!, :name] .= rx 

    append!(oeallres, oe)
end

nmes = unique(allres.name)
sres = @subset(allres, :name .== nmes[5]);

open("output.txt", "w") do f
    # pretty_table(allres, tf = tf_markdown)
    pretty_table(f, allres, tf = tf_markdown)
end

@chain res begin
    groupby(:jump)
    combine(:power => mean => :power)
end

oa = @chain allres begin
    groupby(:jump)
    combine(:power => mean => :power)
end

pretty_table(oa)

mean(oeallres.power)

mean(allres.power)

unique(res.jump)
mean(res.power)

mean(res.ATT)
oe

# using TSCSMethods
# x = load_object("combined_power_sim/overall_death_rte_refcalmodel_nomob.jld2")

