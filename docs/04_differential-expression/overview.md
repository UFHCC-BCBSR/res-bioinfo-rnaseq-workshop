# Differential Expression Analysis: Overview & Background

This section provides background on the statistical framework underlying differential expression analysis with *limma*. If you are already familiar with these concepts, you can skip directly to the [Workshop Notebook](notebook.md).

## What is Differential Expression Analysis?

Differential expression (DE) analysis is a statistical approach to identifying genes or isoforms that show different levels of expression between a set of conditions or treatments of interest. The null hypothesis being tested is that expression of individual genes does not vary between conditions.

## Example Data

Our sample data comprises 12 paired-end RNA-seq libraries for whole body samples of *Drosophila melanogaster* from two geographic regions (Panama and Maine), with two temperature treatments ("low" and "high") for each region, featuring three biological replicates for each region × treatment combination. Previously, these data were used to look for parallel gene expression patterns between high and low latitude populations (Zhao et al, 2015, *PLoS Genetics*).

For this tutorial we focus on gene-level patterns of differential expression, using the count data in `rsem.merged.gene_counts.tsv`. The column headers include "gene_id" and "gene_name" for the first two columns, and the sample names for the remaining columns.

Our example sample sheet is called `dme_elev_samples.tsv`:

| **sample** | **population** | **temp** |
|---|---|---|
| SRR1576457 | maine | low |
| SRR1576458 | maine | low |
| SRR1576459 | maine | low |
| SRR1576460 | maine | high |
| SRR1576461 | maine | high |
| SRR1576462 | maine | high |
| SRR1576463 | panama | low |
| SRR1576464 | panama | low |
| SRR1576465 | panama | low |
| SRR1576514 | panama | high |
| SRR1576515 | panama | high |
| SRR1576516 | panama | high |

## The limma-voom Framework

This tutorial performs differential expression analysis with the `limma` package in R, using the voom transformation. The key steps are:

1. **Filtering** out lowly expressed genes to reduce noise and improve statistical power
2. **TMM normalization** to account for library size differences and composition bias
3. **voom transformation** to convert counts to log-CPM with precision weights
4. **Linear model fitting** to estimate fold changes and standard errors
5. **Empirical Bayes moderation** to improve variance estimates by borrowing information across genes
6. **Multiple testing correction** using the Benjamini-Hochberg FDR procedure

## Design Matrices

At the heart of linear modeling are design matrices that specify the experimental factors and their levels. A design matrix encodes which samples belong to which groups, and limma uses it to fit linear models and test hypotheses about the coefficients of those models.

For a simple one-factor experiment with two temperature treatments, the design matrix looks like this:

| **row** | **(Intercept)** | **templow** |
|---|---|---|
| 1 | 1 | 1 |
| 2 | 1 | 1 |
| 3 | 1 | 1 |
| 4 | 1 | 0 |
| 5 | 1 | 0 |
| 6 | 1 | 0 |

The intercept estimates baseline expression in the reference condition (high temperature), and the *templow* coefficient estimates the difference in expression between low and high temperature.

## Empirical Bayes Moderation

Given the typically small number of biological replicates in bulk RNA-seq experiments, gene-wise variance estimates will be noisy. `eBayes` addresses this by "shrinking" gene-wise variances towards the fitted mean-variance curve — genes whose dispersion is further from the fitted line are shrunk more, those closer are shrunk less. This produces more robust tests for differential expression.

## Sample Quality Weights

Rather than discarding outlier samples — which is often not feasible with small numbers of replicates — limma can assign empirical quality weights to samples, down-weighting those that exhibit outlier-like behavior. This is done with `voomWithQualityWeights` and is generally preferred over the standard `voom` function.

## Multiple Testing Correction

Because we are simultaneously testing thousands of genes, we must correct for multiple testing. We use the Benjamini-Hochberg procedure, which controls the false discovery rate (FDR). A gene is considered differentially expressed if its adjusted p-value (q-value) is below a threshold, typically 0.05.

## Further Reading

- [limma User's Guide](https://bioconductor.org/packages/release/bioc/vignettes/limma/inst/doc/usersguide.pdf)
- [edgeR User's Guide](https://bioconductor.org/packages/release/bioc/vignettes/edgeR/inst/doc/edgeRUsersGuide.pdf)
- Ritchie et al. 2015, *Nucleic Acids Research* — the limma paper
- Robinson and Oshlack 2010, *Genome Biology* — the TMM normalization paper
