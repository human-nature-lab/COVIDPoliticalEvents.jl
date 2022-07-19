"""
        get_county_dist_dict(
            pth = "../../../covid-19-data/data/sf12010countydistancemiles.csv"
        )

Use [NBER County Distance Database](https://www.nber.org/research/data/county-distance-database) to check distances between counties.

Pairs are sorted by fips code.
"""
function county_dist_dict(
    ; pth = "../../../covid-19-data/data/sf12010countydistancemiles.csv"
)
    cdist = CSV.read(pth, DataFrame)

    cdict = Dict{Tuple{Int, Int}, Float64}();
    for r in eachrow(cdist)
    x, y = sort([r[:county1], r[:county2]])
    cdict[(x, y)] = r[:mi_to_county]
    end
    return cdict
end

"""

"""
function get_county_distances(matches, cdict)

    matches[!, :match_miles] .= 0.0;
    for r in eachrow(matches)
    cnt = 0
    v = 0
    for rm in r[:matchunits]
    tple = Tuple(sort([r[:treatedunit], rm]))
    vi = get(cdict, tple, missing)
    if !ismissing(vi)
        cnt += 1
        v += vi
    end
    end
    r[:match_miles] = v * inv(cnt)
    end

    return matches
end

function calc_county_distances(matches)
    q25(x) = quantile(x, 0.025)
    q975(x) = quantile(x, 0.975)

    return @chain unique(matches, [:timetreated, :treatedunit]) begin
        combine(
            :match_miles => mean => :mean,
            :match_miles => std => :std,
            :match_miles => minimum => :min,
            :match_miles => maximum => :max,
            :match_miles => q25 => :p25,
            :match_miles => q975 => :p975
        )
    end
end

function match_distances(matches)
    cdict = county_dist_dict()
    matches = get_county_distances(matches, cdict)
    countydists = calc_county_distances(matches)
    return countydists
end
