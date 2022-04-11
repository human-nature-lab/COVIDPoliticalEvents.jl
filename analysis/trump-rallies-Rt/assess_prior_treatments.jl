push!(ARGS, "full")

include("preamble.jl");

tr = model.treatment;

using DataFrames, DataFramesMeta
import TSCSMethods:quantile


trted = @subset(dat, $tr .== 1)
@select!(trted, :fips, $(vn.t), :Exposure)
sort!(trted, [:fips, vn.t, :Exposure])


for e in sort(unique(trted.Exposure))
    trted[!, Symbol("previous" * string(e))] .= 0;
end

gdf = groupby(trted, vn.id);

for g in gdf
  (is, _) = parentindices(g);
  for (gi, i) in enumerate(is)
    if i > 1
      for giprime in 1:(gi-1)
        if g[gi, vn.t] - g[giprime, vn.t] < 30
            if g[giprime, :Exposure] .== 1
                g.previous1[gi] += 1
            elseif g[giprime, :Exposure] .== 2
                g.previous2[gi] += 1
            elseif g[giprime, :Exposure] .== 3
                g.previous3[gi] += 1
            elseif g[giprime, :Exposure] .== 4
                g.previous4[gi] += 1
            end
        end
      end
    end
  end
end

qtes = Dict{Int, Vector{Float64}}();
for e in sort(unique(trted.Exposure))
    qtes[e] = quantile(trted[!, Symbol("previous" * string(e))])
end;

quantile(trted.previous);
import StatsBase
sort(StatsBase.countmap(trted.previous))
@subset(trted, :previous .> 0)

dtrted = @subset(trted, :Exposure .== 1);
sort(StatsBase.countmap(dtrted.previous))
