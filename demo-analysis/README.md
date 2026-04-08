# Demo Analysis

This directory contains the workshop demonstration RNA-seq analysis. Scripts
are numbered and should be run in order. Optional scripts extend the core
analysis and can be run independently after completing the main workflow.

---

## Data

```
demo-analysis/
├── data/
│   ├── metadata/
│   │   ├── SraRunTable.csv          # Raw metadata from NCBI SRA
│   │   └── sample_metadata.csv      # Cleaned metadata (created during setup)
│   ├── raw/                         # Symlinks to raw .fastq files
│   └── two-factor-design/           # Drosophila dataset (optional script)
│       ├── salmon.merged.gene_counts.tsv
│       └── dme_elev_samples.tsv
└── output/
    ├── 01-prepared-data/            # Created by 01_prepare_nfcore_data.R
    │   ├── rsem.merged.gene_counts.tsv
    │   ├── sample_info.tsv
    │   ├── gene_annotation.tsv
    │   ├── data_summary.txt
    │   ├── library_sizes.png
    │   └── README.txt
    └── 02-differential-expression/  # Created by scripts 02-04
        ├── DGE_filtered_normalized.rds
        ├── figures/
        └── results/
```

---

## Scripts

### 01 — Prepare nf-core Data

**File:** `scripts/01_prepare_nfcore_data.R`  
**Run as:** Source in RStudio

**Goal:** Read raw nf-core/rnaseq pipeline output and prepare it for
downstream analysis.

**Inputs:**
- `/blue/bioinf_workshop/share/nfcore_rnaseq_output/star_rsem/rsem.merged.gene_counts.tsv` (shared, read-only)
- `data/metadata/sample_metadata.csv`

**Outputs** → `output/01-prepared-data/`:
- `rsem.merged.gene_counts.tsv` — gene count matrix
- `sample_info.tsv` — sample metadata
- `gene_annotation.tsv` — Ensembl ID to gene symbol mapping
- `data_summary.txt` — summary statistics
- `library_sizes.png` — QC plot
- `README.txt` — file descriptions

---

### 02 — Quality Control

**File:** `scripts/02_quality_control.qmd` / `scripts/02_quality_control.Rmd`  
**Run as:** Chunk by chunk in RStudio

**Goal:** Assess sample quality, filter lowly expressed genes, and apply
TMM normalization.

**Inputs:**
- `output/01-prepared-data/rsem.merged.gene_counts.tsv`
- `data/metadata/sample_metadata.csv`

**Outputs** → `output/02-differential-expression/`:
- `DGE_filtered_normalized.rds` — normalized DGEList object for use in script 03
- `figures/library_sizes_filtered.png`
- `figures/mds_plot.png`
- `figures/correlation_heatmap.png`

---

### 03 — Differential Expression

**File:** `scripts/03_differential_expression.qmd` / `scripts/03_differential_expression.Rmd`  
**Run as:** Chunk by chunk in RStudio  
**Requires:** Script 02 to have been run

**Goal:** Identify differentially expressed genes between PRMT7 knockdown
and wildtype using limma-voom.

**Inputs:**
- `output/02-differential-expression/DGE_filtered_normalized.rds`

**Outputs** → `output/02-differential-expression/`:
- `results/de_results_all.csv` — full DE results table
- `results/de_results_significant.csv` — FDR < 0.05 only
- `results/sessionInfo.txt`
- `figures/volcano_plot.png`
- `figures/ma_plot.png`
- `figures/heatmap_top50.png`

---

### 04 — Pathway Analysis

**File:** `scripts/04_pathway_analysis.qmd` / `scripts/04_pathway_analysis.Rmd`  
**Run as:** Chunk by chunk in RStudio  
**Requires:** Script 03 to have been run

**Goal:** Identify enriched biological processes and pathways among
differentially expressed genes using GO and KEGG over-representation analysis.

**Inputs:**
- `output/02-differential-expression/results/de_results_all.csv`

**Outputs** → `output/02-differential-expression/`:
- `results/GO_BP_enrichment.csv`
- `results/GO_BP_enrichment_simplified.csv`
- `results/GO_BP_upregulated.csv`
- `results/GO_BP_downregulated.csv`
- `results/KEGG_enrichment.csv`
- `figures/GO_BP_dotplot.png`
- `figures/GO_BP_emap.png`
- `figures/GO_BP_cnetplot.png`
- `figures/GO_BP_simplified_dotplot.png`
- `figures/GO_up_vs_down.png`
- `figures/KEGG_dotplot.png`
- `figures/GO_vs_KEGG_comparison.png`

---

## Optional Scripts

<details>
<summary><strong>opt_01 — edgeR + GREIN Comparison</strong></summary>

**File:** `scripts/optional/opt_01_edgeR_GREIN_comparison.qmd` / `.Rmd`  
**Run as:** Chunk by chunk in RStudio  
**Requires:** Script 03 to have been run

**Goal:** Reproduce a GREIN-style edgeR exact test analysis and compare
results to limma-voom. Demonstrates reproducibility challenges when
methods documentation is incomplete.

**Inputs:**
- `output/01-prepared-data/rsem.merged.gene_counts.tsv`
- `data/metadata/sample_metadata.csv`
- `output/02-differential-expression/results/de_results_all.csv`

**Outputs** → `output/02-differential-expression/`:
- `results/edger_grein_matched_results.csv`
- `results/sessionInfo_edger.txt`
- `figures/volcano_plot_edger_grein.png`
- `figures/ma_plot_edger_grein.png`

</details>

<details>
<summary><strong>opt_02 — Advanced Designs: Two-Factor Analysis</strong></summary>

**File:** `scripts/optional/opt_02_advanced_designs.qmd` / `.Rmd`  
**Run as:** Chunk by chunk in RStudio  
**Requires:** Nothing — standalone script

**Goal:** Demonstrate limma-voom with a two-factor experimental design
using a published Drosophila temperature adaptation dataset. Covers
interaction models, contrast matrices, and parallel vs. divergent
response patterns.

**Inputs:**
- `data/two-factor-design/salmon.merged.gene_counts.tsv`
- `data/two-factor-design/dme_elev_samples.tsv`

**Outputs** → `output/02-differential-expression/`:
- `results/drosophila_contrast_results.csv`
- `results/drosophila_maine_temperature.csv`
- `results/drosophila_panama_temperature.csv`
- `results/drosophila_interaction.csv`
- `results/drosophila_parallel_response_genes.csv`
- `results/drosophila_divergent_response_genes.csv`
- `figures/volcano_drosophila_temperature.png`

</details>
