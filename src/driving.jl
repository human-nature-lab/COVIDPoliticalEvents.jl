# driving.jl

function dataload(
    datapath = nothing, savepath = nothing
)

    dat_store, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables = load_object(datapath);

    sort!(dat_store, [:fips, :date]);

    add_sma!(dat_store, :cases; n = 7, id = :fips);
    add_sma!(dat_store, :deaths; n = 7, id = :fips);
    add_sma!(dat_store, :death_rte; n = 7, id = :fips);
    add_sma!(dat_store, :case_rte; n = 7, id = :fips);

    # if weekly
    #     F = 1:6; L = -4:-1;
    #     dat_store = make_weekly(dat_store, pr_vars, trump_variables);
    # end

   return dat_store, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables, savepath 
end

function preamble(
    outcome, F, L, dat, scenario, covarspec, iters;
    borderexclude = false, convert_missing = true, modelfunc = deathmodel
)

    vn = VariableNames();

    obvars = [vn.pd, vn.ts16, :Exposure];

    treatments = [:primary, :gaspecial, :gub, :rallydayunion, :protest]

    # setup exclude variable
    # where a unit is a protest or rally,
    # but is exposure > 1 or less than 800 persons
    dat[!, :exclude] .= 0;

    # remove early primaries
    dat[(dat[!, :date] .< Date("2020-03-10")) .& (dat[!, :primary] .== 1), :exclude] .= 1;
    # remove big-enough-to-be-treated protests
    dat[(dat[!, :prsize] .< 800) .& (dat[!, :protest] .== 1), :exclude] .= 1;

    # remove rally exposures less than direct treatment
    dat[(dat[!, :Exposure] .>= 1) .& (dat[!, :rallydayunion] .== 1), :exclude] .= 1;

    # for each county-timetreated
    # look for the set of adjacent counties, if not treated already
    # treat and mark as excluded (these will necessarily be in other states)

    # combine the treated into `political`
    dat[!, :political] = 1 .* (sum([dat[!, trt] for trt in treatments]) .> 0);

    # adj mat, fips => row / col, row / col => fips
    if borderexclude
        adjmat, id2rc, rc2id = COVIDPoliticalEvents.getneighbordat();
        dat = exclude_border_counties(dat, :political, adjmat, id2rc, rc2id)
    end  

    model = modelfunc(
        scenario * covarspec, :political, Symbol(covarspec), dat,
        outcome;
        F = F, L = L,
        iterations = iters,
    );
    
    dat = dataprep(dat, model; convert_missing = convert_missing);
    
    return model, dat
end

## utilities

function gen_stratdict(dat)
    days = dat[dat[!, :political] .== true, :running]
    codes = dat[dat[!, :political] .== true, :fips]
    excludes = dat[dat[!, :political] .== true, :exclude]
    
    stratdict = Dict{Tuple{Int,Int}, Int}();
    for (r, c, ex) in zip(days, codes, excludes)
        stratdict[(r, c)] = ex + 1
        # 2 is excluded, # 1 are the actual events
    end
    return stratdict
end

"""
    remove_stratum(model; stratum = 2)
"""
function remove_stratum(model; stratum = 2)

    # remove elections prior to March 10
    obinclude = model.strata .== stratum
    @reset model.observations = model.observations[obinclude];
    @reset model.matches = model.matches[obinclude];

    @reset model.treatednum = length(model.observations)

    return model
end
