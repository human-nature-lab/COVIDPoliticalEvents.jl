# multiple outcome mobility plots

using TSCSMethods, COVIDPoliticalEvents, DataFrames, DataFramesMeta, Parameters, Accessors, Dates
import Colors, ColorSchemes
using CairoMakie
using JLD2

include("multiple outcome plotting functions.jl")

xlabel = "Day"; ylabel = "Adjusted total visits";
savepath = fpth = "mobility out/";
format = ".svg";;


mobility_main(
    fpth * "mobility primary full_multiple_Full-Service Restaurants_.jld2",
    xlabel, ylabel;
    savepath = savepath, format = format, scenario = "primary mobility"
);

mobility_main(
    fpth * "mobility ga full_multiple_Full-Service Restaurants_.jld2",
    xlabel, ylabel;
    savepath = savepath, format = format, scenario = "ga mobility"
);

mobility_main(
    fpth * "mobility protest full_multiple_Full-Service Restaurants_.jld2",
    xlabel, ylabel;
    savepath = savepath, format = format, scenario = "protest mobility"
);

mobility_main(
    fpth * "mobility gub full_multiple_Full-Service Restaurants_.jld2",
    xlabel, ylabel;
    savepath = savepath, format = format, scenario = "gub mobility"
);

f = mobility_stratified(
    fpth * "mobility rally full_multiple_Full-Service Restaurants_exposure.jld2",
    xlabel, ylabel;
    savepath = savepath, format = format, scenario = "rally mobility"
);
