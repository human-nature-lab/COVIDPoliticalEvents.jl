function finish_data(dat, datapath)
    # add other data to dat  
    vn = VariableNames();
  
    # add the GA special turnout data
    ga_election = ga_turnout(dat; datpath = datapath)
    ed = Dict(ga_election[!, vn.id] .=> ga_election[!, vn.tout]);
    dat[!, vn.gaout] .= 0.0;
    tochng = @views dat[dat.State .== "Georgia", [vn.id, vn.gaout]]
    for r in eachrow(tochng)
        r[vn.gaout] = ed[r[vn.id]]
    end
  
    # mask data
    rare = Symbol("Rarely Mask");
    http_response = download("https://raw.githubusercontent.com/nytimes/covid-19-data/master/mask-use/mask-use-by-county.csv")
    maskdat = CSV.File(http_response) |> DataFrame
    @transform!(maskdat, $rare = :NEVER + :RARELY)
    maskdat[!, rare] = disallowmissing(maskdat[!, rare])
    dat = leftjoin(dat, maskdat, on = vn.id => :COUNTYFP)
    dat[!, rare] = disallowmissing(dat[!, rare])
  
    # protest data
    protest_dat = load_object(datapath * "final_protest_data.jld2")
    select!(dat, Not([:protest, :prsize, :prcount]))
    dat = leftjoin(dat, protest_dat, on = [:fips, :date => :pr_event_date]);
    return dat
  end
  
  function indicatetreatments(dat)
    # treatments
  
    vn = VariableNames();
  
    # primaries already in the data
  
    # GA Special (5 Jan 21)
    treatstateondate!(
        dat;
        state_abbreviation = "GA",
        eventdate = Date("2021-01-05"),
        treatment_variable = :gaspecial
    )
      
    # Gubernatorial (2 Nov 21)
    treatstateondate!(
        dat;
        state_abbreviation = ["NJ", "VA"],
        eventdate = Date("2021-11-02"),
        treatment_variable = :gub,
    );
  
    # trump rallies
    dat, trump_stratassignments, trump_labels, trump_stratifier = countyspillover_assignment(
        dat, 3, :rallyday, vn.t, vn.id
    );
  
    # add variables to dataframe for combostrat
  
    # Exposure
    dat[!, :Exposure] .= 0;
  
    for r in eachrow(dat)
        r[:Exposure] = get(trump_stratassignments, (r[vn.t], r[vn.id]), -1)
        # -1 placeholder for observations that are not treated
    end
  
    trump_variables = [
        :rallydayunion,
        :rallyday0, :rallyday1, :rallyday2, :rallyday3
    ];
  
    # Trump Share binary
    dat[!, vn.tshigh] = dat[!, vn.ts16] .> 0.50;
  
    # BLM protests
    pr_vars = [:protest, :prsize, :prcount, :pr_blm, :pr_bluetrump, :pr_covid];
    for v in pr_vars
        c1 = ismissing.(dat[!, v])
        x = if eltype(skipmissing(dat[!, v])) == Bool
        false
        else 0
        end
        dat[c1, v] .= x
        dat[!, v] = disallowmissing(dat[!, v])
    end
  
    return dat, trump_stratassignments, trump_labels, trump_stratifier, pr_vars, trump_variables
end

function make_weekly(dat, pr_vars, trump_variables)
    vn = VariableNames();

    @transform!(
        dat,
        :week = Dates.Week.(:date),
        :year = Dates.Year.(:date),
    )

    dict = Dict{Tuple, Int}()
    for (i, r) in enumerate(eachrow(sort(unique(dat[!, [:year, :week]]))))
        dict[(r[:year], r[:week])] = i
    end

    dat[!, :running] .= 0;
    for r in eachrow(dat)
        r[:running] = dict[(r[:year], r[:week])]
    end

    wkd = @chain dat begin
        groupby([:running, :fips])
        combine(
            # outcome vars
            vn.cd => mean => vn.cd,
            vn.cc => mean => vn.cc,
            vn.cdr => mean => vn.cdr,
            vn.ccr => mean => vn.ccr,
            vn.deathoutcome => sum => vn.deathoutcome,
            vn.caseoutcome => sum => vn.caseoutcome,
            :deaths => sum => :deaths,
            :cases => sum => :cases,
            # mobility vars
            vn.rec => mean => vn.rec,
            vn.res => mean => vn.res,
            vn.groc => mean => vn.groc,
            # matching covariates
            vn.fc => maximum => vn.fc,
            vn.pd => maximum => vn.pd,
            vn.pbl => maximum => vn.pbl,
            vn.phi => maximum => vn.phi,
            vn.ts16 => maximum => vn.ts16,
            vn.mil => maximum => vn.mil,
            vn.p65 => maximum => vn.p65,
            # other variables
            :pop => maximum => :pop,
            vn.tout => maximum => vn.tout,
            vn.gaout => maximum => vn.gaout,
            vn.rare => maximum => vn.rare,
            # treatment variables
            :primary => sum => :primary,
            :gaspecial => sum => :gaspecial,
            :gub => sum => :gub,
            [prv => sum => prv for prv in trump_variables],
            :Exposure => maximum => :Exposure, 
            [prv => sum => prv for prv in pr_vars]
    
        )
        sort([:fips, :running])
    end
    return wkd
end
