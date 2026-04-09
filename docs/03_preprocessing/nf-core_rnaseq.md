# Running the nf-core/rnaseq pipeline

**Pipeline documentation**: https://nf-co.re/rnaseq  
**Pipeline GitHub**: https://github.com/nf-core/rnaseq

---

## Overview

The `nf-core/rnaseq` pipeline takes raw paired-end or single-end FASTQ files and processes them through a standardized, reproducible workflow that includes quality control, adapter trimming, genome (& pseudo-) alignment, expression quantification, and aggregated reporting. The workflow requires as input a specifically formatted sample sheet, a genome fasta, and either a gtf or a gff annotation file.

By the end of the pipeline you will have:

- Quality-checked, adapter-trimmed reads
- Genome-aligned BAM files
- Gene and isoform-level count matrices
- A comprehensive MultiQC HTML report

![nf-core rnaseq metro map](../assets/nf-core-rnaseq_metro_map_grey_animated.svg)

On UF's HiPerGator, nf-core is available as a pre-installed software module along with Nextflow. Both modules can be loaded using the following commands:

```bash
module load nf-core
module load nextflow/25.10.4
```

---

## Pipeline Components and Tools

| Key Steps | Tool(s) | Purpose | Required? |
|---|---|---|---|
| Validation of inputs | Custom script | Check input file formats | ✅ Default |
| Raw and post-trim read QC | FastQC | Assess quality of raw reads | ✅ Default |
| Adapter trimming | Trim Galore | Remove adapters and low-quality bases | ✅ Default |
| rRNA removal | SortMeRNA | Filter ribosomal RNA contamination | ⬜ Optional |
| Genome alignment | STAR | Splice-aware alignment to reference genome | ✅ (STAR-RSEM) |
| Alignment QC | RSeQC, Qualimap, SAMtools | Assess alignment quality, strandedness, coverage uniformity | ✅ Default |
| Duplicate marking | picard MarkDuplicates | Flag PCR/optical duplicates | ✅ Default |
| Library complexity | Preseq | Estimate library complexity and sequencing saturation | ⬜ Optional |
| Quantification | RSEM | Gene and isoform-level expression estimation | ✅ (STAR-RSEM) |
| Aggregated QC | MultiQC | Compile all QC metrics into one HTML report | ✅ Default |

---

## Alignment and Quantification Options

The pipeline offers several aligner/quantifier combinations. We use **STAR-RSEM** in this workshop:

| Option | Aligner | Quantifier | Best For |
|---|---|---|---|
| `star_rsem` ✅ | STAR | RSEM | Standard DE analysis; gene & isoform-level quantification |
| `star_salmon` | STAR | Salmon | Faster quantification; large cohorts |
| `hisat2_salmon` | HISAT2 | Salmon | Lower memory usage; resource-constrained environments |

**STAR-RSEM** is preferred for standard differential expression analysis because it produces high-quality alignment BAM files (useful for QC) and uses RSEM's probabilistic model to handle multi-mapping reads more accurately.

---

## Prerequisites

Before launching the pipeline, the following files are required:

1. **Sample sheet** (CSV format)
2. **Genome FASTA file**
3. **Genome annotation file** (GTF preferred, uncompressed)
4. **Nextflow config file** (HPC-specific settings)
5. **STARIndex** (optional, time-saving if pre-built)
6. **Parameters YAML file** (recommended)
7. **SLURM submission script**

---

## Step 1: Prepare the Sample Sheet

The sample sheet is a comma-separated file that tells the pipeline where your FASTQ files are. Navigate to your workshop directory and create it:

```bash
cd /blue/bioinf_workshop/$USER
nano samplesheet.csv
```

Paste the following content, save, and exit:

```
sample,fastq_1,fastq_2,strandedness,seq_platform
SRR12546980,/blue/bioinf_workshop/share/nfcore_rnaseq_files/inputs/fastq/SRR12546980.fastq,,auto,ILLUMINA
SRR12546982,/blue/bioinf_workshop/share/nfcore_rnaseq_files/inputs/fastq/SRR12546982.fastq,,auto,ILLUMINA
SRR12546984,/blue/bioinf_workshop/share/nfcore_rnaseq_files/inputs/fastq/SRR12546984.fastq,,auto,ILLUMINA
SRR12546986,/blue/bioinf_workshop/share/nfcore_rnaseq_files/inputs/fastq/SRR12546986.fastq,,auto,ILLUMINA
SRR12546988,/blue/bioinf_workshop/share/nfcore_rnaseq_files/inputs/fastq/SRR12546988.fastq,,auto,ILLUMINA
SRR12546990,/blue/bioinf_workshop/share/nfcore_rnaseq_files/inputs/fastq/SRR12546990.fastq,,auto,ILLUMINA
```

### Column Descriptions

| Column | Description |
|---|---|
| `sample` | A unique sample identifier. This becomes the column header in the count matrix. Use short, descriptive, alphanumeric names with no spaces. |
| `fastq_1` | Path to the R1 (forward) FASTQ file. Can be relative to your launch directory or an absolute path. |
| `fastq_2` | Path to the R2 (reverse) FASTQ file. Leave empty for single-end data. |
| `strandedness` | Library strandedness. Options: `auto`, `forward`, `reverse`, `unstranded`. We recommend `auto`. |
| `seq_platform` | Sequencing platform. Optional. |

### Important Rules

Locations of R1 and R2 can be paths relative to the location where the workflow is being launched or absolute paths. FASTQ files should be gzipped. If a sample ID occurs in more than one row, the workflow assumes these are separate sequencing runs of the same sample and counts will be aggregated across those rows.

While strand configuration can be manually specified, we prefer to use Salmon's auto-detect function, which accounts for cases where strandedness is unknown, mistakenly specified, or where reagent issues led to unexpected library structure.

---

## Step 2: Prepare the Genome Files

!!! info "For this workshop, skip this step — genome files are already prepared"
    The genome FASTA, GTF, and STAR index files have already been downloaded and prepared at `/blue/bioinf_workshop/share/nfcore_rnaseq_files/inputs/genome_files/`. The paths in `params.yaml` already point to these. This section is here for reference when you run the pipeline on your own data.

**Genome FASTA**

- Must be gzipped (e.g., `genome.fna.gz`)
- Download from Ensembl or NCBI for your organism of interest

**Genome Annotation (GTF)**

- Must be uncompressed (`.gtf`, not `.gtf.gz`)
- Ensembl GTF files are preferred — they follow a consistent format that is fully compatible with all pipeline tools
- NCBI GTF files can be used but may cause errors due to missing `gene_id` attributes:

```
ERROR: failed to find the gene identifier attribute in the 9th column of the provided GTF file.
```

The nf-core ecosystem was built to work optimally with Ensembl annotation files. For NCBI annotations, the workflow will occasionally fail because some manually curated features lack a `gene_id` value in the attributes column. Warnings or job failure may also occur if `gene_biotype` is missing, which is why we use `--skip_biotype_qc` to skip that QC metric. The genome and GTF files must be from the same source.

---

## Step 3: Prepare the Nextflow Config File

The config file tells Nextflow how to interact with HiPerGator's SLURM scheduler and how much compute resource to request per job. Create it:

```bash
nano nextflow_rnaseq.config
```

Paste the following, save, and exit:

```
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Nextflow config file for RNA-Seq analysis on HiPerGator
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
process {
  executor = "slurm"
  clusterOptions = "--account=bioinf_workshop --qos=bioinf_workshop"
}

process {
  withName: 'NFCORE_RNASEQ:RNASEQ:DUPRADAR' {
    time = 80.h
    memory = 48.GB
    cpus = 6
    errorStrategy = 'ignore'
  }
}

process {
  errorStrategy = {
    task.attempt <= 3 ? "retry" : "finish"
  }
}
```

---

## Step 4: Write the Parameters YAML File

Rather than putting all parameters in the SLURM script command, storing them in a YAML file makes your runs more readable, reproducible, and easy to version-control. Create it:

```bash
nano params.yaml
```

Paste the following, **replacing `yourusername` with your actual GatorLink username**, save, and exit:

!!! warning "Replace yourusername"
    `$USER` does not expand inside YAML files the way it does in bash. You must manually replace `yourusername` with your actual GatorLink username in the `outdir` and `email` fields below.

```yaml
---
# General Parameters
input: "samplesheet.csv"
outdir: "/blue/bioinf_workshop/yourusername/nfcore_output"
email: "yourusername@ufl.edu"
multiqc_title: "TestData_RNASEQ_Multiqc"

# Input Files — pre-prepared for this workshop
fasta: "/blue/bioinf_workshop/share/nfcore_rnaseq_files/inputs/genome_files/genome.fa"
gtf: "/blue/bioinf_workshop/share/nfcore_rnaseq_files/inputs/genome_files/genes.gtf"

# Alignment
aligner: "star_rsem"
star_index: "/blue/bioinf_workshop/share/nfcore_rnaseq_files/inputs/genome_files/STARIndex"

# iGenomes
igenomes_ignore: true

# Process skipping
skip_preseq: true
skip_biotype_qc: true
```

---

## Step 5: Write the SLURM Submission Script

This script submits the Nextflow pipeline manager itself as a SLURM job. Nextflow then submits each pipeline step as its own SLURM job internally.

!!! info "Workshop test run"
    For the workshop we set a short time limit and low memory so the job starts quickly and validates that all your file paths and configuration are correct. The pipeline will not complete a full run in this time — that is expected. Pre-prepared output from a complete run is available at `/blue/bioinf_workshop/share/nfcore_rnaseq_files/outputs/` and will be used in the differential expression analysis section.

Create the script:

```bash
nano rnaseq.sbatch
```

Paste the following, save, and exit:

```bash
#!/bin/bash
#SBATCH --job-name=nfcorernaseq
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4gb
#SBATCH --qos=bioinf_workshop
#SBATCH --account=bioinf_workshop
#SBATCH --time=00:05:00
#SBATCH --output=rnaseq_%j.out
#SBATCH --error=rnaseq_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=$USER@ufl.edu

# Load required modules
module load nf-core
module load nextflow/25.10.4

# Use shared Singularity cache so images don't need to be re-downloaded
export NXF_SINGULARITY_CACHEDIR=/blue/bioinf_workshop/share/singularity_cache

nextflow run nf-core/rnaseq -r 3.23.0 \
        -c nextflow_rnaseq.config \
        -profile singularity \
        -params-file params.yaml \
        -work-dir /blue/bioinf_workshop/$USER/work \
        --save_reference
```

!!! warning "Always pin the pipeline version"
    Always use `-r` to pin the pipeline version (e.g., `-r 3.23.0`). This ensures your results are reproducible and not affected by future pipeline updates. Check available versions at https://github.com/nf-core/rnaseq/releases.

---

## Submitting and Monitoring the Pipeline

Make sure you are in your workshop directory before submitting:

```bash
cd /blue/bioinf_workshop/$USER
```

Submit the job:

```bash
sbatch rnaseq.sbatch
```

Check job status — `ST` column shows `PD` (pending), `R` (running), or `CG` (completing):

```bash
squeue -u $USER
```

Monitor progress in real time (press `Ctrl+C` to stop):

```bash
tail -f rnaseq_12345678.out
```

Check for errors (replace with your job ID):

```bash
tail -f rnaseq_12345678.err
```

!!! info "What should I expect to see?"
    With a 5-minute time limit, the job will start, validate your input files and configuration, begin pulling pipeline steps, and then hit the time limit and stop. This is intentional — if you see the pipeline start running steps without immediately erroring out, your setup is correct. If you see errors about missing files or incorrect paths, check your `samplesheet.csv` and `params.yaml`. The pre-prepared output from a complete run will be used for the rest of the workshop.

---

## Pipeline Outputs

Once a full run is complete, your output directory will look like this. The pre-prepared output at `/blue/bioinf_workshop/share/nfcore_rnaseq_files/outputs/` follows this same structure:

```
nfcore_output/
├── fastqc/                               # Raw read QC (FastQC)
│   ├── raw/
│   └── trim/
├── trimgalore/                           # Trimmed reads and Trim Galore reports
├── star_rsem/                            # Alignment and quantification outputs
│   ├── *.Aligned.sortedByCoord.out.bam
│   ├── *.Aligned.toTranscriptome.out.bam
│   ├── *.genes.results                   # Per-sample RSEM counts
│   ├── *.isoforms.results
│   ├── rsem.merged.gene_counts.tsv       # ✅ Use this for DE analysis
│   ├── rsem.merged.transcript_counts.tsv
│   ├── rsem.merged.gene_tpm.tsv
│   └── rsem.merged.transcript_tpm.tsv
├── samtools_stats/                       # Alignment statistics
├── rseqc/                                # RNA-specific alignment QC
├── qualimap/                             # Coverage and bias QC
├── preseq/                               # Library complexity estimates
├── picard_metrics/                       # Duplicate marking reports
├── dupradar/                             # Duplication rate estimates
├── multiqc/
│   └── star_rsem/
│       └── multiqc_report.html           # ✅ Start here for QC review
└── pipeline_info/                        # Nextflow execution reports
```

The key output for differential expression analysis is `rsem.merged.gene_counts.tsv` — a matrix of raw estimated counts with genes as rows and samples as columns.

After reviewing the MultiQC report, proceed to the differential expression analysis section.