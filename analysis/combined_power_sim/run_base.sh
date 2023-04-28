#!/bin/bash
#SBATCH --output co_base-%A_%2a-%N.out
#SBATCH --job-name co_base
#SBATCH --mem=120G --cpus-per-task=20 --nodes=1
#SBATCH --ntasks=1 -t 02:00:00
#SBATCH --mail-type ALL

module load Julia
module load R

export JULIA_NUM_THREADS=${SLURM_CPUS_ON_NODE}; julia --project="." combined_power_sim/base_model.jl
