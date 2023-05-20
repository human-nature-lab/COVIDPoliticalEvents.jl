#!/bin/bash

# collect, preprocess, organize data for analysis

cd ..

Rscript data/scripts/preprocess.R

julia --threads 16 data/scripts/preprocess.jl
