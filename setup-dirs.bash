#!/bin/bash

# RNA-seq Workshop Repository Structure Setup
# Usage: bash setup_rnaseq_workshop.sh
# Run from within res-bioinfo-rnaseq-workshop/

set -e

echo "Setting up RNA-seq workshop directory structure..."

# Define modules
MODULES=(
    "00_pipeline-overview"
    "01_command-line-basics"
    "02_hipergator-basics"
    "03_preprocessing"
    "04_differential-expression"
    "05_pathway-analysis"
    "06_visualization"
)

# Modules that get scripts/ and example-data/ subdirs
DATA_MODULES=(
    "03_preprocessing"
    "04_differential-expression"
    "05_pathway-analysis"
    "06_visualization"
)

# Create top-level docs/assets
mkdir -p docs/assets

# Create each module with base subdirs
for module in "${MODULES[@]}"; do
    mkdir -p "${module}/exercises"
    touch "${module}/README.md"
    echo "  Created: ${module}/"
done

# Add scripts/ and example-data/ to appropriate modules
for module in "${DATA_MODULES[@]}"; do
    mkdir -p "${module}/scripts"
    mkdir -p "${module}/example-data"
    echo "  Added scripts/ and example-data/ to ${module}/"
done

# Add a docs/ subfolder to pipeline-overview for diagrams/file format explainers
mkdir -p 00_pipeline-overview/docs

# Create top-level files
touch README.md
touch mkdocs.yml

echo ""
echo "Done! Here's your structure:"
echo ""
find . -not -path '*/\.*' | sort | sed 's|[^/]*/|  |g'
