# run models locally

mdir = "ga-election/"

push!(ARGS, "epi")

files = [
    "base_model.jl",
    "ts_model.jl",
    "turnout_model.jl"
]

for file in files
    try
        include(file)
    catch
        txt = "problem with file " * file
        @warn txt
        continue
    end
end

# run models locally

ARGS[1] = "nomob"

files = [
    "base_model.jl",
    "ts_model.jl",
    "turnout_model.jl"
]

for file in files
    try
        include(file)
    catch
        txt = "problem with file " * file
        @warn txt
        continue
    end
end

# run models locally

ARGS[1] =  "full"

files = [
    "base_model.jl",
    "ts_model.jl",
    "turnout_model.jl"
]

for file in files
    try
        include(file)
    catch
        txt = "problem with file " * file
        @warn txt
        continue
    end
end
