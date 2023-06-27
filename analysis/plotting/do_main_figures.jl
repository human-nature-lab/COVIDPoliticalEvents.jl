# do_main_figures.jl
# Generate the figures and model counts (for the captions) for the main paper.
# requires DataFrames version 1.3.4 (e.g., no later versions)
#    -> later versions will not be able to load .jld2 files

using TSCSMethods
using COVIDPoliticalEventsPlots, DataFrames, DataFramesMeta
import COVIDPoliticalEventsPlots.gen_colors
using Random, CSV

savepth = "plotting/figures main/";
format = ".pdf"; # NHB wants standalone vector graphics files that are not SVG

ylabels = ("Death rate (per 10,000)", "Case rate (per 10,000)");
xlabel = "Day";

# offset for death and case outcomes, relative to day in the center
offsets = (0.15, 0.15);

# outcome colors
outcomecolors = (gen_colors(3)[3], gen_colors(3)[2]);

# figure 1 created in photoshop/illustrator
# then downsampled to a smaller size as a PDF file

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
let
    # combined analysis
    # main and SI plots for the combined model

    Random.seed!(2019)

    # locate the model files
    par = "combined out/grace combined out";
    drs = readdir(par);
    files = drs[contains.(drs, "excluded")]

    bals, matching = COVIDPoliticalEvents.getmatchbal(par, files);

    imp, oes = load_object("combined out/grace combined out/imputesets.jld2")
    for e in imp; rename!(e, e.outcome[1] => :observed) end
    imp = reduce(vcat, imp);
    select!(imp, Not(:stratum))

    # plots

    ## case-death rate plot
    dth = imp[imp.outcome .== :death_rte, :];
    cse = imp[imp.outcome .== :case_rte, :];

    odth = oes[oes.outcome .== :death_rte, :];
    ocse  = oes[oes.outcome .== :case_rte, :];

    dbal = bals[:death_rte];
    cbal = bals[:case_rte];

    ## execute plots
    f = COVIDPoliticalEvents.combined_case_death_plot(dth, cse, dbal, cbal)

    # plotpath = "combined plots/case_death_rte.svg";
    save(savepth * "Figure 2.pdf", f)

    # counts for Figure 2 caption

    combined_counts = let
        sort!(dth, :f)
        sort!(cse, :f)

        x1 = select(dth, [:f, :treated, :matches])
        rename!(x1, :treated => :treated_deaths, :matches => :matches_deaths)
        
        x2 = select(cse, [:treated, :matches])
        rename!(x2, :treated => :treated_cases, :matches => :matches_cases)

        hcat(x1, x2)
    end

    CSV.write(savepth * "Figure 2 counts.csv", combined_counts)

    vbles = [:treated_deaths, :matches_deaths, :treated_cases, :matches_cases];
    av_counts = @chain combined_counts begin
        combine([v => TSCSMethods.mean => v for v in vbles])
    end;

    CSV.write(savepth * "Figure 2 average counts.csv", av_counts)
end
