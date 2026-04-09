---
title: Demo Analysis Guide
subtitle: RNA-seq Bioinformatics Workshop - Hands On Demo Analysis Guide
author: UF Health Cancer Institute Bioinformatics
date: 2026-04-07
---

# Overview

This document explains the demo analysis setup.

---

# Demo Analysis File Layout

## What is GitHub and Why Are We Using It?

GitHub is a platform for hosting and sharing code. The workshop analysis scripts, configuration files, and directory structure are all stored in a **repository** (repo) — essentially a project folder that lives on GitHub. Rather than downloading files one by one, we use `git clone` to copy the entire repo to HiPerGator in one command. You won't need to know much more about Git for this workshop, but if you want to learn more, [GitHub's own guides](https://docs.github.com/en/get-started) are a good starting point.

The files for the demo analysis will be created by cloning the [workshop's GitHub repository](https://github.com/UFHCC-BCBSR/res-bioinfo-rnaseq-workshop):

## What You'll Create (Your Working Space)

```
/blue/bioinf_workshop/$USER/
└── rnaseq_workshop/
    ├── .gitignore
    ├── mkdocs.yml
    ├── README.md
    ├── docs/
    └── demo-analysis/
        ├── data/
        │   ├── metadata/
        │   │   ├── SraRunTable.csv          # Raw metadata from NCBI SRA
        │   │   └── sample_metadata.csv      # Cleaned metadata (created for you)
        │   ├── raw/                         # Symlinks to raw .fastq files
        │   └── two-factor-design/           # Drosophila dataset (for optional script)
        │       ├── salmon.merged.gene_counts.tsv
        │       └── dme_elev_samples.tsv
        └── output/
            ├── differential-expression/     # Created by scripts 01-03
            │   ├── DGE_filtered_normalized.rds
            │   ├── figures/
            │   └── results/
            └── optional/                    # Created by optional/opt_01_prepare_nfcore_data.R
                ├── rsem.merged.gene_counts.tsv
                ├── sample_info.tsv
                ├── gene_annotation.tsv
                ├── data_summary.txt
                ├── library_sizes.png
                └── README.txt
```

## Shared Workshop Data (Read-Only)

```
/blue/bioinf_workshop/share/nfcore_rnaseq_files/
├── fastqc/
├── fq_lint/
├── genome/
├── multiqc/
├── pipeline_info/
├── star_rsem/
└── trimgalore/
```

> **Note:** This directory is read-only. Your scripts will read from here but write output to your own working directory.

---

# Setup Instructions

## Create Your Working Directory and Clone the Repo

If you are not already logged in to HiPerGator, open a terminal and SSH in:

```bash
ssh $USER@hpg.rc.ufl.edu
```

Then navigate to your workshop directory and clone the repo:

```bash
cd /blue/bioinf_workshop/$USER
git clone https://github.com/UFHCC-BCBSR/res-bioinfo-rnaseq-workshop.git rnaseq_workshop
cd rnaseq_workshop
ls -la
```

> You should see: `demo-analysis/`, `docs/`, `.gitignore`, `.Renviron`, `mkdocs.yml`, `README.md`

## Launch RStudio Server

!!! warning "Make sure you are in the cloned repo directory before submitting"
    RStudio Server sources .Renviron from the directory where it is launched from. You must be inside `rnaseq_workshop/` before running `sbatch` to ensure this is sourced.

    ```bash
    pwd
    ```

    > You should see `/blue/bioinf_workshop/$USER/rnaseq_workshop` — if not, run `cd /blue/bioinf_workshop/$USER/rnaseq_workshop` first.

Create and submit a SLURM job to launch RStudio Server:

```bash
cat > rstudio.sbatch << 'EOF'
#!/bin/bash
#SBATCH --job-name=rserver
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=28gb
#SBATCH --time=05:00:00
#SBATCH --output=rserver_%j.log
#SBATCH --error=rserver_%j.err
#SBATCH --account=bioinf_workshop
#SBATCH --qos=bioinf_workshop

module purge; module load R/4.5
rserver
EOF
sbatch rstudio.sbatch
```

Check that the job is running:

```bash
squeue -u $USER
```

Once running, check the log for your connection details (replace `12345678` with your actual job ID):

```bash
cat rserver_12345678.log
```

You will see output like:

> Starting rserver on port 45261 in the /blue/bioinf_workshop/username/rnaseq_workshop directory.  
> Create an SSH tunnel with:  
> `ssh -N -L 8080:c0710a-s29.ufhpc:45261 username@hpg.rc.ufl.edu`  
> Then, open in the local browser:  
> `http://localhost:8080`

!!! info "What is all that other output in the log?"
    You will see RStudio Server startup messages after the SSH tunnel instructions, including what looks like an ERROR about a missing config file. This is normal and can be ignored. If RStudio loaded in your browser, everything is working correctly.

**To connect to RStudio:**

1. Open a **new terminal window on your local machine** (not on HiPerGator) and run the `ssh -N -L ...` command shown in your log. The terminal will appear to hang — this is normal, leave it running.
2. Open any browser and go to `http://localhost:8080`.

## Verify Your Setup in RStudio

Once RStudio opens, verify your working directory and package library path in the **Console**.

First check your working directory — it should already be set to the repo root if you submitted the job from the right place:

```r
getwd()
```

> `/blue/bioinf_workshop/username/rnaseq_workshop`

If it is not correct, set it manually (replace `username` with your GatorLink username):

```r
setwd("/blue/bioinf_workshop/username/rnaseq_workshop")
```

Then use the **gear icon ⚙** in the Files panel → **Go To Working Directory** to confirm.

Next, verify your package library path is correct:

```r
.libPaths()
```

> `[1] "/blue/bioinf_workshop/share/R_libs"`  
> `[2] "/usr/local/lib/R/site-library"`  
> `[3] "/usr/lib/R/site-library"`  
> `[4] "/usr/lib/R/library"`

!!! warning "If your .libPaths() looks different"
    The shared library at `/blue/bioinf_workshop/share/R_libs` must be first in the list — this is where all the workshop packages are pre-installed. If it is not listed or not first, the scripts will fail with "package not found" errors. In R Console, run:

    ```r
    source("/blue/bioinf_workshop/<username>/rnaseq_workshop/.Rprofile")
    ```

> All scripts use the `here` package to build file paths relative to the repository root, so they work for everyone without needing to change any paths in the code.

---

# Running the Differential Expression Analysis

With your working directory set, open and run the three numbered scripts in order — each picks up where the previous one left off.

---

### 01 — Quality Control

**File:** `demo-analysis/scripts/01_quality_control.Rmd`  
**Run as:** Chunk by chunk in RStudio

Loads the nf-core/rnaseq count matrix directly from the shared directory, converts Ensembl IDs to gene symbols, assesses sample quality, filters lowly expressed genes, and applies TMM normalization.

Before running, confirm your metadata looks correct by opening `demo-analysis/data/metadata/sample_metadata.csv` in the Files panel.

**Outputs** → `output/differential-expression/`:

| File | Description |
|------|-------------|
| `DGE_filtered_normalized.rds` | Normalized DGEList for script 02 |
| `figures/library_sizes_filtered.png` | Library size QC plot |
| `figures/mds_plot.png` | Sample similarity plot |
| `figures/correlation_heatmap.png` | Sample correlation heatmap |

---

### 02 — Differential Expression

**File:** `demo-analysis/scripts/02_differential_expression.Rmd`  
**Run as:** Chunk by chunk in RStudio  
**Requires:** Script 01 to have been run

Identifies differentially expressed genes between PRMT7 knockdown and wildtype using limma-voom.

**Outputs** → `output/differential-expression/`:

| File | Description |
|------|-------------|
| `results/de_results_all.csv` | Full DE results table |
| `results/de_results_significant.csv` | FDR < 0.05 only |
| `results/sessionInfo.txt` | Session info |
| `figures/volcano_plot.png` | Volcano plot |
| `figures/ma_plot.png` | MA plot |
| `figures/heatmap_top50.png` | Top 50 DE genes heatmap |

---

### 03 — Pathway Analysis

**File:** `demo-analysis/scripts/03_pathway_analysis.Rmd`  
**Run as:** Chunk by chunk in RStudio  
**Requires:** Script 02 to have been run

Identifies enriched biological processes and pathways among differentially expressed genes using GO and KEGG over-representation analysis.

**Outputs** → `output/differential-expression/`:

| File | Description |
|------|-------------|
| `results/GO_BP_enrichment.csv` | Full GO biological process results |
| `results/GO_BP_enrichment_simplified.csv` | Simplified GO results |
| `results/GO_BP_upregulated.csv` | GO results for upregulated genes |
| `results/GO_BP_downregulated.csv` | GO results for downregulated genes |
| `results/KEGG_enrichment.csv` | KEGG pathway results |
| `figures/GO_BP_dotplot.png` | GO dotplot |
| `figures/GO_BP_emap.png` | GO enrichment map |
| `figures/GO_BP_cnetplot.png` | GO concept network |
| `figures/GO_BP_simplified_dotplot.png` | Simplified GO dotplot |
| `figures/GO_up_vs_down.png` | Up vs. down GO comparison |
| `figures/KEGG_dotplot.png` | KEGG dotplot |
| `figures/GO_vs_KEGG_comparison.png` | GO vs. KEGG comparison |

---

## Optional Scripts

<details>
<summary><strong>opt_01 — Prepare nf-core Data</strong></summary>

**File:** `scripts/optional/opt_01_prepare_nfcore_data.R`  
**Run as:** Source in RStudio

Reads the raw nf-core/rnaseq pipeline output, converts Ensembl IDs to gene symbols, and generates QC and summary files. The core workshop scripts read the count matrix directly, so this script is not required — but it is useful if you want to explore the data preparation steps in more detail.

**Outputs** → `output/optional/`:

| File | Description |
|------|-------------|
| `rsem.merged.gene_counts.tsv` | Gene count matrix with gene symbols |
| `sample_info.tsv` | Sample metadata |
| `gene_annotation.tsv` | Ensembl ID to gene symbol mapping |
| `data_summary.txt` | Summary statistics |
| `library_sizes.png` | Library size QC plot |
| `README.txt` | File descriptions |

</details>

<details>
<summary><strong>opt_02 — edgeR + GREIN Comparison</strong></summary>

**File:** `scripts/optional/opt_02_edgeR_GREIN_comparison.Rmd`  
**Run as:** Chunk by chunk in RStudio  
**Requires:** Script 02 to have been run

Reproduces a GREIN-style edgeR exact test analysis and compares results to limma-voom. Demonstrates reproducibility challenges when methods documentation is incomplete.

**Outputs** → `output/differential-expression/`:

| File | Description |
|------|-------------|
| `results/edger_grein_matched_results.csv` | edgeR vs. limma-voom comparison |
| `results/sessionInfo_edger.txt` | Session info |
| `figures/volcano_plot_edger_grein.png` | edgeR volcano plot |
| `figures/ma_plot_edger_grein.png` | edgeR MA plot |

</details>

<details>
<summary><strong>opt_03 — Advanced Designs: Two-Factor Analysis</strong></summary>

**File:** `scripts/optional/opt_03_advanced_designs.Rmd`  
**Run as:** Chunk by chunk in RStudio  
**Requires:** Nothing — standalone script

Demonstrates limma-voom with a two-factor experimental design using a published Drosophila temperature adaptation dataset. Covers interaction models, contrast matrices, and parallel vs. divergent response patterns.

**Outputs** → `output/differential-expression/`:

| File | Description |
|------|-------------|
| `results/drosophila_contrast_results.csv` | Full contrast results |
| `results/drosophila_maine_temperature.csv` | Maine temperature effect |
| `results/drosophila_panama_temperature.csv` | Panama temperature effect |
| `results/drosophila_interaction.csv` | Interaction results |
| `results/drosophila_parallel_response_genes.csv` | Parallel response genes |
| `results/drosophila_divergent_response_genes.csv` | Divergent response genes |
| `figures/volcano_drosophila_temperature.png` | Drosophila volcano plot |

</details>

---

# Troubleshooting

## Working directory is wrong

```r
getwd()
```

If it doesn't return `/blue/bioinf_workshop/username/rnaseq_workshop`, run:

```r
setwd("/blue/bioinf_workshop/username/rnaseq_workshop")
```

Then use the **gear icon ⚙** in the Files panel → **Go To Working Directory**.

## "Cannot find file" errors

```r
list.files("demo-analysis/output/differential-expression")
```

If empty, you need to run the preceding script first.

## Package not installed

If `.libPaths()` is correct and you still get package errors, let an instructor know — all required packages should be pre-installed in the shared library. If you need to install a package yourself:

```r
install.packages(c("tidyverse", "ggrepel", "pheatmap", "RColorBrewer", "here"))
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install(c("limma", "edgeR"))
```