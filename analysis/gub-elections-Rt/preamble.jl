# preamble.jl

Random.seed!(2019)

scenario = "gub "

obvars = [vn.pd, vn.ts16];

# remove other election counties on that date
# NJ Gub & Ohio House
housecounties = [39035, 39153, 39159, 39097, 39049];
c1 = dat.fips .∉ Ref(housecounties);
dat = dat[c1, :];

cvs = COVIDPoliticalEvents.covariateset(
  vn, vn.rt;
  modeltype = Symbol(ARGS[1])
)

model = rtmodel(
  scenario * ARGS[1], :gub, Symbol(ARGS[1]), dat; iterations = iters,
  matchingcovariates = setdiff([cvs..., vn.rare], [vn.fc])
);

dat = dataprep(dat, model; convert_missing = false);
