# threshold.jl

"""
    evthres!(dat, cc, control_thresh, treat_thresh, event_size::Symbol)

Mutate the treatment variable in the dataframe, subject to size thresholding. Events that are less than or equal to control_thres are treated as not-treated. Events in between the control threshold and the treatment threshold are removed from the data, over the outcome window (fmin to fmax), and are so not eligible to be control units.
"""
function thresholdevent2!(
  dat, cc, control_thresh, treat_thresh, event_size
)

  nix = Vector{Int64}(undef, 0);

  for r in eachrow(dat)
    if r[cc.treatment] == 1
      if r[event_size] <= control_thresh
        r[cc.treatment] = 0
        c1a = r[event_size] > control_thresh
        c1b = r[event_size] <= treat_thresh
        if c1a & c1b
          c2a = dat[!, cc.id] .== r[cc.id];
          c2b = dat[!, cc.t] .>= r[cc.t] + cc.fmin;
          c2c = dat[!, cc.t] .<= r[cc.t] + cc.fmax;
          anix = findall(c2a .& c2b .& c2c);
          append!(nix, anix);
        end
      end
    end
  end

  delete!(dat, sort(unique(nix)))
  return dat
end

#=
  for i in 1:length(trv)
    trvi = @views(trv[i]);
    idi = @views(idv[i]);
    ti = @views(rning[i]);
    svi = @views(sv[i]);
    if trvi == 1
      if svi <= ct
        trv[i] = 0
      elseif (svi > ct) & (svi <= ot)
        # remove data for that unit from treatment + fmin to treatment + fmax
        anix = findall(
          (idv .== idi) .& (rning .>= ti + fmin) .& (rning .<= (ti + fmax))
        )
        append!(nix, anix)
      end
    end
  end
  delete!(dat, sort(unique(nix)))
  return dat
end
=#
