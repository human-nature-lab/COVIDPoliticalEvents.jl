# data.jl

"""
    deleteincomplete!(dat, t, id, treatment, F, cutoff)

Remove observations for a unit with incomplete match periods (specified by cutoff, days before treatment, furthest day back to require that is included) in the outcome window for that treatment event. Mutates the data.
"""
function deleteincomplete!(
  dat,
  t, id, treatment, F,
  cutoff
)
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
    gaprep!(dat; gaspecialdate = Date("2021-01-05"))

Create the treatment variable for the GA Special Election.
"""
function treatga!(
  dat;
  state_abbreviation = "GA",
  gaspecialdate = Date("2021-01-05"),
  treatment_variable = :gaspecial,
  date_column = :date
)

  dat[!, treatment_variable] .= 0;
  c1 = (dat[!, VariableNames().abbr] .== state_abbreviation) .& (dat[!, date_column] .== gaspecialdate);
  dat[c1, treatment_variable] .= 1;

  return dat
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
  # @reset model.results = tscsmethods.DataFrame();

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
  3. Shift (lead) the cumulative death rate and cumulative case rate variables by the lower 5th percentile day of their infection-to-death distributions. This regards covariate matching.
"""
function dataprep(
  dat, model;
  t_start = nothing, t_end = nothing,
  remove_incomplete = false,
  incomplete_cutoff = nothing,
  convert_missing = true,
)

  leadsize = 10;

  vn = VariableNames()
  @unpack t, id, treatment, F, L = model;
  
  # push the cumulative death rate back 10 days
  # by the infection-death distribution
  # NaN doesn't matter since we drop the range anyway
  dat = @chain dat begin
    sort([id, t])
    groupby(id)
    @transform($(vn.cdr) = lead($(vn.cdr), leadsize; default = NaN))
  end
  
  if isnothing(t_start)
    ttmin = minimum(dat[dat[!, treatment] .== 1, t]);
    c1 = dat[!, t] .>= ttmin + L[begin];
  else
    c1 = dat[!, t] .>= t_start
  end
  
  if isnothing(t_end)
    ttmax = maximum(dat[dat[!, treatment] .== 1, t]);
    c2 = dat[!, t] .<= ttmax + F[end] + leadsize;
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
  3. Shift (lead) the cumulative death rate and cumulative case rate variables by the lower 5th percentile day of their infection-to-death distributions. This regards covariate matching.
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

  # push the cumulative death rate back 10 days
  # by the infection-death distribution
  # NaN doesn't matter since we drop the range anyway
  dat = @chain dat begin
    sort([id, t])
    groupby(id)
    @transform($(cdr) = lead($(cdr), 10; default = NaN))
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
