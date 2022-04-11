# COVIDPoliticalEvents.jl

## Introduction

Paper replication package and source code.
 
This repository contains three components
1. the paper replication package COVIDPoliticalEvents.jl
2. the code used to reconstruct the data used in the paper (see "data")
3. the code used to conduct the paper analyses (see "analysis")

This directory contains the Julia code used to replicate main and supplemental
findings in the paper "Local COVID-19 mortality did not increase after
large-scale political events in the USA in 2020 and 2021".

## Extracting and processing the data

### data files

Files that must be downloaded by the user are linked, files that are included in the package are noted, and appear in the "data" directory.

* JHU COVID ([deaths](https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv), [cases](https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv))
* [County level estimates](https://covidestim.s3.us-east-2.amazonaws.com/latest/estimates.csv) of R_t (from [covidestim](https://covidestim.org))
* US Census / ACS (via [tidycensus](https://walker-data.com/tidycensus/))
* BLS unemployment ("bls_unemployment.csv")
* [US Census region definitions](https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/delineation-files.html) ("census_delineation.csv")
* [US county adjacency information](https://www2.census.gov/geo/docs/reference/county_adjacency.txt)
* [US Urban-rural code classification](https://www.census.gov/programs-surveys/geography/guidance/geo-areas/urban-rural.html) ("ruralurbancodes2013.csv)
* [NYT county-level masking](https://raw.githubusercontent.com/nytimes/covid-19-data/master/mask-use/mask-use-by-county.csv)
* [ALCED protest events](https://acleddata.com/#/dashboard) ("final_protest_data.csv")
* Primary elections turnout ("2020_presidential_primary_turnout.csv")
* GA election turnout ("ga_election_results_clean.csv")
* [SafeGraph mobility](https://www.safegraph.com)

### data preparation

1. Download the covidestim county-level data, and the mobility data (see above)
2. Specify a census api key, obtainable through the US census website, in "preprocess.R", as an argument to ```preprocess()```.
3. If you possess the SafeGraph mobility data, you must specify it as "patpth" as an argument to ```process_csv()``` in "preprocess.jl". N.B., this data is not freely available, but is provided by SafeGraph, Inc.
4. Execute "covid_data_make.sh" to generate "cvd_dat.jld2", used for the main analyses.

## Replication of main results

# System Requirements

## Hardware Requirements

`TSCSMethods` works on a standard computer, with sufficient RAM and processing power to support the size of the dataset analyzed by the user. This will be a computer with at least 16 GB, and 4 cores. Analysis and testing was carried out on a system running MAC OS 17.0, with 64 Gb RAM, and an intel i9 processor @ 2.30Ghz.

## Software Requirements

While analysis was executed on a MAC OSX system, all of the underlying dependencies are compatible with Windows, Mac, and Linux systems. This package has been tested on Julia 1.7.1. Data was constructed using R 4.1.

**R system information and platform details**
```
               _                           
platform       x86_64-apple-darwin17.0     
arch           x86_64                      
os             darwin17.0                  
system         x86_64, darwin17.0          
status                                     
major          4                           
minor          1.0                         
year           2021                        
month          05                          
day            18                          
svn rev        80317                       
language       R                           
version.string R version 4.1.0 (2021-05-18)
nickname       Camp Pontanezen
```

**Julia system information and platform details**

```
Julia Version 1.7.1
Commit ac5cc99908 (2021-12-22 19:35 UTC)
Platform Info:
  OS: macOS (x86_64-apple-darwin21.1.0)
  CPU: Intel(R) Core(TM) i9-9880H CPU @ 2.30GHz
  WORD_SIZE: 64
  LIBM: libopenlibm
  LLVM: libLLVM-13.0.0 (ORCJIT, skylake)
Environment:
  JULIA_EDITOR = code
  JULIA_NUM_THREADS = 16
```

# Installation Guide

Julia may be installed on Mac OSX using [homebrew](https://brew.sh) by executing:

```shell
brew install julia
```

Otherwise, consult the [Julia Language download page](https://julialang.org/downloads/) for installation on your system.

### Dependencies

### programming languages

* [R](https://www.r-project.org) version 4.1.0 (2021-05-18)
  * Packages: dplyr, magrittr, tibble, lubridate, ggplot2 (each available through the [CRAN repository](https://cran.r-project.org))
* [Julia](https://julialang.org) version 1.7.1 (2021-12-22)
  * Packages: TSCSMethods, COVIDPoliticalEvents, Random, DataFrames, Dates, CSV, JLD2 (all except the first two available through Julia's package manager)

All packages are available through the standard repositories, except [TSCSMethods](https://github.com/human-nature-lab/TSCSMethods.jl) and [COVIDPoliticalEvents](https://github.com/human-nature-lab/COVIDPoliticalEvents.jl).

### package installation

From within a `julia` session, type:

```{julia}
import Pkg; Pkg.add("https://github.com/human-nature-lab/TSCSMethods.jl")
```

The package should take approximately 1 minute to install. 

### execution

After installation of the software dependencies, a given model should take anywhere from 10-60 minutes to execute, depending on workstation specifications.

The models for a given scenario may be executed together, by executing the "run" file, e.g., "run_blm.jl", or separately, by executing the file for a specific model (e.g., "base_model.jl"). Each scenario is housed in a specific subdirectory.

The output for each model is saved as a [Julia Data Format](https://juliaio.github.io/JLD2.jl/dev/) file (".jld2"), and the file structure itself
depends on the above packages.

Executing a "run" file creates output files for each model in the "out",
subdirectories for each scenario.

You may inspect model output according to the following:

```{julia}
using TSCSMethods, JLD2

output = load_object("ga full_death_rte_.jld2")
```

the output object contains the following fields:
* model
* refinedmodel
* calmodel
* refcalmodel
* matchinfo
* obsinfo

For example, access the results of the refined caliper model as:

```{julia}
output.refcalmodel.results
```

Which yields the ATT estimates, confidence intervals, and the
number of treated units from a given model.

The latter two fields contain information about the matched units and
the treated observation units.

For a simple program example, to estimate the ATTs for a specific event, in
a simple context, see "ga-election/base_model.jl" which runs through
estimation of the overall ATTs for the Georgia special election, each scenario
has the same overall structure:

1. Load the packages, data, and set the parameters for estimation:

```{julia}
include("preamble.jl");
```

2. Perform matching:

```{julia}
match!(model, dat);
```

3. Perform balancing:

```{julia}
balance!(model, dat);
```

4. Estimate the ATTs for the non-refined, non-caliper model:

```{julia}
estimate!(model, dat);
```

5. Refine the model to the `refinementnum` (e.g., 5) best matches, and estimate:

```{julia}
refinedmodel = refine(
  model, dat;
  refinementnum = refinementnum, dobalance = true, doestimate = true
);
```

6. Specify an initial caliper:

```{julia}
ibs = Dict(
  vn.cdr => 0.25 #, vn.fc => 0.25,
  # vn.pbl => 0.25, vn.ts16 => 0.25
)
```

7. Successively apply calipers to get a refined caliper model with sufficient balance:

```
calmodel, refcalmodel, overall = autobalance(
  model, dat;
  calmin = 0.08, step = 0.05,
  initial_bals = ibs,
  dooverall = true
);

8. Save a record of the model:

```{julia}
recordset = makerecords(
  dat, savepath, [model, refinedmodel, calmodel, refcalmodel]
)

TSCSMethods.save_object(savepath * "overall_estimate.jld2", overall)
```
