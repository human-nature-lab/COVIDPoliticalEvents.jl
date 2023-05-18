# extended data figures

using TSCSMethods, COVIDPoliticalEvents

vn = COVIDPoliticalEvents.VariableNames();

datapath = "/Users/emf/Library/Mobile Documents/com~apple~CloudDocs/Yale/yale research/COVID19/covid-19-data/data/";

datafile = "cvd_dat_use.jld2";
dat = load_object(datapath * datafile);
add_recent_events!(dat, vn.t, vn.id, :protest; recency = 30);

bpth = "";
primpth = bpth * "primary out/";
gapth = bpth * "ga out/";
rlpth = bpth * "rally out/";
prpth = bpth * "protest out/";
copth = bpth * "combined out/grace combined out/";

expth = "plotting/figures extended/"

## ED Fig. 1

#| label: fig-72
#| fig-scap: Pre-outcome-window ATTs
#| fig-cap: Pre-outcome-window ATTs. ATTs for the death and case rates, from 30 days before treatment up to the 9 days after treatment. The light green cell is the day of treatment, and the dark grey cell is the reference day for the ATT calculation (see Methods). In each panel, the error bars indicate the 95% CIs. The panels present the “average treatment effect on the treated” (ATT) estimates for the (A) omnibus analysis, (B) the primary elections, (C) GA special election, (D) NJ & VA gubernatorial elections, (E) Donald Trump’s political rallies, and (F) the BLM protests. In each case, we observe results that are similar to those for the corresponding main analysis; that is, generally non-significant results, which is expected for the period prior to treatment.

let
    pt = pretrendfig();

    save(expth * "E Fig. 1.eps", pt)
end

## ED Fig. 2

#| label: fig-4
#| fig-scap: Omnibus estimates for the effect of political events on the death rate
#| fig-cap: Omnibus estimates for the effect of political events on the death rate. (a) Overall ATT estimates and covariate balance before matching refinement. (The ATTs represent the average difference in the change in death rates, from the day before treatment to 10 to 40 days after an election. The pre-refinement covariate balance for each matching covariate. All covariates are measurements at the county level. The balance score is the average standardized mean difference between the treated and control units, over a matching period from 30 days before to 1 day before treatment. There are 2135 treated units present. (b) Overall ATT estimates and covariate balance after matching refinement, to no more than the five best matches to each treated county. (c) Overall ATT estimates and covariate balance before matching refinement and after the application of a caliper. (d) Overall ATT estimates and covariate balance after the application of a caliper, and after matching refinement, the observed balance scores are, on average over the matching window, within the threshold of 0.1, indicating sufficient similarity between the treated and matched counties. On average, for estimates over the outcome window, 1449.4 treated units remain, with 6084.5 matches.

let
    f = diagnostic(
        copth * "combined full_death_rte_excluded.jld2";
        simple = true
    )
    save(expth * "E Fig. 2.eps", f)
end

## ED Fig. 3

#| label: fig-5
#| #| fig-scap: Omnibus estimates for the effect of political events on the case rate
#| fig-cap: Omnibus estimates for the effect of political events on the case rate. (a) Overall ATT estimates and covariate balance before matching refinement. (The ATTs represent the average difference in the change in case rates, from the day before treatment to 10 to 40 days after an election. The pre-refinement covariate balance for each matching covariate. All covariates are measurements at the county level. The balance score is the average standardized mean difference between the treated and control units, over a matching period from 30 days before to 1 day before treatment. There are 2135 treated units present. (b) Overall ATT estimates and covariate balance after matching refinement, to no more than the five best matches to each treated county. (c) Overall ATT estimates and covariate balance before matching refinement and after the application of a caliper. (d) Overall ATT estimates and covariate balance after the application of a caliper, and after matching refinement, the observed balance scores are, on average over the matching window, within the threshold of 0.1, indicating sufficient similarity between the treated and matched counties. On average, for estimates over the outcome window, 1473.5 treated units remain, with 6305.4 matches.

let
    f = diagnostic(
        copth * "combined full_case_rte_excluded.jld2";
        simple = true
    )

    save(expth * "E Fig. 3.eps", f)
end

## ED Fig. 4

#| label: fig-53
#| fig-scap: Overall estimates for the primary elections
#| fig-cap: Overall estimates for the primary elections. In each panel, the error bars indicate the 95% CIs. (A) Overall ATT estimates and covariate balance before matching refinement. (The ATTs represent the average difference in the change in death rates, from the day before treatment to 10 to 40 days after an election. The pre-refinement covariate balance for each matching covariate. All covariates are measurements at the county level. The balance score is the average standardized mean difference between the treated and control units, over a matching period from 30 days before to 1 day before treatment. There are 1173 treated units present. (B) Overall ATT estimates and covariate balance after matching refinement, to no more than the five best matches to each treated county. (C) Overall ATT estimates and covariate balance before matching refinement and after the application of a caliper. (D) Overall ATT estimates and covariate balance after the application of a caliper, and after matching refinement, the observed balance scores are, on average over the matching window, within the threshold of 0.1, indicating sufficient similarity between the treated and matched counties. On average, for estimates over the outcome window, 961.2 treated units remain, with 4283.8 matched units.

let
    f = diagnostic(prpth * " protest nomob_death_rte_.jld2")
    save(expth * "E Fig. 4.eps", f)
end

## ED Fig. 5

#| label: fig-56
#| fig-scap: Overall estimates for the GA elections
#| fig-cap: Overall estimates for the GA elections. In each panel, the error bars indicate the 95% CIs. (a) Overall ATT estimates and covariate balance before matching refinement. (The ATTs represent the average difference in the change in death rates, from the day before treatment to 10 to 40 days after an election. The pre-refinement covariate balance for each matching covariate. All covariates are measurements at the county level. The balance score is the average standardized mean difference between the treated and control units, over a matching period from 30 days before to 1 day before treatment. There are 159 treated units present. (b) Overall ATT estimates and covariate balance after matching refinement, to no more than the five best matches to each treated county. (c) Overall ATT estimates and covariate balance before matching refinement and after the application of a caliper. (d) Overall ATT estimates and covariate balance after the application of a caliper, and after matching refinement, the observed balance scores are, on average over the matching window, within the threshold of 0.1, indicating sufficient similarity between the treated and matched counties. On average, for estimates over the outcome window, 137 treated units remain, with 566 matched units.

let
    f = diagnostic(gapth * " ga nomob_death_rte_.jld2")
    save(expth * "E Fig. 5.eps", f)
end

## ED Fig. 6

# fig-s57
# Overall estimates for the NJ and VA gubernatorial elections. In each panel, the error bars indicate the 95% CIs. (a) Overall ATT estimates and covariate balance before matching refinement. (The ATTs represent the average difference in the change in death rates, from the day before treatment to 10 to 40 days after an election. The pre-refinement covariate balance for each matching covariate. All covariates are measurements at the county level. The balance score is the average standardized mean difference between the treated and control units, over a matching period from 30 days before to 1 day before treatment. There are 154 treated units present. (b) Overall ATT estimates and covariate balance after matching refinement, to no more than the five best matches to each treated county. (c) Overall ATT estimates and covariate balance before matching refinement and after the application of a caliper. (d) Overall ATT estimates and covariate balance after the application of a caliper, and after matching refinement, the observed balance scores are, on average over the matching window, within the threshold of 0.1, indicating sufficient similarity between the treated and matched counties. On average, for estimates over the outcome window, 141 treated units remain, with 649 matched units.

let
    f = diagnostic("gub out/ gub out nomob_death_rte_.jld2")
    save(expth * "E Fig. 6.eps", f)
end

## ED Figs. 7, 8

#| include: false

let
    f1, f2 = diagnostic(rlpth * " rally nomob_death_rte_exposure.jld2")

#| label: fig-58
#| fig-scap: Estimates for Donald Trump’s rallies, stratified by exposure (without caliper)
#| fig-cap: Estimates for Donald Trump’s rallies, stratified by exposure (without caliper). In both panels, the error bars indicate the 95% CIs. (a) Overall ATT estimates and covariate balance before matching refinement, for each stratum. (The ATTs represent the average difference in the change in death rates, from the day before treatment to 10 to 40 days after an election. The pre-refinement covariate balance for each matching covariate. All covariates are measurements at the county level. The balance score is the average standardized mean difference between the treated and control units, over a matching period from 30 days before to 1 day before treatment. The number of treated units in each stratum are on average, over the outcome window. For Treatment, there are 67 treated units; for Degree 1, there are 397 treated units; for Degree 2, there are 788 treated units; for Degree 3, there are 1156 treated units. (b) Overall ATT estimates and covariate balance after matching refinement, to no more than the five best matches to each treated county, for each stratum.

    f1
    save(expth * "E Fig. 7.eps", f1)

#| label: fig-59
#| fig-scap: Estimates for Donald Trump’s rallies, stratified by exposure (with caliper)
#| fig-cap: Estimates for Donald Trump’s rallies, stratified by exposure (with caliper). In both panels, the error bars indicate the 95% CIs. (a) Overall ATT estimates and covariate balance before matching refinement, for each stratum. (The ATTs represent the average difference in the change in death rates, from the day before treatment to 10 to 40 days after an election. The pre-refinement covariate balance for each matching covariate. All covariates are measurements at the county level. The balance score is the average standardized mean difference between the treated and control units, over a matching period from 30 days before to 1 day before treatment. The number of treated units in each stratum are on average, over the outcome window. For Treatment, 58.2 treated units remain; for Degree 1, 363.4 treated units remain; for Degree 2, 713.3 treated units remain; for Degree 3, 1055.1 treated units remain. Respectively, with 251.8, 1679, 3290.9, 4280.4  matches. (b) Overall ATT estimates and covariate balance after matching refinement, to no more than the five best matches to each treated county, for each stratum.

    f2
    save(expth * "E Fig. 8.eps", f2)

end

## ED Fig. 9

#| label: fig-60
#| fig-scap: Overall estimates for the BLM protests
#| fig-cap: Overall estimates for the BLM protests. In each panel, the error bars indicate the 95% CIs. (a) Overall ATT estimates and covariate balance before matching refinement. (The ATTs represent the average difference in the change in death rates, from the day before treatment to 10 to 40 days after an event. The pre-refinement covariate balance for each matching covariate. All covariates are measurements at the county level. The balance score is the average standardized mean difference between the treated and control units, over a matching period from 30 days before to 1 day before treatment. On average, for estimates over the outcome window, 658 treated units are present. (b) Overall ATT estimates and covariate balance after matching refinement, to no more than the five best matches to each treated county. (c) Overall ATT estimates and covariate balance before matching refinement and after the application of a caliper. (d) Overall ATT estimates and covariate balance after the application of a caliper, and after matching refinement, the observed balance scores are, on average over the matching window, within the threshold of 0.1, indicating sufficient similarity between the treated and matched counties. On average, for estimates over the outcome window, 450.5 treated units remain, with 1901.7 matched units.

let
    f = diagnostic(prpth * " protest nomob_death_rte_.jld2")
    save(expth * "E Fig. 9.eps", f)
end

## ED Fig. 10

#| label: fig-71
#| fig-scap: Political Event sizes
#| fig-cap: Political Event sizes. (a) Overall distribution of event sizes in the data, across event type. Large frequencies for specific values reflect the thresholding procedure used to estimate crowd sizes from different reports (see Methods). (b) Overall distribution of event sizes in the data, across each event type, represented as the percentage of the county population in which the event takes place. (c) Event sizes over the roughly two-year period that constitutes our study horizon, colored by event type. Event sizes are plotted on the natural log scale, labelled on the original scale (persons at event).

# see treatment_plot.jl
