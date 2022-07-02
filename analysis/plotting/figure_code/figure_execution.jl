# figure preamble for main paper figures

using TSCSMethods, COVIDPoliticalEvents, DataFrames, DataFramesMeta, Parameters, Accessors, Dates
import Colors, ColorSchemes
using CairoMakie
using JLD2

savepth = "plotting/main_figures/";
format = ".svg";

ylabels = ("Death rate (per 10,000)", "Case rate (per 10,000)")
xlabel = "Day"

# outcome colors
outcomecolors = (TSCSMethods.gen_colors(3)[3], TSCSMethods.gen_colors(3)[2])

# offset for death and case outcomes, relative to day in the center
offsets = (0.15, 0.15)

# load functions
include("plot_utilities.jl")

include("primary_main.jl")
include("gub_main.jl")
include("blm_main.jl")
include("rally_figure.jl")
include("transmissibility_main.jl")
include("mobility_main.jl")
# include("long_fig.jl")

# execution
primary_main(xlabel, ylabels, outcomecolors, offsets, savepth, format);

gub_main(xlabel, ylabels, outcomecolors, offsets, savepth, format);

rally_main(xlabel, ylabels, outcomecolors, offsets, savepth, format);

blm_main(xlabel, ylabels, outcomecolors, offsets, savepth, format);

rt_main(;
    savepath = savepth,
    format = format,
    basepath = "Rt out/"
)

mobility_main(
    format = format,
    savepath = savepth
)

long_fig(xlabel, ylabels, outcomecolors, offsets, savepth, format)
