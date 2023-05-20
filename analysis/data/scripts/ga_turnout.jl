# ga_turnout.jl

"""
get and handle the turnout data for the GA special election
"""
function ga_turnout(dat; datapath = "covid-19-data/data/")

  pdict = Dict(dat.fips .=> dat.pop);

  vn = VariableNames()

  ge = CSV.read(
      datapath * "ga_election_results_clean.csv", 
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

  ge[!, :pop] .= [get(pdict, e, 0) for e in ge.fips]

  ge.fips = convert(Vector{Int64}, ge.fips);

  select!(ge, Not(:County))
  ge[!, vn.tout] = ge.day_of .* inv.(ge.pop);
  
  return ge
end;

# VA turnout

using DataFrames, DataFramesMeta, CSV, HTTP

function gub_turnout(dat; njdatapath = "covid-19-data/data/")

  urlb = HTTP.get(
    "https://apps.elections.virginia.gov/SBE_CSV/ELECTIONS/ELECTIONTURNOUT/Turnout-2021%20November%20General%20.csv"
  ).body;

  vadat = CSV.read(urlb, DataFrame);

  vadat = @chain vadat begin
    groupby(:locality)
    combine(:in_person_ballots => sum => :in_person_ballots)
    @transform(:locality = lowercase.(:locality))
  end
  rename!(vadat, :in_person_ballots => :va_in_person)

  njdat = CSV.read(njdatapath * "nj_turnout.csv", DataFrame);

  njdat = @transform(
    @transform(
      njdat,
      :County = lowercase.(:County),
      :in_person = :total_ballots - :ballots_by_mail
    ),
    :County = :County .* " county"
  );

  select!(njdat, :County, :in_person)
  rename!(njdat, :in_person => :nj_in_person)

  fpsdat = HTTP.get(
    "https://raw.githubusercontent.com/kjhealy/fips-codes/master/state_and_county_fips_master.csv"
  ).body;

  fpsdat = CSV.read(fpsdat, DataFrame);
  njfpsdat = @chain fpsdat begin
    @subset(:state .== "NJ")
    @transform(:name = lowercase.(:name))
  end

  vafpsdat = @chain fpsdat begin
    @subset(:state .== "VA")
    @transform(:name = lowercase.(:name))
  end

  njdat = leftjoin(njdat, njfpsdat, on = :County => :name)
  njdat = disallowmissing(njdat);

  vadat = leftjoin(vadat, vafpsdat, on = :locality => :name)

  vadat.fips[vadat.locality .== "king & queen county"] = [51097]
  vadat.state[vadat.locality .== "king & queen county"] = ["VA"]

  vadat = disallowmissing(vadat);

  rename!(njdat, :nj_in_person => :in_person)
  rename!(vadat, :va_in_person => :in_person)
  
  select!(njdat, :fips, :in_person, :state)
  select!(vadat, :fips, :in_person, :state)
  
  gubturnout = vcat(njdat, vadat)

  popd = Dict(dat.fips .=> dat.pop);
  gubturnout[!, :pop] .= [get(popd, e, 0) for e in gubturnout.fips]

  gubturnout[!, Symbol("In-person Turnout Rate")] = gubturnout.in_person .* inv.(gubturnout.pop)

  return gubturnout
end
