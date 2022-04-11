# preamble.jl

using Random, TSCSMethods, COVIDPoliticalEvents
import JLD2:load_object

Random.seed!(2019)

savepath = "Rt out/";
datapath = "data/";
scenario = "rally "

refinementnum = 5; iters = 10000;

dat = load_object(datapath * "cvd_dat.jld2");

transpth = "covidestim_estimates_2022-03-05.csv"
transdatafile = datapath * transpth

dat = merge_Rt_data(dat, transdatafile)

vn = VariableNames();

obvars = [vn.pd, vn.ts16, :Exposure];

dat, stratassignments, labels, stratifier = countyspillover_assignment(
  dat, 3, :rallyday, vn.t, vn.id
);

tshigh = Symbol("Trump Share > 50%");

begin
  # add variables to dataframe for combostrat

  # Exposure
  dat[!, :Exposure] .= 0;

  for r in eachrow(dat)
    r[:Exposure] = get(stratassignments, (r[vn.t], r[vn.id]), -1)
      # -1 placeholder for observations that are not treated
  end

  # Trump Share binary
  dat[!, tshigh] = dat[!, vn.ts16] .> 0.50;
end

model = rtmodel(
  scenario * ARGS[1], :rallydayunion, Symbol(ARGS[1]), dat; iterations = iters
);

dat = dataprep(dat, model; convert_missing = false);
