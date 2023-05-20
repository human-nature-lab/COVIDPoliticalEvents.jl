# preamble.jl

Random.seed!(2019)

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

# vax = CSV.read("vax_county_proc.csv", DataFrame);

# select!(vax, Not(:Recip_County))

# mytryparse(T, str) = something(tryparse(T, str), missing)

# vax.fips = mytryparse.(Int, vax.FIPS)
# dropmissing!(vax, :fips)
# serpct = Symbol("Pct. series complete")
# rename!(vax, :Completeness_pct => serpct)

# dat = leftjoin(dat, vax, on = [:date => :Date, :fips])

cvs = [cvs..., vn.rare]
cvs = setdiff(cvs, [vn.fc])

model = deathmodel(
  scenario * ARGS[1], :gub, Symbol(ARGS[1]), dat,
  outcome;
  iterations = iters,
  F = F, L = L,
  matchingcovariates = cvs,
);

# model.timevary[serpct] = false

dat = dataprep(dat, model);
