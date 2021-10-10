# data.jl

"""
    deleteincomplete!(dat, cc::AbstractCICModel, cutoff)

Remove observations for a unit with incomplete match periods (specified by cutoff, days before treatment, furthest day back to require that is included) in the outcome window for that treatment event. Mutates the data.
"""
function deleteincomplete!(dat, cc::AbstractCICModel, cutoff)
  # if there is no date at least to cutoff, remove data for unit up to fmax
  tobs = unique(dat[dat[!, cc.treatment] .== 1, [cc.id, cc.t]]);

  removal_indices = Int64[];
  
  for r in eachrow(tobs)
    treat_cutoff = r[cc.t] - cutoff;
    c1 = dat[!, cc.id] .== r[cc.id];
    c2 = dat[!, cc.t] .>= treat_cutoff;
    c3 = dat[!, cc.t] .<= (r[cc.t] + cc.fmax);

    tf = @views dat[c1 .& c2 .& c3, cc.t];
    keep = minimum(tf) <= treat_cutoff;
    if !keep
      c2b = dat[!, cc.t] .>= (r[cc.t] + cc.fmin); # remove during outcome window
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
function treatga!(dat; gaspecialdate = Date("2021-01-05"))

  dat[!, :gaspec] .= 0;
  c1 = (dat[!, abbr] .== "GA") .& (dat.date .== gaspecialdate);
  dat.gaspec[c1] .= 1;

  return dat
end

"""
    dataprep!(
      dat, treatment, t, fmax;
      t_start = nothing, t_end = nothing;
      remove_incomplete = false
    )

Prepare the data for analysis:
  1. Limit date range to first day of matching period for first treatment, up to last outcome window day for last treatment.
  2. Optionally, remove observations over the outcome window for a treatment event where the corresponding matching period (or portion thereof) is not present in the data. The portion is specified by incomplete_cutoff, the first day before a treatment event that must be included.
"""
function dataprep(
  dat, cc;
  t_start = nothing, t_end = nothing,
  remove_incomplete = false,
  incomplete_cutoff = nothing
)

  if isnothing(t_start)
    ttmin = minimum(dat[dat[!, cc.treatment] .== 1, cc.t]);
    c1 = dat[!, cc.t] .>= ttmin + cc.mmin;
  else
    c1 = dat[!, cc.t] .>= t_start
  end
  
  if isnothing(t_end)
    ttmax = maximum(dat[dat[!, cc.treatment] .== 1, cc.t]);
    c2 = dat[!, cc.t] .<= ttmax + cc.fmax;
  else
    c2 = dat[!, cc.t] .<= t_end;
  end


  dat = dat[c1 .& c2, :];

  if remove_incomplete
    deleteincomplete!(dat, cc, incomplete_cutoff)
  end

  sort!(dat, [cc.id, cc.t])

  return dat
end
