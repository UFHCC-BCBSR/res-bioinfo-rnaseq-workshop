
# Quantifying Gene Expression: From Reads to Count Matrices


**Attribution:** Portions of this page are inspired by the [Harvard FAS Informatics RNA-seq tutorial](https://informatics.fas.harvard.edu/resources/tutorials/differential-expression-analysis/) by Adam Freedman, c. 2023:2025.


## What is Expression Quantification?
At its core, RNA-seq quantification answers the question: **"How many RNA molecules from each gene were sequenced in my sample?"**
The path from raw sequencing reads to a count matrix involves solving two connected statistical problems:

1. **Assigning each read to a gene or transcript of origin**

2. **Converting read assignments to expression estimates**
Both steps involve **uncertainty**, and how a tool handles that uncertainty has a major impact on the quality and accuracy of your expression estimates. Early bioinformatics approaches to RNA-seq quantification simply discarded multi-mapping reads, leading to loss of information and lack of robustness within the estimates, and effectively precluded investigations of expression variation among alternatively spliced transcripts. Fortunately, there are now two common approaches for handling read assignment uncertainty in a way that can be leveraged by state-of-the-art tools that quantify expression.

**<u>Level 1: The Problem of Read Assignment</u>**

*Uniquely Mapping Reads*
Some reads map to only one location in the genome to an exon of a gene that has no overlapping sequences with any other gene. These **uniquely mapping reads** can be confidently assigned to their gene of origin.

*Multi-Mapping Reads*

Many reads are harder to assign:

- **Alternatively spliced transcripts**: Many genes produce multiple transcripts by including or excluding different exons. A read that falls on an exon shared between two isoforms of the same gene cannot definitively be assigned to one isoform or the other.
- **Gene families with similar sequences**: Reads from paralogous genes may align equally well to multiple genomic loci.
- **Repetitive elements**: Some reads fall in repetitive regions that occur hundreds of times in the genome.

Early RNA-seq analysis tools simply **discarded multi-mapping reads**, leading to substantial loss of information. For genes with many isoforms or members of expanded gene families, this could mean losing a large fraction of reads precisely the reads needed to distinguish expression differences.
Modern tools handle this problem using **probabilistic models** that distribute multi-mapping reads across their possible origins in proportion to the evidence available.


**<u>Level 2: The Problem of Converting Assignments to Counts</u>**
Even if we know which gene a read came from, converting that to a meaningful count estimate is not straightforward:

- **Transcript length**: Longer transcripts produce more reads than shorter ones, even at the same expression level. Counts must be normalized by transcript length for within-sample comparisons.
- **Alternative isoform lengths**: If a gene has isoforms of very different lengths, the expected number of reads differs even at the same expression level.
- **Sequencing depth**: More total reads = more reads per gene. Counts must be normalized by total sequencing depth for between-sample comparisons.

Tools like **RSEM** use a statistical model (expectation-maximization) to estimate expression values that account for all of these factors simultaneously.

## Two Approaches to Quantification

**Approach 1: Sequence Alignment**
Sequence alignment tools formally align each read to the reference genome or transcriptome, recording the exact position of each match, mismatch, gap, or splice junction in a **SAM/BAM format file**.
For RNA-seq, alignment to the genome requires a **splice-aware aligner** that can span introns the genomic sequences that are spliced out of mature mRNA. The most widely used splice-aware aligner is **STAR** (Spliced Transcripts Alignment to a Reference).

**What is STAR?**
[**STAR**](https://github.com/alexdobin/STAR) (Spliced Transcripts Alignment to a Reference) is an ultra-fast RNA-seq aligner that:

- Performs splice-aware alignment, correctly handling reads that span exon???intron boundaries
- Detects both **known** splice junctions (from the GTF annotation) and **novel** splice junctions
- Produces standard BAM files that can be used for both QC and downstream quantification
- Builds a genome index on first run (30 to 60 min, save and reuse)

**Advantages of alignment-based approaches**:

- Produces BAM files required for RNA-specific QC tools (RSeQC, Qualimap)
- Can detect novel splice junctions
- Well-validated and widely benchmarked

**Limitations**:

- Computationally expensive

**Memory note:** STAR is fast but memory-intensive, typically requiring ~38GB RAM for the human GRCh38 reference genome. If you are working in a memory-constrained environment, you can switch to the HISAT2 aligner using `--aligner hisat2`.

**Tip:** The genome index is built from scratch on the first run a compute-intensive process that can take 30???60 minutes. It is good practice to save the generated index using `--save_reference` so it can be reused in future runs, saving both time and compute resources.

**GPU acceleration:** The pipeline supports NVIDIA GPUs via a Parabricks container, which can significantly reduce alignment runtime. HiPerGator provides GPU partition access check with your HPC administrator to confirm Parabricks availability on your allocation.


**Approach 2: Pseudo-alignment**
Pseudo-alignment (also called quasi-mapping or lightweight mapping) takes a fundamentally different approach. Rather than formally aligning reads to a reference, tools like **Salmon** and **kallisto** use k-mer based or hash-based substring matching to **probabilistically determine** the transcript of origin without base-level alignment precision.

**What is Salmon?**

[**Salmon**](https://combine-lab.github.io/salmon/) is a tool for fast, accurate transcript-level quantification. It uses a statistical model called **variational Bayesian expectation maximization** to distribute reads across transcripts and estimate expression values.
Salmon can run in two modes:

1. **Quasi-mapping mode** (`salmon quant -r fastq`): Runs directly on FASTQ files. Very fast can process a human RNA-seq library in minutes.

2. **Alignment mode** (`salmon quant -a bam`): Takes BAM files (e.g., from STAR) as input instead.
The `nf-core/rnaseq` pipeline uses Salmon in alignment mode when the `star_salmon` aligner option is selected STAR produces the BAM files, and Salmon quantifies from them.

**Advantages of pseudo-alignment**:

- Extremely fast 5-10x faster than alignment + RSEM
- Low memory requirements
- Well-suited for large cohorts (hundreds to thousands of samples)

**Limitations**:

- Does not produce BAM files (in direct mode), limiting some QC options
- Slightly lower accuracy for multi-mapping reads compared to RSEM in some benchmarks


## Our Recommended Approach: STAR + RSEM

We use the **STAR-RSEM** combination for this workshop. Here is why:

**Step 1: STAR Alignment**
STAR aligns reads to the genome and produces:

- A **genome-sorted BAM** (for QC tools)
- A **transcriptome BAM** (for RSEM input)

Having genome-aligned BAM files is important because it enables **all of the RNA-specific QC tools** (RSeQC, Qualimap) to assess alignment quality, strandedness, coverage uniformity, and potential biases before you trust your expression estimates.

Notes:

**Spike-in controls:** The pipeline supports the addition of custom control FASTA sequences, such as ERCC spike-in controls (`--additional_fasta`), allowing you to include external reference standards for normalization and quality assessment.

**UMI support:** Unique Molecular Identifiers (UMIs) are short random sequences ligated to each RNA molecule before amplification, allowing PCR duplicates to be distinguished from true biological reads and improving quantification accuracy. If your library was prepared with UMIs, the pipeline provides dedicated options to process and deduplicate UMI-tagged reads.

**Step 2: RSEM Quantification**

[**RSEM**](https://deweylab.github.io/RSEM/) (RNA-Seq by Expectation Maximization) takes the transcriptome-aligned BAM from STAR and uses an **expectation-maximization (EM) algorithm** to estimate expression levels.

*How the EM Algorithm Works (Conceptually)*

Imagine you have a bag of colored balls (reads), and you're trying to figure out how many of each color was in the original mixture (transcripts). Some balls are clearly one color (uniquely mapping reads). But some balls are ambiguous they could be red or orange (multi-mapping reads).
The EM algorithm:

1. **E-step**: Given current expression estimates, calculate the probability that each read came from each transcript
2. **M-step**: Update expression estimates to maximize the likelihood of the observed read assignments
3. Repeat until estimates converge

This allows RSEM to make use of multi-mapping reads rather than discarding them.

**RSEM Output Files**

| File | Description |
|---|---|
| `*.genes.results` | Per-sample gene-level expression: expected counts, TPM, FPKM |
| `*.isoforms.results` | Per-sample isoform-level expression: expected counts, TPM, FPKM |
| `rsem.merged.gene_counts.tsv` | **Gene count matrix across all samples input for DE analysis** |
| `rsem.merged.transcript_counts.tsv` | Transcript count matrix across all samples |
| `rsem.merged.gene_tpm.tsv` | Gene TPM matrix (normalized, for visualization) |
| `rsem.merged.transcript_tpm.tsv` | Transcript TPM matrix |

**Understanding the Count Types**

| Value | Full Name | Use Case |
|---|---|---|
| **Expected counts** | Fractional read counts estimated by EM | Input to DESeq2/edgeR for differential expression |
| **TPM** | Transcripts Per Million | Within- and between-sample comparisons; visualization |
| **FPKM/RPKM** | Fragments/Reads Per Kilobase Million | Legacy metric; not recommended for DE analysis |

> **For differential expression analysis**, always use **raw expected counts** (`rsem.merged.gene_counts.tsv`). Tools like DESeq2 , edgeR require raw counts and perform their own normalization internally. Do not input TPM or FPKM values into DESeq2.


**Gene-Level vs. Isoform-Level Quantification**

RSEM estimates expression at both the **gene** and **transcript (isoform)** level simultaneously.

| Level | When to use |
|---|---|
| **Gene-level counts** | Standard differential expression analysis (most common use case) |
| **Isoform-level counts** | Differential splicing or isoform usage analysis (requires more samples and statistical power) |

For this workshop, we focus on **gene-level counts**.

After the pipeline completes, the `rsem.merged.gene_counts.tsv` file looks like this: