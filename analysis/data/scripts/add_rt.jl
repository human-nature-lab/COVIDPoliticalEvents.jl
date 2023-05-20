using Random, TSCSMethods, COVIDPoliticalEvents, Dates, DataFrames
import JLD2:load_object,save_object
import CSV

cvdpth = "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/cvd_dat_use.jld2";

cvd = load_object(cvdpth)

rt = CSV.read(
    "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/covidestim_estimates_2022-03-05.csv",
    DataFrame
)

select!(rt, [:fips, :date, :Rt]);
cvd[1] = leftjoin(cvd[1], rt, on = [:fips, :date]);

save_object(cvdpth, cvd)