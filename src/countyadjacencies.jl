# counteradjacencies.jl

function mkDataFrame(cts)
    df = DataFrame()
    for (k, v) in cts
        df[!, k] = v
    end
    return df
end

"""
        getneighbordat(;
            durl = "https://www2.census.gov/geo/docs/reference/county_adjacency.txt"
        )

Get the county adjacecy info from the US Census Bureau website.

"""
function getneighbordat(;
    durl = "https://www2.census.gov/geo/docs/reference/county_adjacency.txt"
)

    C = CSV.read(
        download(durl),
        DataFrame;
        header = false
    )

    brks = findall((ismissing.(C.Column2) .- 1) * .- 1 .== 1)
    # last is nrow(C)

    cc = zeros(Int64, nrow(C), 2);
    cnt = 0
    for i = eachindex(brks)
        i1 = brks[i]
        cnt += 1
        if i < length(brks)
            i2 = brks[i + 1] - 1
        else
            i2 = nrow(C)
        end
        cc[(i1 : i2), 1] = fill(C.Column2[i1], i2 - i1 + 1)
        cc[(i1 : i2), 2] = C.Column4[i1 : i2]
    end

    ccd = sort!(DataFrame(from = cc[:,1], to = cc[:,2]), :from);

    ul = unique(ccd.from);
    UL = zeros(Int64, length(ul), 2);
    UL[:,1] = ul;
    UL[:,2] = 1:length(ul);

    ky = DataFrame(id = UL[:,1], numfrom = UL[:,2]);
    ky2 = DataFrame(id = UL[:,1], numto = UL[:,2]);

    ccd = leftjoin(ccd, ky, on = [:from => :id]);
    ccd = leftjoin(ccd, ky2, on = [:to => :id]);

    # C is the county adj matrix, in increasing-fips order
    C = zeros(Int64, length(ul), length(ul));

    id2ind = Dict(UL[:, 1] .=> UL[:, 2])
    ind2id = Dict(UL[:, 2] .=> UL[:, 1])


    # for each unique treated observation, look across its unit's row and mark the others as treated
    for i = eachindex(1:nrow(ccd))
        C[id2ind[ccd.from[i]], id2ind[ccd.to[i]]] = 1;
    end

    return C, id2ind, ind2id
end
