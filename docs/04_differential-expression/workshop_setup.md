---
title: Workshop Setup Guide
subtitle: RNA-seq Bioinformatics Workshop - Hands On Demo Analysis Guide
author: UF Health Cancer Institute Bioinformatics
date: 2026-04-07
---

# Overview

This document explains the demo analysis setup and where your data files are.

---

# Workshop File Layout

## What You'll Create (Your Working Space)

```
/blue/bioinf_workshop/your_username/
└── rnaseq_workshop/
    ├── .gitignore
    ├── mkdocs.yml
    ├── README.md
    ├── docs/
    ├── logs/
    └── demo-analysis/
        ├── data/
        │   ├── metadata/
        │   │   ├── SraRunTable.csv
        │   │   └── sample_metadata.csv   (created during setup)
        │   └── raw/
        ├── output/
        │   ├── 01-prepared-data/         (created by prep script)
        │   └── 02-differential-expression/   (created by analysis)
        │       ├── figures/
        │       └── results/
        └── scripts/
            ├── 01_prepare_nfcore_data.R
            └── 02_differential_expression_analysis.qmd
```

## Shared Workshop Data (Read-Only)

```
/blue/bioinf_workshop/share/nfcore_rnaseq_output/
├── fastqc/
├── fq_lint/
├── genome/
├── multiqc/
├── pipeline_info/
├── star_rsem/
└── trimgalore/
```

> **Note:** This directory is read-only. Your scripts will read from here
> but write output to your own working directory.

---

# Setup Instructions

## Create Your Working Directory and Clone the Repo

If you are not already logged in to HiPerGator, open a terminal and SSH in
(replace `your_username` with your actual username):

```bash
ssh your_username@hpg.rc.ufl.edu
```

Then navigate to your workshop directory and clone the repo:

```bash
cd /blue/bioinf_workshop/your_username/

git clone https://github.com/UFHCC-BCBSR/res-bioinfo-rnaseq-workshop.git rnaseq_workshop

cd rnaseq_workshop

ls -la
# You should see: demo-analysis/, docs/, .gitignore, mkdocs.yml, README.md
```

## Launch RStudio Server

Create and submit a SLURM job to launch RStudio Server by copying and pasting this in the command prompt:

```bash
cat > rstudio.sbatch << 'EOF'
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
module purge; module load R/4.5
rserver
EOF

sbatch rstudio.sbatch
```

Check that the job is running:

```bash
ml bcbsr_tools
sjobs
```

Once running, check the log for your connection details (replace `<JOBID>`
with your actual job ID):

```bash
cat logs/rserver_<JOBID>.log
```

You will see output like:

```
Starting rserver on port 45261 in the /blue/bioinf_workshop/your_username/rnaseq_workshop directory.
Create an SSH tunnel with:
ssh -N -L 8080:c0710a-s29.ufhpc:45261 your_username@hpg.rc.ufl.edu
Then, open in the local browser:
http://localhost:8080
```

**To connect to RStudio:**

1. Open a **new terminal window or tab on your local machine** (not on
   HiPerGator) and run the `ssh -N -L ...` command shown in your log.
   The working directory on your local machine doesn't matter.
2. Open any browser and paste `http://localhost:8080` into the address bar.

## Set Your Working Directory in RStudio

Once RStudio opens, set your working directory in the **Console**
(replace `your_username` with your actual username):

```r
setwd("/blue/bioinf_workshop/your_username/rnaseq_workshop")
```

Then in the **Files panel** (bottom-right), click the **gear icon ⚙** and
select **Go To Working Directory** to confirm you are in the right place.

> All scripts use the `here` package to build file paths relative to the
> repository root, so they work for everyone without needing to change
> any paths in the code.

## Create Sample Metadata

Before running the data preparation script, you need to create a metadata
file that describes your experimental design. In the RStudio **Console**, run:

```r
library(tidyverse)
library(here)

read_csv(here("demo-analysis", "data", "metadata", "SraRunTable.csv")) %>%
  select(sample = Run, group = genotype) %>%
  write_csv(here("demo-analysis", "data", "metadata", "sample_metadata.csv"))
```

In the Files panel, open `demo-analysis/data/metadata/sample_metadata.csv`
to confirm it looks correct. You should see two columns:

| Column | Contents |
|--------|----------|
| `sample` | SRR run IDs (e.g. SRR12546980) |
| `group` | PRMT7 WT or PRMT7 KD |

## Run the Data Preparation Script

In the Files panel, open `demo-analysis/scripts/01_prepare_nfcore_data.R`
and click **Source** (top-right of the script editor) to run the entire script.

This will create the following files in `demo-analysis/output/01-prepared-data/`:

| File | Description |
|------|-------------|
| `rsem.merged.gene_counts.tsv` | Gene count matrix |
| `sample_info.tsv` | Sample metadata |
| `gene_annotation.tsv` | Gene ID to symbol mapping |
| `data_summary.txt` | Summary statistics |
| `library_sizes.png` | QC plot |
| `README.txt` | File descriptions |

---

# Running the Differential Expression Analysis

With your working directory set and data prepared, open:

`demo-analysis/scripts/02_differential_expression_analysis.qmd`

Work through the notebook **chunk by chunk** using the green play button
or `Ctrl+Enter`. This notebook will walk you through the full differential
expression analysis using limma-voom.

After completing the analysis, you will find results in
`demo-analysis/output/02-differential-expression/`:

| Location | Contents |
|----------|----------|
| `figures/` | PNG files of all plots |
| `results/` | CSV files with DE results |

---

# Troubleshooting

## Working directory is wrong

```r
getwd()
# Should return: /blue/bioinf_workshop/your_username/rnaseq_workshop
```

If it doesn't, run:

```r
setwd("/blue/bioinf_workshop/your_username/rnaseq_workshop")
```

Then use the **gear icon ⚙** in the Files panel → **Go To Working Directory**.

## "Cannot find file" errors

```r
# Check what files exist in the output directory
list.files("demo-analysis/output/01-prepared-data")

# If empty, you need to run 01_prepare_nfcore_data.R first
```

## Data prep script can't find nf-core output

Check this line in `01_prepare_nfcore_data.R`:

```r
nfcore_results_dir <- "/blue/bioinf_workshop/share/nfcore_rnaseq_output/"
```

Ask an instructor if the path looks different.

## Package not installed

```r
install.packages(c("tidyverse", "ggrepel", "pheatmap", "RColorBrewer", "here"))

if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install(c("limma", "edgeR"))
```