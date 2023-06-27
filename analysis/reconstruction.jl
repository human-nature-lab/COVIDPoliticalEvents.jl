# reconstruction.jl
# reconstruct prior estimate from modelrecord

using DataFrames, DataFramesMeta
using Accessors
using Statistics

function tupleize(df, ind, x, y)
    if ismissing(ind)
        ind = 1:nrow(df)
    end
    return tuple.(df[ind, x], df[ind, y])
end

function matchassign!(newmatches, ld_matching, fmin, ids)
    for (i, r) in enumerate(eachrow(ld_matching))
        for (fs, mus) in zip(r[:fs], r[:matchunitsets])
            fix = fs - fmin + 1
            for mu in mus
                uix = findfirst(mu .== ids)
                newmatches[i].mus[uix, fix] = true
            end
        end
    end
end

function newmatching(ld)
    kp = .!ld.obsinfo.removed;
    ld_obs = tupleize(ld.obsinfo, kp, :timetreated, :treatedunit);
    
    ids = sort(ld.refcalmodel.ids);
    idnum = length(ids);
    fmin = minimum(ld.refcalmodel.F);
    
    ld_matching = @chain ld.matchinfo begin
    groupby([:timetreated, :treatedunit])    
    combine(
        :f => Ref => :fs,
        :matchunits => Ref => :matchunitsets
        )
    end;
    ld_matching.obs = tupleize(ld_matching, missing, :timetreated, :treatedunit);
    
    sidx = sortperm(ld_matching.obs);
    ld_matching.obs = ld_matching.obs[sidx];

    newmatches = Vector{TSCSMethods.TobR}(undef, length(ld_obs));
    for i in eachindex(ld_obs)
        newmatches[i] = TSCSMethods.TobR(
            mus = fill(0, idnum, length(ld.refcalmodel.F))
        )
    end
    matchassign!(newmatches, ld_matching, fmin, ids)

    if length(ld.refcalmodel.strata) > 0
        ld_stra = ld.refcalmodel.strata[sidx];
        return newmatches, ld_matching, ids, ld_stra
    else
        return newmatches, ld_matching, ids
    end
end

function process_oe(oe_rcm)

    return DataFrame(
        :att => oe_rcm.att,
        :lwr => first(oe_rcm.percentiles),
        :upr => last(oe_rcm.percentiles),
        :bayesfactor => oe_rcm.bayesfactor,
        :pvalue => oe_rcm.pvalue,
    )
end


function process_oe(oe_rcm, labels)

    return DataFrame(
            :label => [get(labels, Int(x), missing) for x in oe_rcm.stratum],
            :att => oe_rcm.att,
            :lwr => [first(x) for x in oe_rcm.percentiles],
            :upr => [last(x) for x in oe_rcm.percentiles],
            :bayesfactor => oe_rcm.bayesfactor,
            :pvalue => oe_rcm.pvalue,
            :stratum => oe_rcm.stratum,
        )
end

function upconvert(oe_proc)
    oe_proc2 = deepcopy(oe_proc)
    oe_proc2.att = round.(oe_proc.att .* 100; digits = 3)
    oe_proc2.lwr = round.(oe_proc.lwr .* 100; digits = 3)
    oe_proc2.upr = round.(oe_proc.upr .* 100; digits = 3)
    oe_proc2.bayesfactor = round.(oe_proc.bayesfactor; digits = 3)
    oe_proc2.pvalue = round.(oe_proc.pvalue; digits = 3)
    return oe_proc2
end
