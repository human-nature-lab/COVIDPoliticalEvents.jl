# base_model.jl

push!(ARGS, "full")

include("preamble.jl");

@time match!(model, dat);

model = primary_filter(model;  mintime = 10);

@time balance!(model, dat);

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


# colinc = [occursin(string(vn.res), nm) for nm in names(refcalmodel.results)];
# colinc[1] = true;
# refcalmodel.results[!, colinc];

recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)
