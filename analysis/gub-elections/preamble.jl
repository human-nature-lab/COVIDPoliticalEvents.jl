# preamble.jl

Random.seed!(2019)

savepath = "gub out/";
scenario = prefix * " gub out "

obvars = [vn.pd, vn.ts16];

# remove other election counties on that date
# NJ Gub & Ohio House
housecounties = [39035, 39153, 39159, 39097, 39049];
c1 = dat.fips .∉ Ref(housecounties);
dat = dat[c1, :];

cvs = COVIDPoliticalEvents.covariateset(
  vn, outcome;
  modeltype = Symbol(ARGS[1])
)

cvs = [cvs..., vn.rare]
cvs = setdiff(cvs, [vn.fc])

model = deathmodel(
  scenario * ARGS[1], :gub, Symbol(ARGS[1]), dat,
  outcome;
  iterations = iters,
  F = F, L = L,
  matchingcovariates = cvs,
);

dat = dataprep(dat, model);
