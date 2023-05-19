## si_figures.jl

ext = ".svg";
spth = "plotting/figures_supporting/";

using TSCSMethods, COVIDPoliticalEvents
import Colors, ColorSchemes
using CairoMakie

# pth = "plotting/figure_code/"
pth = ""

# include(pth * "plot_utilities.jl")
include(pth * "old/main_paper_plot_functions.jl")
include(pth * "si_paper_plot_functions.jl")
include(pth * "supplemental_plots.jl")
include(pth * "covariate_robustness_plots_functions.jl")

vn = VariableNames();

datapath = "data/data/";
datafile = "cvd_dat_use.jld2";

dat = load_object(datapath * datafile);
add_recent_events!(dat, vn.t, vn.id, :protest; recency = 30);

primpth = "primary out/";
gapth = "ga out/";
rlpth = "rally out/";
prpth = "protest out/";
copth = "combined out/grace combined out/";
postpth = "post out/"

# s1
let
    f = testingfig(
        deepcopy(dat);
        p1 = copth * "combined full_death_rte_excluded.jld2"
    )

    save(spth * "s1" * ext, f)
end

# s2, s3
let
    rp = rescheduled_pl(dat)
    save(spth * "s2-s3" * ext, rp)
end

# s6
let
    f = diagnostic(
        primpth * " primary full_case_rte_.jld2"
    )
    save(spth * "s6" * ext, f)
end

# s7, s8
let 
    f1, f2 = diagnostic(primpth * " primary full_case_rte_In-person Turnout Rate.jld2")

   save(spth * "s7" * ext, f1)
   save(spth * "s8" * ext, f2)
end

# s9
let 
    f = diagnostic(gapth * " ga nomob_case_rte_.jld2")
    save(spth * "s9" * ext, f)
end

# s10, s11
let
    f1, f2 = diagnostic(
        gapth * " ga nomob_case_rte_In-person Turnout Rate.jld2"
    )
    save(spth * "s10" * ext, f1)
    save(spth * "s11" * ext, f2)
end

let
    f = diagnostic("gub out/ gub out nomob_case_rte_.jld2")
    save(spth * "s12" * ext, f)
end

let
    f1, f2 = diagnostic(rlpth * " rally nomob_case_rte_exposure.jld2")
    save(spth * "s13" * ext, f1)
    save(spth * "s14" * ext, f2) 
end

let
    f = diagnostic(prpth * " protest nomob_case_rte_.jld2")
    save(spth * "s15" * ext, f) 
end

let
    f1, f2 = diagnostic(prpth * " protest nomob_case_rte_prsize.jld2")
    save(spth * "s16" * ext, f1)
    save(spth * "s17" * ext, f2)  
end

let
    f1, f2 = diagnostic(primpth * " primary full_death_rte_Pop. Density.jld2")
    save(spth * "s18" * ext, f1)
    save(spth * "s19" * ext, f2)  
end

let
    f1, f2 = diagnostic(primpth * " primary full_death_rte_date.jld2")
    save(spth * "s20" * ext, f1)
    save(spth * "s21" * ext, f2)
end

let
    f1, f2 = diagnostic(primpth * " primary nomob_death_rte_Region.jld2")
    save(spth * "s22" * ext, f1)
    save(spth * "s23" * ext, f2) 
end

let
    f1, f2 = diagnostic(primpth * " primary full_death_rte_Trump 2016 Vote Share.jld2")
    save(spth * "s24" * ext, f1)
    save(spth * "s25" * ext, f2)  
end

let
    f1, f2 = diagnostic(primpth * " primary full_death_rte_firstcase.jld2")
    save(spth * "s26" * ext, f1)
    save(spth * "s27" * ext, f2)  
end

let
    f1, f2 = diagnostic(primpth * " primary full_death_rte_Cum. Case Rate.jld2")
    save(spth * "s28" * ext, f1)
    save(spth * "s29" * ext, f2)  
end

let
    f1, f2 = diagnostic(primpth * " primary full_death_rte_Cum. Death Rate.jld2")
    save(spth * "s30" * ext, f1)
    save(spth * "s31" * ext, f2)
end

let
    pout = collect(skipmissing(dat[dat.primary .== 1, vn.tout]));
    gout = ga_turnout(dat; datapath = datapath)[!, vn.tout];
    njout, vaout = let
        x = gub_turnout(dat; njdatapath = datapath)
        nj = x[x.state .== "NJ", vn.tout]
        va = x[x.state .== "VA", vn.tout]
        nj, va
    end;

    f = turnoutplot(pout, gout, njout, vaout)
    save(spth * "s32" * ext, f)
end

let
    f1, f2 = diagnostic(gapth * " ga nomob_death_rte_In-person Turnout Rate.jld2")
    save(spth * "s33" * ext, f1)
    save(spth * "s34" * ext, f2)
end

let
    f1, f2 = diagnostic(gapth * " ga nomob_death_rte_Rarely Mask.jld2")
    save(spth * "s35" * ext, f1)
    save(spth * "s36" * ext, f2)
end

##

let
    f1, f2 = diagnostic(gapth * " ga nomob_death_rte_Trump 2016 Vote Share.jld2")
    save(spth * "s37" * ext, f1)
    save(spth * "s38" * ext, f2)
end

let
    fs = begin
        rx = rlpth * "rally nomob_death_rte_Exposure x Trump Share > 50%.jld2";
        X = load_object(rx);
    
        better_labels = Dict(
            1 => "Degree 1, Trump Share > 50%",
            2 => "Degree 3, Trump Share > 50%",
            3 => "Degree 2, Trump Share > 50%",
            4 => "Treatment, Trump Share > 50%",
            5 => "Degree 1, Trump Share < 50%",
            6 => "Degree 3, Trump Share < 50%",
            7 => "Degree 2, Trump Share < 50%",
            8 => "Treatment, Trump Share < 50%"
        )
    
        @reset X.model.labels = better_labels;
        @reset X.refinedmodel.labels = better_labels;
        @reset X.calmodel.labels = better_labels;
        @reset X.refcalmodel.labels = better_labels;
       
        str = X.model.stratifier != Symbol("") ? string(X.model.stratifier) : ""
        scenario = X.model.title * " " * str;
        
        rally_ts_x_exposure_fig(
            X, scenario;
            savepth = nothing,
            format = ""
        )

    end
    save(spth * "s39" * ext, fs[1])
    save(spth * "s40" * ext, fs[2])
    save(spth * "s41" * ext, fs[3])
    save(spth * "s42" * ext, fs[4])
end

let
    f1, f2 = diagnostic(prpth * " protest nomob_death_rte_prsize.jld2")
    save(spth * "s43" * ext, f1)
    save(spth * "s44" * ext, f2)
end

let
    pth = "plotting/supplementary_figures/rally_mob_pl.png"
    img = load(pth)
    f = Figure(resolution = (800, 1200))
    ax = Axis(f[1, 1], aspect = DataAspect())
    image!(ax, rotr90(img))
    hidedecorations!(ax)
    hidespines!(ax)
    save(spth * "s45" * ext, f)
end

# ERROR HERE?
let
    pth = "plotting/supplementary_figures/blm_mob_pl.png"
    img = load(pth)
    f = Figure(resolution = (800, 1200))
    ax = Axis(f[1, 1], aspect = DataAspect())
    image!(ax, rotr90(img))
    hidedecorations!(ax)
    hidespines!(ax)
    save(spth * "s46" * ext, f)
end

let
    pth = "plotting/supplementary_figures/primary_mob_pl.png"
    img = load(pth)
    f = Figure(resolution = (800, 1200))
    ax = Axis(f[1, 1], aspect = DataAspect())
    image!(ax, rotr90(img))
    hidedecorations!(ax)
    hidespines!(ax)
    save(spth * "s47" * ext, f)
end

let
    pth = "plotting/supplementary_figures/ga_mob_pl.png"
    img = load(pth)
    f = Figure(resolution = (800, 1200))
    ax = Axis(f[1, 1], aspect = DataAspect())
    image!(ax, rotr90(img))
    hidedecorations!(ax)
    hidespines!(ax)
    save(spth * "s48" * ext, f)
end

let 
    f = protest_size_hists(
        dat;
        w = 1200,
        h = 800
    )
    save(spth * "s49" * ext, f)
end

let
    f = Figure(resolution = (800, 1000))
    l1 = f[1, 1] = GridLayout()
    l2 = f[2, 1] = GridLayout()
    
    pth = "plotting/supplementary_figures/rallyday_shift_pl.png"
    img = load(pth)
    ax = Axis(l1[1, 1], aspect = DataAspect())
    image!(ax, rotr90(img))
    hidedecorations!(ax)
    hidespines!(ax)

    pth = "plotting/supplementary_figures/protest_shift_pl.png"
    img = load(pth)
    ax2 = Axis(l2[1, 1], aspect = DataAspect())
    image!(ax2, rotr90(img))
    hidedecorations!(ax2)
    hidespines!(ax2)

    for (label, layout) in zip(["a", "b"], [l1, l2])
        Label(layout[1, 1, TopLeft()], label,
            fontsize = 26,
            # font = noto_sans_bold,
            padding = (0, 5, 5, 0),
            halign = :right
        )
    end

    save(spth * "s51" * ext, f)
end

let
    pth = "plotting/supplementary_figures/exposure.png"
    img = load(pth)
    f = Figure()
    ax = Axis(f[1, 1], aspect = DataAspect())
    image!(ax, rotr90(img))
    hidedecorations!(ax)
    hidespines!(ax)
    save(spth * "s52" * ext, f)
end

let
    f1, f2 = diagnostic(primpth * " primary full_death_rte_In-person Turnout Rate.jld2")
    save(spth * "s54" * ext, f1)
    save(spth * "s55" * ext, f2)
end

let
    f1, f2 = diagnostic(prpth * " protest nomob_death_rte_prsize.jld2");
    save(spth * "s61" * ext, f1)
    save(spth * "s62" * ext, f2)
end

let
    f = diagnostic(
        copth * "combined full_deaths_excluded.jld2";
        simple = true
    )
    save(spth * "s63" * ext, f)
end

let
    f = diagnostic("Rt out/" * "primary full_Rt_.jld2")
    save(spth * "s64" * ext, f)
end

let
    f = diagnostic("Rt out/ga nomob_Rt_.jld2")
    save(spth * "s65" * ext, f)
end

let
    f = diagnostic("Rt out/gub nomob_Rt_.jld2")
    save(spth * "s66" * ext, f)
end

let
    f1, f2 = diagnostic("Rt out/rally nomob_Rt_exposure.jld2")
    save(spth * "s67" * ext, f1)
    save(spth * "s68" * ext, f2) 
end

let
    f = diagnostic("Rt out/" * "protest nomob_Rt_.jld2")
    save(spth * "s69" * ext, f) 
end

let
    f = Figure(resolution = (800, 1000))
    pth = "plotting/supplementary_figures/matchcount.eps"
    img = load(pth)
    ax = Axis(f[1, 1], aspect = DataAspect())
    image!(ax, rotr90(img))
    hidedecorations!(ax)
    hidespines!(ax)
    save(spth * "s70" * ext, f) 
end

let
    x = load_object("combined_power_sim/overall_death_rte_refcalmodel_nomob.jld2")
    f = covrob_plot(x)
    save(spth * "s73" * ext, f) 
end

let
    x = load_object("combined_power_sim/overall_case_rte_refcalmodel_nomob.jld2")
    f = covrob_plot(x)
    save(spth * "s74" * ext, f) 
end

let
    x = load_object("combined_power_sim/overall_death_rte_refcalmodel_epi.jld2")
    f = covrob_plot(x)
    save(spth * "s75" * ext, f) 
end

let
    x = load_object("combined_power_sim/overall_case_rte_refcalmodel_epi.jld2")
    f = covrob_plot(x)
    save(spth * "s76" * ext, f) 
end

let
    x = load_object("primary-elections/primary_death_rte_refcalmodel_nomob.jld2")
    f = covrob_plot(x)
    save(spth * "s77" * ext, f) 
end

let
    x = load_object("primary-elections/primary_case_rte_refcalmodel_nomob.jld2")
    f = covrob_plot(x)
    save(spth * "s78" * ext, f) 
end

let
    x = load_object("primary-elections/primary_death_rte_refcalmodel_epi.jld2")
    f = covrob_plot(x)
    save(spth * "s79" * ext, f) 
end

let
    x = load_object("primary-elections/primary_case_rte_refcalmodel_epi.jld2")
    f = covrob_plot(x)
    save(spth * "s80" * ext, f) 
end

let
    x = load_object("ga-election/ga_case_rte_refcalmodel_epi.jld2")
    f = covrob_plot(x)
    save(spth * "s81" * ext, f) 
end

let
    x = load_object("ga-election/ga_case_rte_refcalmodel_epi.jld2")
    f = covrob_plot(x)
    save(spth * "s82" * ext, f) 
end

let
    x = load_object("ga-election/ga_death_rte_refcalmodel_other.jld2")
    f = covrob_plot(x)
    save(spth * "s83" * ext, f) 
end

let
    x = load_object("gub-elections/gub_death_rte_refcalmodel_epi.jld2")
    f = covrob_plot(x)
    save(spth * "s84" * ext, f) 
end

let
    x = load_object("gub-elections/gub_case_rte_refcalmodel_epi.jld2")
    f = covrob_plot(x)
    save(spth * "s85" * ext, f) 
end

let
    x = load_object("trump-rallies/rally_death_rte_refcalmodel_epi.jld2")
    f = covrob_plot(x)
    save(spth * "s86" * ext, f) 
end

let
    x = load_object("trump-rallies/rally_case_rte_refcalmodel_epi.jld2")
    f = covrob_plot(x)
    save(spth * "s87" * ext, f) 
end

let
    x = load_object("blm-protests/blm_death_rte_refcalmodel_epi.jld2")
    f = covrob_plot(x)
    save(spth * "s88" * ext, f) 
end

let
    f = diagnostic("post out/blm epi_case_rte_.jld2")
    save(spth * "s89" * ext, f) 
end
