# make_main_figures.jl
# Generate the figures and model counts (for the captions) for the main paper.
# requires DataFrames version 1.3.4 (e.g., no later versions)
#    -> later versions will not be able to load .jld2 files

using TSCSMethods, COVIDPoliticalEvents
using DataFrames, DataFramesMeta, Parameters, Accessors, Dates
import Colors, ColorSchemes
using CairoMakie
using JLD2
import CairoMakie.RGB
import TSCSMethods.mean

savepth = "plotting/main_figures_minor/";
format = ".pdf"; # NHB wants standalone vector graphics files that are not SVG

ylabels = ("Death rate (per 10,000)", "Case rate (per 10,000)");
xlabel = "Day";

# load functions
include("plot_utilities.jl");

include("primary_main.jl");
include("gub_main.jl");
include("blm_main.jl");
include("rally_figure.jl");
include("transmissibility_main.jl");
include("mobility_main.jl");

# offset for death and case outcomes, relative to day in the center
offsets = (0.15, 0.15);

# outcome colors
outcomecolors = (gen_colors(3)[3], gen_colors(3)[2]);

# figure 1 created in photoshop/illustrator

# primary
figure3(xlabel, ylabels, outcomecolors, offsets, savepth, format);

# gubernatorial
figure4(xlabel, ylabels, outcomecolors, offsets, savepth, format);

# rally
figure5(xlabel, ylabels, outcomecolors, offsets, savepth, format);

# blm
figure6(xlabel, ylabels, outcomecolors, offsets, savepth, format);

# transmissibility
figure7(
    format = format,
    savepath = savepth
)

# mobility
figure8(;
    savepath = savepth,
    format = format,
)

# combined (FIGURE 2)
include("combined_plots.jl")
