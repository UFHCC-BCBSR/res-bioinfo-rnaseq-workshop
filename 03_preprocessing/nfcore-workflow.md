# Quantifying Expression: Best Practice Using the *nf-core/rnaseq* Workflow

In order to obtain a comprehensive set of quality control metrics on our fastq files, while also obtaining gene and isoform-level count matrices, we use nf-core's RNA-seq pipeline. nf-core is a collection of *Nextflow* workflows for automating analyses of high-dimensional biological data. Nextflow is a workflow language that can be used to chain together multi-step data analysis workflows, which can easily be adapted for running on high performance computing environments such as UF's HiPerGator cluster. We specifically use the "STAR-RSEM" option, which performs spliced alignment to the genome with *STAR* and expression quantification with *RSEM*.

The workflow requires as input a specifically formatted sample sheet, a genome fasta, and either a gtf or a gff annotation file.

In order to run the workflow you will need:

- A sample sheet in the nf-core format
- A gtf/gff genome annotation file
- A genome fasta file
- A config file with HPC-specific settings

## The nf-core Sample Sheet Format

The sample sheet must be in comma-separated format with specific column headers:

```
sample,fastq_1,fastq_2,strandedness
sample1,fastq/sample1_R1_fastq.gz,fastq/sample1_R2_fastq.gz,auto
sample2,fastq/sample2_R1_fastq.gz,fastq/sample2_R2_fastq.gz,auto
```

| **Column** | **Description** |
|---|---|
| sample | The sample ID, used as the column header in the count matrix |
| fastq_1 | The path to the R1 fastq file for the sample |
| fastq_2 | The path to the R2 fastq file for the sample |
| strandedness | The strandedness of the library: "auto", "forward", "reverse", or "unstranded" |

> **We do not recommend using single-end data for expression analysis.**
> More robust expression estimates can be obtained with short paired-end reads that are effectively the same cost per base as traditional single-end layouts. See: Freedman et al. 2020, BMC Bioinformatics.

Locations of R1 and R2 can be paths relative to the launch location or absolute paths. Fastq files should be gzipped. If a sample ID occurs in more than one row, the workflow assumes these are separate sequencing runs of the same sample and aggregates counts across rows.

While strand configuration can be manually specified, we prefer to use the auto-detect function, which will also account for cases where strandedness is unknown, mistakenly specified, or inconsistent.

## The gtf/gff Genome Annotation File

The nf-core ecosystem was built to work optimally with annotation files from Ensembl, though it will generally work with NCBI annotation files. For both sources, gtf versions are preferred.

For NCBI annotations, the workflow will occasionally fail because some features lack a value for *gene_id* in the attributes column of the gtf. A typical error message of this type looks like:

```
ERROR: failed to find the gene identifier attribute in the 9th column of the provided GTF file.
```

We use the additional argument `--skip_biotype_qc` in our workflow to skip a biotype-based expression QC metric that can cause warnings or failures with NCBI files.

## The Config File

A config file specifies the computational resources allocated for workflow jobs. To use HPC resources, specify the executor and partition names at the beginning of the `process` block. In the case of HiPerGator, on which jobs are scheduled by SLURM:

```
process {
    executor = 'slurm'
    cpus   = { 1      * task.attempt }
    memory = { 6.GB   * task.attempt }
    time   = { 4.h    * task.attempt }
    queue  = 'hpg-default'
```

## Executing the nf-core RNA-seq Workflow

We recommend submitting the nextflow pipeline as a SLURM job on a compute node:

```bash
#SBATCH -J nfcorerna
#SBATCH -N 1
#SBATCH -c 1
#SBATCH -t 23:00:00
#SBATCH -p hpg-default
#SBATCH --mem=12000
#SBATCH -e nf-core_star_rsem_%A.err
#SBATCH -o nf-core_star_rsem_%A.out

module load nextflow
nextflow run nf-core/rnaseq \
    --input nfcore_samplesheet.csv \
    --outdir $(pwd)/star_rsem \
    --skip_biotype_qc \
    --gtf genome/mygenome.gtf \
    --fasta genome/mygenome.fna.gz \
    --aligner star_rsem \
    -profile singularity \
    --save_reference \
    -c rnaseq_cluster.config
```

| **Option** | **Description** |
|---|---|
| `--input` | Path to the sample sheet in nf-core format |
| `--outdir` | Path to the output directory |
| `--skip_biotype_qc` | Skip biotype-based QC; necessary for NCBI gff/gtf files |
| `--gtf` | Path to genome annotation file in gtf format; must be **uncompressed** |
| `--fasta` | Path to genome fasta file; must be **gzipped** |
| `--aligner` | Aligner to use; in this case *star_rsem* |
| `-profile` | Profile to use; in this case *singularity* |
| `--save_reference` | Save reference genome and annotation files to the output directory |
| `-c` | Path to the config file with HPC-specific settings |

Key notes:

- Launching nf-core/rnaseq automatically downloads the workflow and installs all dependencies.
- The genome needs to be gzipped.
- The annotation file should be uncompressed. If using a gff file, replace `--gtf` with `--gff`.

## The Output

The output of this workflow includes:

- The *star_rsem* directory, containing:
    - bam files from STAR alignment for each sample
    - Gene and transcript count tables in tsv format
    - *rsem.merged.gene_counts.tsv* and *rsem.merged.transcript_counts.tsv*, the estimated raw counts in matrix form
- The *multiqc/star_rsem* directory, containing *multiqc_report.html*, an html report compiling all sample-level quality metrics.

We are now ready to perform differential expression analysis in R.
