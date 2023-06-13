# figure s 37.jl
# make supplementary figure 37.
# useful code for: map plots in julia makie, spillover exposure plotting with minimum exposure

using GeoTables
# using Shapefile
using MeshViz
using CairoMakie
using DataFrames, DataFramesMeta
using COVIDPoliticalEvents

pth = "plotting/Supplementary Figure 37/ne_10m_admin_2_counties/ne_10m_admin_2_counties.shp"

gtbl = GeoTables.load(pth)
# table = Shapefile.Table(pth)

df = DataFrame(gtbl)

ga = @subset(df, :REGION .== "GA");

C, id2ind, ind2id = COVIDPoliticalEvents.getneighbordat();

codf = DataFrame(:ind => Int[], :fips => Int[]) # county df
for (k, v) in id2ind
    push!(codf, [v, k])
end
sort!(codf, :ind)
@subset!(codf, :fips .>= 13000, :fips .<= 13510);
gamat = C[codf.ind, codf.ind]

using Graphs, MetaGraphs
using ColorSchemes

vtx = codf.fips
g = SimpleGraph(size(gamat, 1), 0)
for i in 1:size(gamat, 1), j in 1:size(gamat, 1)
    if i < j
        if gamat[i, j] == 1
            add_edge!(g, i, j)
        end
    end
end

# Fulton 13121
# DeKalb 13089
# Atikson 13003
# Berrien 13019


## plot
codf.fips = string.(codf.fips) 
codf.fips == sort(ga.CODE_LOCAL) # we don't have to join or match if true
sort!(ga, :CODE_LOCAL)

edf = DataFrame(
    :direct => Int[], :fips => Int[], :ind => Int[], :exposure => Int[]
);

let
    for tc in [13089, 13003, 13019]
        coind = findfirst(vtx .== tc)
        nd = neighborhood_dists(g, coind, 3)

        for (v, d) in nd
            push!(edf, [tc, vtx[v], v, d])
        end
    end
end

edf2 = @chain edf begin
    groupby([:fips, :ind])
    combine(:exposure => minimum => :exposure)
    sort(:ind)
end

let
    exposure = Dict{Int, Int}();
    pal = colorschemes[:RdYlGn_8];
    clrs = Vector{Any}(undef, length(vtx))
    clrs[:] = fill(RGBf(1, 1, 1), length(vtx));

    clrs[edf2.ind] = [pal[1+d] for d in edf2.exposure]

    fg = Figure(resolution = (800, 800));
    ax = Axis(fg[1, 1])
    viz!(
        ax, ga.geometry,
        showfacets = true, facetcolor = :black, color = clrs
    )
    hidedecorations!(ax)

    CairoMakie.save("plotting/figures_supporting/s37.svg", fg)
    fg
end