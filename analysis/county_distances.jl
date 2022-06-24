# county_distances.jl

using COVIDPoliticalEvents, DataFrames, DataFramesMeta
using PrettyTables

cdict = county_dist_dict();

# omnibus deaths model

X = load_object("combined out/combined modelfull_deaths_excluded.jld2");
matches = X.matchinfo;
matches = get_county_distances(matches, cdict)
cdist_deaths = county_distances(matches)

# omnibus R_t model
X = load_object("combined Rt out/combined Rt modelfull_Rt_excluded.jld2");
matches = X.matchinfo;
matches = get_county_distances(matches, cdict)
cdist_Rt = county_distances(matches)

pretty_table(cdist_Rt, tf = PrettyTables.tf_markdown)

# BLM model
X = load_object("protest out/ protest nomob_death_rte_.jld2");
matches = X.matchinfo;
matches = get_county_distances(matches, cdict)
cdist_blm = county_distances(matches)

pretty_table(cdist_blm, tf=PrettyTables.tf_markdown)
# trump rally model
