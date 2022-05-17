# size_model.jl

include("preamble.jl");

@time match!(model, dat; treatcat = protest_treatmentcategories);

model = variable_filter(
  model, :prsize, dat;
  mn = 800
)

stratdict = Dict{Tuple{Int, Int}, Int}();
labels = Dict{Int, String}();
begin  

  obout = treatedinfo(model, [:prsize], dat);

  cutoffs = TSCSMethods.quantile(obout.prsize, [0, 0.3333, 0.66666, 1])
  strata = Vector{Int}(undef, length(model.observations));

  for (i, e) in enumerate(obout.prsize)
    strata[i] = if (e <= cutoffs[2])
      1
    elseif (e > cutoffs[2]) & (e <= cutoffs[3])
      2
    elseif e > cutoffs[3]
      3
    end
  end

  for (i, e) in enumerate(model.observations); stratdict[e] = strata[i] end

  cr = Int.(round.(cutoffs; digits = 0));

  labels[1] = string(cr[1]) * " to " * string(cr[2])
  labels[2] = string(cr[2]) * " to " * string(cr[3])
  labels[3] = string(cr[3]) * " to " * string(cr[4])
end;

@time balance!(model, dat);

model = stratify(customstrat, model, :prsize, stratdict);

for (k, v) in labels; model.labels[k] = v end

@time estimate!(model, dat);

@time refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);

@time calmodel, refcalmodel = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = Dict(vn.cdr => 0.25)
);

relabel!(calmodel, refcalmodel, dat)

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel];
  obscovars = obvars
)

