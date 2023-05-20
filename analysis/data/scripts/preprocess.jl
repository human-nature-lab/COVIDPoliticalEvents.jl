# data preprocessing steps

include("data_preprocessing.jl");

process_csv(;
    id = :fips,
    # patpth = "data/data/mobility_processed.jld2",
    dpth = "data/data/setup_data.csv",
    spth = "data/data/cvd_dat.jld2",
    trim_to_mob = true
);
