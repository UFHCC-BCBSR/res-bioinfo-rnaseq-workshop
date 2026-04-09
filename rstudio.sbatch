#!/bin/bash
#SBATCH --job-name=rserver
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=28gb
#SBATCH --time=12:00:00
#SBATCH --output=logs/rserver_%j.log
#SBATCH --error=logs/rserver_%j.error
#SBATCH --account=bioinf_workshop
#SBATCH --qos=bioinf_workshop

module purge; module load R/4.5 # Load a specific version of R for reproducubility between sessions
rserver
