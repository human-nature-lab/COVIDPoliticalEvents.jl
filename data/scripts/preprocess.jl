# data preprocessing steps

include("data_preprocessing.jl");

process_csv(;
    id = :fips,
    # patpth = "data/mobility_processed.jld2",
    dpth = "data/setup_data.csv",
    spth = "data/cvd_dat.jld2",
    trim_to_mob = true
);
