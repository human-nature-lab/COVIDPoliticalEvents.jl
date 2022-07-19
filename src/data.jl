# data.jl

"""
        add_sma!(dat, variable; n = 7, id = :fips)

Add a simple moving average of `variable` to a DataFrame, over the previous n = 7 days.
"""
function add_sma!(dat, variable; n = 7, id = :fips)
    mao = Symbol(String(variable) * "_sma")
    dat[!, mao] = Vector{Union{Float64, Missing}}(undef, nrow(dat));
    codes = sort(unique(dat[!, id]))

    for code in codes
        trnd = dat[dat[!, id] .== code, variable];
        dat[dat[!, id] .== code, mao] = sma(trnd; n = n)
        dat[(dat[!, id] .== code) .& isnan.(dat[!, mao]), mao] .= missing
    end

end

"""
    deleteincomplete!(dat, t, id, treatment, F, cutoff)

Remove observations for a unit with incomplete match periods (specified by cutoff, days before treatment, furthest day back to require that is included) in the outcome window for that treatment event. Mutates the data.
"""
function deleteincomplete!(dat, t, id, treatment, F, cutoff)
    # if there is no date at least to cutoff, remove data for unit up to fmax
    tobs = unique(dat[dat[!, treatment] .== 1, [id, t]]);

    removal_indices = Int64[];

    for r in eachrow(tobs)
        treat_cutoff = r[t] - cutoff;
        c1 = dat[!, id] .== r[id];
        c2 = dat[!, t] .>= treat_cutoff;
        c3 = dat[!, t] .<= (r[t] + maximum(F));

        tf = @views dat[c1 .& c2 .& c3, t];
        keep = minimum(tf) <= treat_cutoff;
        if !keep
            c2b = dat[!, t] .>= (r[t] + minimum(F)); # remove during outcome window
            append!(removal_indices, findall(c1 .& c2b .& c3))
        end
    end
    delete!(dat, removal_indices)
    return dat
end

"""
    treatstateondate!(
        dat;
        state_abbreviation = ["VA", "GA"],
        eventdate = Date("2021-01-05"),
        treatment_variable = :gaspecial,
        date_column = :date
    )

Create the treatment variable for an event in a whole state, on a day). e.g. the ga special election.
"""
function treatstateondate!(
    dat;
    state_abbreviation = ["VA", "NJ"],
    eventdate = Date("2021-11-02"),
    treatment_variable = :gub,
    date_column = :date
)

    dat[!, treatment_variable] .= 0;

    if typeof(state_abbreviation) == Vector{String}
    for state_abbreviation in state_abbreviation
        c1 = (dat[!, VariableNames().abbr] .== state_abbreviation) .& (dat[!, date_column] .== eventdate);
        dat[c1, treatment_variable] .= 1;
    end
    else
    c1 = (dat[!, VariableNames().abbr] .== state_abbreviation) .& (dat[!, date_column] .== eventdate);
    dat[c1, treatment_variable] .= 1;
    end

    return dat
end

"""
    filter_treated!(model;  mintime = 10)

remove observations considered too early
"""
function filter_treated(model; mintime = 10)

    # remove elections prior to March 10
    obtimes = [model.observations[i][1] for i in eachindex(model.observations)];
    obinclude = obtimes .>= mintime;
    @reset model.observations = model.observations[obinclude];
    @reset model.matches = model.matches[obinclude];
    # @reset model.results = TSCSMethods.DataFrame();

    @reset model.treatednum = length(model.observations)

    return model
end

"""
    primary_filter!(model;  mintime = 10)

remove observations considered too early
"""
function primary_filter(model;  mintime = 10)

    # remove elections prior to March 10
    obtimes = [model.observations[i][1] for i in eachindex(model.observations)];
    obinclude = obtimes .>= mintime;
    @reset model.observations = model.observations[obinclude];
    @reset model.matches = model.matches[obinclude];
    # @reset model.results = TSCSMethods.DataFrame();

    @reset model.treatednum = length(model.observations)

    return model
end

"""
    dataprep!(
        dat, model;
        t_start = nothing, t_end = nothing,
        remove_incomplete = false,
        incomplete_cutoff = nothing,
        convert_missing = true
    )

Prepare the data for analysis:
  1. Limit date range to first day of matching period for first treatment, up to last outcome window day for last treatment.
  2. Optionally, remove observations over the outcome window for a treatment event where the corresponding matching period (or portion thereof) is not present in the data. The portion is specified by incomplete_cutoff, the first day before a treatment event that must be included.
  3. Optionally, shift (lead) the cumulative death rate and cumulative case rate variables by the lower 5th percentile day of their infection-to-death distributions. This regards covariate matching.
"""
function dataprep(
    dat, model;
    t_start = nothing, t_end = nothing,
    remove_incomplete = false,
    incomplete_cutoff = nothing,
    convert_missing = true,
)

    @unpack t, id, treatment, F, L = model;

    if isnothing(t_start)
        ttmin = minimum(dat[dat[!, treatment] .== 1, t]);
        c1 = dat[!, t] .>= ttmin + L[begin];
    else
        c1 = dat[!, t] .>= t_start
    end

    if isnothing(t_end)
        ttmax = maximum(dat[dat[!, treatment] .== 1, t]);
        c2 = dat[!, t] .<= ttmax + F[end];
    else
        c2 = dat[!, t] .<= t_end;
    end

    dat = dat[c1 .& c2, :];

    if remove_incomplete
        deleteincomplete!(dat, t, id, treatment, F, incomplete_cutoff)
    end

    sort!(dat, [id, t])

    if convert_missing
        for covar in model.covariates
            dat[!, covar] = Missings.disallowmissing(dat[!, covar])
        end
    end

    return dat
end

"""
    dataprep!(
        dat, treatment, F, L, covariates;
        t_start = nothing, t_end = nothing,
        remove_incomplete = false,
        incomplete_cutoff = nothing,
        convert_missing = true
    )

Prepare the data for analysis:
  1. Limit date range to first day of matching period for first treatment, up to last outcome window day for last treatment.
  2. Optionally, remove observations over the outcome window for a treatment event where the corresponding matching period (or portion thereof) is not present in the data. The portion is specified by incomplete_cutoff, the first day before a treatment event that must be included.
  3. Optionally, shift (lead) the cumulative death rate and cumulative case rate variables by the lower 5th percentile day of their infection-to-death distributions. This regards covariate matching.
"""
function dataprep(
    dat, treatment, F, L;
    t_start = nothing, t_end = nothing,
    remove_incomplete = false,
    incomplete_cutoff = nothing,
    convert_missing = true,
    covariates = nothing
)

    vn = VariableNames()

    @unpack t, id, cdr = vn;

    if isnothing(t_start)
        ttmin = minimum(dat[dat[!, treatment] .== 1, t]);
        c1 = dat[!, t] .>= ttmin + L[begin];
    else
        c1 = dat[!, t] .>= t_start
    end

    if isnothing(t_end)
        ttmax = maximum(dat[dat[!, treatment] .== 1, t]);
        c2 = dat[!, t] .<= ttmax + F[end];
    else
        c2 = dat[!, t] .<= t_end;
    end

    dat = dat[c1 .& c2, :];

    if remove_incomplete
        deleteincomplete!(dat, t, id, treatment, F, incomplete_cutoff)
    end

    sort!(dat, [id, t])

    if convert_missing
        for covar in covariates
            dat[!, covar] = Missings.disallowmissing(dat[!, covar])
        end
    end

    return dat
end

function ga_turnout(dat; datpath = "covid-19-data/data/")

    vn = VariableNames()

    ge = CSV.read(
        datpath * "ga_election_results_clean.csv", 
        DataFrame
    );

    select!(ge, Not(Symbol("Total Votes")));

    urlb = HTTP.get(
        "https://raw.githubusercontent.com/kjhealy/fips-codes/master/state_and_county_fips_master.csv"
    ).body;

    ftab = CSV.read(urlb, DataFrame);
    ftab = @subset(ftab, :state .== "GA");

    ftab = @eachrow ftab begin
        @newcol :county::Vector{String}
        :county = replace(:name, " County" => "")
    end;

    select!(ftab, [:fips, :county]);

    ge = leftjoin(ge, ftab, on = :County => :county);

    copop = unique(select(dat, [:fips, :pop]));

    ge = leftjoin(ge, copop, on = :fips);

    ge.fips = convert(Vector{Int64}, ge.fips);

    select!(ge, Not(:County))
    ge[!, vn.tout] = ge.day_of ./ ge.pop;

    return ge
end;

function merge_Rt_data(dat, transdatafile)
    td = CSV.read(transdatafile, DataFrame);
    rename!(td, Symbol("Rt.hi") => :Rt_hi, Symbol("Rt.lo") => :Rt_lo)
    select!(td, :fips, :date, :Rt) # :Rt_hi, :Rt_lo
    # hi and low estimates are missing?
    tdict = Dict{Tuple{Int, Dates.Date}, Float64}();

    # (unit, dte, rval) = collect(zip(td.fips, td.date, td.Rt))[1]
    for (unit, dte, rval) in zip(td.fips, td.date, td.Rt)
        tdict[(unit, dte)] = rval
    end

    dat[!, :Rt] = Vector{Union{Float64, Missing}}(missing, nrow(dat));

    for r in eachrow(dat)
        r[:Rt] = get(tdict, (r[:fips], r[:date]), missing)
    end

    return dat
end

"""
    exclude_border_counties(dat, treatment, adjmat, id2rc, rc2id)

Exclude the border counties (by treating and putting into a different strata that we throw out) for units that are already considered treated and not exluded (directly treated observations).

N.B. this removes adj. counties for the BLM protests
"""
function exclude_border_counties(dat, treatment, adjmat, id2rc, rc2id)
    
    # for each row create a vector that records the source counties
    tp = Union{Missing, Vector{Int}}[]
    for i in 1:nrow(dat); push!(tp, missing) end;
    dat[!, :source] = tp;

    # select the treated counties at time of treatment who are not excluded
    # that is, select the directly treated units
    tobs = @views dat[(dat[!, treatment] .== 1) .& (dat[!, :exclude] .== 0), [:date, :fips]];

    # only consider counties that are not already treated or excluded
    c3 = (dat[!, treatment] .== 0) .& (dat[!, :exclude] .== 0);
    subdat = @views dat[c3, :];

    _bordercounties!(subdat, tobs, adjmat, id2rc, rc2id, treatment)
    return dat
end

function _bordercounties!(subdat, tobs, adjmat, id2rc, rc2id, treatment)
    for tob in eachrow(tobs)
        bordercounties = [
            rc2id[x] for x in findall(adjmat[:, id2rc[tob[:fips]]] .== 1)
        ];

        # don't need to worry about the county itself -> already excluded
        # only bother if there are bordering counties
        if length(bordercounties) > 0
            # get a view on the border counties' data
            c1 = (subdat[!, :fips] .∈ Ref(bordercounties))
            c2 = (subdat[!, :date] .== tob[:date])
            subsubdat = @views subdat[c1 .& c2, :];

            # if there are any relevant spillover counties
            if sum(c1 .& c2) > 0
                # treat & exclude; store the spillover source
                for l in eachindex(subsubdat[!, :exclude])
                    subsubdat[l, treatment] = 1
                    subsubdat[l, :exclude] = 1

                    # default is missing
                    # so if it wasn't applicable before, create the vector
                    if ismissing(subsubdat[l, :source])
                        subsubdat.source[l] = [tob[:fips]]
                    else
                        # there will be many cases where a county at t
                        # receives spillover from more than one treatment event
                        # (e.g., it borders >1 treated units at t)
                        append!(subsubdat[l, :source], tob[:fips])
                    end
                end
            end
        end
    end
end

# test border county situation
# Kent Co., RI gets spillover from two ct counties on Aug. 11 primary
# kent = 44003; windham = 09015; newlondon = 09011;
# ds = dat[(.!(ismissing.(dat.source))), :];
# @subset(
#   dat, :date .== Date("2020-08-11"), :fips .== kent
# )[!, [:political, :source]]
