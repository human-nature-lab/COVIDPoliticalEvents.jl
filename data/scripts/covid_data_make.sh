#!/bin/bash

# collect, preprocess, organize data for analysis

cd ..

Rscript scripts/preprocess.R

julia --threads 16 scripts/preprocess.jl
