# COVID Political Events Analysis

2023-06-03

## Dependencies

Depends on the COVIDPoliticalEvents.jl package.

## Figures

Execute

- "do_main_figures.jl"
- "do_extended_figures.jl"
- "do_supplementary_figures.jl"

## Main text models

Overall

- "combined out/grace combined out"
  - "combined full_case_rte_excluded.jld2"
  - "combined full_cases_excluded.jld2"
  - "combined full_death_rte_excluded.jld2"
  - "combined full_deaths_excluded.jld2"
  - "imputesets.jld2"

Primary

- "primary out/"
  - "primary out/ primary full_death_rte_.jld2"
  - " primary full_case_rte_.jld2"
  - " primary full_death_rte_In-person Turnout Rate.jld2"
  - " primary full_case_rte_In-person Turnout Rate.jld2"

GA

- "ga out/"
  - "ga out/ ga nomob_death_rte_.jld2"
  - "ga out/ ga nomob_case_rte_.jld2"
  
Gubernatorial
  
  - " gub out nomob_death_rte_.jld2"
  - " gub out nomob_case_rte_.jld2"

Rally

- "rally out/ rally nomob_death_rte_exposure.jld2"
- "rally out/ rally nomob_case_rte_exposure.jld2"

BLM

- "protest out/"
  - "protest out/ protest nomob_death_rte_.jld2"
  - "protest out/ protest nomob_death_rte_prsize.jld2"
  - "protest out/ protest nomob_case_rte_.jld2"
  - "protest out/ protest nomob_case_rte_prsize.jld2"

Transmissibility

- "Rt out/primary full_Rt_.jld2"
- "Rt out/ga epi_Rt_.jld2"
- "Rt out/gub nomob_Rt_.jld2"
- "Rt out/rally nomob_Rt_exposure.jld2"
- "Rt out/protest nomob_Rt_.jld2"

Mobility

- "mobility out/mobility primary full_multiple_Full-Service Restaurants_.jld2"
- "mobility out/mobility ga full_multiple_Full-Service Restaurants_.jld2"
- "mobility out/mobility gub full_multiple_Full-Service Restaurants_.jld2"
- "mobility out/mobility rally full_multiple_Full-Service Restaurants_exposure.jld2"
- "mobility out/mobility protest full_multiple_Full-Service Restaurants_.jld2"
