# threshold.jl

"""
    evthres!(
      dat, treatment, t, id, fmin, fmax,
      control_thresh, treat_thresh, event_size::Symbol
    )

Mutate the treatment variable in the dataframe, subject to size thresholding. Events that are less than or equal to control_thres are treated as not-treated. Events in between the control threshold and the treatment threshold are removed from the data, over the outcome window (fmin to fmax), and are so not eligible to be control units.
"""
function thresholdevent!(
  dat,
  treatment, t, id, fmin, fmax,
  control_thresh, treat_thresh, event_size
)

  nix = Vector{Int64}(undef, 0);

  for r in eachrow(dat)
    if r[treatment] == 1
      if r[event_size] <= control_thresh
        r[treatment] = 0
        c1a = r[event_size] > control_thresh
        c1b = r[event_size] <= treat_thresh
        if c1a & c1b
          c2a = dat[!, id] .== r[id];
          c2b = dat[!, t] .>= r[t] + fmin;
          c2c = dat[!, t] .<= r[t] + fmax;
          anix = findall(c2a .& c2b .& c2c);
          append!(nix, anix);
        end
      end
    end
  end

  delete!(dat, sort(unique(nix)))
  return dat
end
