# useful_functions.jl

function assigneventcolor(x)
    clrs = Makie.wong_colors()
    return if x == "Primary"
        clrs[1]
    elseif x == "GA Special"
        clrs[5]
    elseif x == "Rally"
        clrs[2]
    elseif x == "Gubernatorial"
        clrs[3]
    elseif x == "Protest"
        clrs[4]
    end
end

function sizeprocess(
    dat;
    njdat = "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/nj_turnout.csv",
    vadat = "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/va_turnout.csv",
    trumpdat = "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/trump_rallies.csv"

)

    trt = subset(
        dat,
        :political => ByRow(==(1)),
        [a => ByRow(==(0)) for a in [:rallyday1, :rallyday2, :rallyday3]],
        # :size => ByRow(>(0)),
        skipmissing = true
    )
        
    tn = names(trt)

    tr = Symbol("In-person Turnout Rate");
    gatr = Symbol("In-Person Turnout Rate (GA)");

    trt.prsize
    trt[!, tr] .* trt.pop
    trt[!, gatr] .* trt.pop

    trt[!, :size] = Vector{Union{Float64, Missing}}(missing, nrow(trt));
    # trt[!, :event] = Vector{Union{String, Missing}}(missing, nrow(trt));
    trt[!, :event] = Vector{String}(undef, nrow(trt));

    events = [:primary, :rallyday0, :gub, :gaspecial, :protest]

    eventnames = Dict(
        :primary => "Primary", :rallyday0 => "Rally",
        :gub => "Gubernatorial", :gaspecial => "GA Special",
        :protest => "Protest"
    );

    eventsize = Dict(
        :primary => tr,
        # :rallyday0 => "Rally",
        # :gub => "Gubernatorial",
        :gaspecial => gatr,
        :protest => :prsize
    )

    let
        for rw in eachrow(trt)
            for vbl in events
                if rw[vbl] == 1
                    rw[:event] = eventnames[vbl]
                    rw[:size] = if (vbl == :primary) | (vbl == :gaspecial)
                        round(rw[get(eventsize, vbl, missing)] * rw[:pop]; digits = 0)
                    else
                        if !ismissing(get(eventsize, vbl, missing))
                            rw[get(eventsize, vbl, missing)]
                        else missing
                        end
                    end
                end
            end
        end
    end

    ##


    ## add gub
    let
        nj = CSV.read(njdat, DataFrame)

        va = CSV.read(vadat, DataFrame)

        nj[!, :in_person] = nj.total_ballots - nj.ballots_by_mail;

        gubturnout = Dict(
            vcat(nj.fips, va.fips) .=> vcat(nj.in_person, va.election_day)
        )

        for (i, (fps, ev)) in enumerate(zip(trt.fips, trt.event))
            if ev == "Gubernatorial"
                trt.size[i] = get(gubturnout, fps, missing)
            end
        end
    end

    ## add trump
    let
        trmp = CSV.read(trumpdat, DataFrame)

        # trmp.date = Date.(trmp.date, "m/d/y") + Dates.Year(2000);
        trmp.size = sqrt.(trmp.crowd_lwr .* trmp.crowd_upr)

        dd = Dict{Tuple{Date, Int}, Union{Float64, Missing}}()
        for r in eachrow(trmp)
            dd[(r.date, r.fips)] = r.size
        end

        for (i, (dte, fps, ev)) in enumerate(zip(trt.date, trt.fips, trt.event))
            if ev == "Rally"
                trt.size[i] = get(dd, (dte, fps), missing)
            end
        end
    end


    ##

    evs = [
        :primary,
        :gaspecial,
        :gub,
        :protest,
        :rallyday0,
        :rallyday1,
        :rallyday2,
        :rallyday3
    ];

    dp = @subset(dat, :political .== 1);
    dps = select(dp, [:fips, :running, evs...])

    dps = stack(
        dps,
        evs, value_name=:held, variable_name=:event
    )

    @subset!(dps, :held .== 1)

    # (tt, tu)
    treatcats = Dict{Tuple{Int,Int},Int}();
    evs = string.(evs);
    for (tt, tu, ev) in zip(dps.running, dps.fips, dps.event)
        treatcats[(tt, tu)] = findfirst(ev .== evs)
    end


    trt[!, :eventcat] .= 0;
    for (j, (tt, tu)) in enumerate(zip(trt.running, trt.fips))
        trt[j, :eventcat] = treatcats[(tt, tu)]
    end

    trt.eventcat = categorical([evs[i] for i in trt.eventcat]);
    # trt.eventcat = categorical(trt.eventcat);

    trt = @subset(trt, :eventcat .∉ Ref(["rallyday1", "rallyday2", "rallyday3"]))
    trt = dropmissing(trt, :size)

    trt.size_adj = trt.size ./ 10000
    trt.size_rnd = Vector{Union{Int, Missing}}(undef, nrow(trt));

    for (i, x) in enumerate(trt.size)
        if !ismissing(x)
            trt.size_rnd[i] = round(x; digits = 0)
        end
    end
    trt.pop_adj = trt.pop ./ 10000

    return trt
end
