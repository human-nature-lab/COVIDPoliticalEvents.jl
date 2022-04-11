# process the csv data

using CSV, DataFrames, DataFramesMeta, Dates
import JLD2

using StatsBase
import RData, CSVFiles

function process_csv(;
    id = :fips,
    patpth = nothing,
    dpth = "data/setup_data.csv",
    spth = "data/cvd_dat.jld2",
    trim_to_mob = true # limit to mobility data range
)

    dat = CSV.File(
        dpth;
        missingstrings = ["missing", "NA", ""], delim = ","
    ) |> DataFrame;

    # dd = describe(dat);
    # hcat(dd.variable, dd.eltype)

    # sort!(dat, [t, id]);

    #= temporary cleaning to deal with incomplete data
    remove dates outside range
    change missing that are left to zeros =#

    if !isnothing(patpth)
        pat = JLD2.load_object(patpth);
    
        # non mobility variables
        notmvs = [
            "fips"
            "date"
            "number_devices_residing"
            "number_devices_primary_daytime"
        ];
        
        # Date("2021-02-28")
        # trim to most recent mobility data
        if trim_to_mob
            @subset!(dat, :date .<= maximum(pat.date))
        end
        
        # gives all (date, fips) combinations in data
        datobs = select(dat, [:date, id]);
        datobs = leftjoin(datobs, pat, on = [:date, id]);
        
        for cn in setdiff(names(datobs), ["date", "fips"])
            datobs[ismissing.(datobs[!, cn]), cn] .= 0.0
            datobs[!, cn] = convert(Vector{Float64}, datobs[!, cn])
        end
        
        dat = leftjoin(dat, datobs, on = [:date, id]);
        
        # population adjust the paterns data
        for mvs in setdiff(names(pat), notmvs)
            mv = Symbol(mvs);
            dat[!, mv] .= dat[!, mv] .* dat[!, :pop];
        end
    end

    rename!(
        dat,
        :hispanic => Symbol("Pct. Hispanic"),
        :black => Symbol("Pct. Afr. American"),
        :cum_case_rte => Symbol("Cum. Case Rate"),
        :cum_death_rte => Symbol("Cum. Death Rate"),
        :state => :State,
        :abbr => Symbol("State Abbr."),
        :firstcase => Symbol("Date of First Case"),
        :bacc => Symbol("Pct. with Bacc. Deg."),
        :median_inc_ln => Symbol("Median Income (log)"),
        :tot_reg => Symbol("Tot. Registered Voters"),
        :trn_rte => Symbol("In-person Turnout Rate"),
        :pop_density => Symbol("Pop. Density"),
        :trump_share_2016 => Symbol("Trump 2016 Vote Share"),
        :perc_65_up => Symbol("Pct. 65 yrs and Above")
    );

    #=
    turnout data corrections

    Nebraska counties that satisfy criteria below, should be not treated as 

    KY counties should be made missing

    too early anyway:
    CA (four rural, very small pop. counties)
    ID (two counties)
    ND (39/50, caucuses)
    TX (12 counties)

    KY -- state data not reliale, make missing
    NE (11 counties) -- checked that these have no in-person votes, so de-treat
    =#

    # KY data is not reliable, so make turnout missing for whole state
    dat[(dat.primary .== 1) .& (dat.State .== "Kentucky"), Symbol("In-person Turnout Rate")] .= missing;

    subdat = @views(dat[dat.primary .== 1, :]);
    for i in 1:nrow(subdat)
    if !ismissing(subdat[i, Symbol("In-person Turnout Rate")])
        c1 = subdat[i, Symbol("In-person Turnout Rate")] == 0.0;
        c2 = subdat[i, :primary] == 1;
        c3 = subdat[i, :State] == "Nebraska";
        # c4 = subdat[i, :State] == "Kentucky";
        if c1 & c2 & c3
        subdat[i, :primary] = 0
        end
    end
    end

    sort!(dat, [:fips, :running])

    JLD2.save_object(spth, dat);

    return dat
end
