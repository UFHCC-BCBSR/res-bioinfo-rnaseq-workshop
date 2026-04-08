# Quality Control in RNA-Seq: MultiQC Report

## Quality Matters

Before trusting any downstream analysis — differential expression, pathway analysis, or otherwise — you need to verify that your raw data and processed outputs meet basic quality standards. Poor-quality RNA-seq data can arise from many sources:

-   Degraded RNA at time of library preparation
-   Low sequencing depth
-   Adapter contamination
-   rRNA or DNA contamination
-   PCR over-amplification (duplicates)
-   Biased coverage (e.g., 3' bias in degraded samples)
-   Sample swaps or mislabeling

The `nf-core/rnaseq` pipeline automates QC at every stage and compiles all results into a single **MultiQC report**. This section explains each QC tool, what it measures, and what to look for.

------------------------------------------------------------------------

## The MultiQC Report: Key Points

[**MultiQC**](https://multiqc.info/) aggregates the output of all QC tools across all samples into a single, interactive HTML report.

Download the html file from the output folder. You will find the report at the following location:

```         
/blue/bioinf_workshop/share/nfcore_rnaseq_files/outputs/multiqc/star_rsem
```

To use scp to download the report:

``` bash
# Copy to your local machine and open in a browser
scp username@hpg.rc.ufl.edu:/OUTPUT/star_rsem/multiqc/star_rsem/multiqc_report.html ./
open multiqc_report.html   # macOs
```

To download it using [OnDemand](<https://ondemand.rc.ufl.edu/pun/sys/dashboard/>), log in and navigate to the same location and click 'Download' after selecting the html report.

The report includes sections for every tool that ran — FastQC, Trim Galore, STAR, Picard, RSeQC, Qualimap, Preseq, and RSEM. Each section shows per-sample metrics and highlights any samples that fall outside expected ranges.

------------------------------------------------------------------------

**<u>1. FastQC — Raw Read Quality Assessment</u>**

[FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) is the standard first-pass QC tool for sequencing data. It runs on raw FASTQ files and generates a set of diagnostic plots.

| Module | What to Look For |
|------------------------------------|------------------------------------|
| Per-base sequence quality | Phred scores should be \>28 across the read. It's normal for quality to drop slightly at the 3' end. |
| Per-sequence quality scores | The distribution should peak at high quality (\>30). A low-quality peak indicates a problem. |
| Per-base sequence content | The first \~10 bases often show variation due to random hexamer priming — this is normal. Uniform composition expected after that. |
| GC content | Should follow a smooth, roughly normal distribution centered near the expected GC% for your organism. Unusual peaks or bimodal distributions suggest contamination. |
| Sequence duplication levels | High duplication is expected for RNA-seq (some transcripts are highly expressed). Extremely high duplication (\>80%) may indicate over-amplification. |
| Adapter content | Should be near zero after trimming. High adapter content in raw reads is expected and normal before trimming. |
| Overrepresented sequences | rRNA or adapter sequences showing up here suggest contamination. |

------------------------------------------------------------------------

**<u>2. Trim Galore / Cutadapt — Adapter Trimming and Quality Filtering</u>**

[Trim Galore](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/) is a wrapper around the [Cutadapt](https://cutadapt.readthedocs.io/en/stable/) adapter trimmer, with additional quality trimming. It removes adapter sequences and low-quality bases from read ends.

-   Detects and removes Illumina adapter sequences

-   Trims low-quality bases from the 3' end (default Phred \< 20)

-   Removes reads that become too short after trimming (default: \< 20 bp)

-   Runs FastQC on the trimmed reads automatically

-   **% reads passing filter:** Should be \>90% for a good library

-   **% bases trimmed:** A small percentage (1–10%) is normal. Very high values (\>30%) suggest adapter contamination or low quality

-   Reads significantly shorter after trimming may indicate RNA degradation

------------------------------------------------------------------------

**<u>3. SAMtools — Alignment Statistics</u>**

[SAMtools](http://www.htslib.org/) is a suite of tools for manipulating SAM/BAM alignment files. In the pipeline, it is used to generate per-sample alignment summary statistics via `samtools flagstat` and `samtools stats`.

| Metric | Meaning | What to look for |
|------------------------|------------------------|------------------------|
| \% mapped reads | Fraction of reads that aligned to the genome | \>75% (typically 85–95% for good samples) |
| \% properly paired | Both reads in a pair align to the same chromosome in expected orientation | \>90% |
| \% singletons | One read mapped but its pair did not | Should be low (\<5%) |
| \% reads mapped to different chromosomes | Indicative of chimeric or contaminating reads | Should be very low |

> > ⚠️ A low overall mapping rate (\<70%) can indicate issues such as wrong genome used, high contamination, or very low quality /degraded input RNA.

------------------------------------------------------------------------

**<u>4. DupRadar - Duplication Rate in Context of Expression Level</u>**

[DupRadar](https://bioconductor.org/packages/release/bioc/html/dupRadar.html) is a Bioconductor R package that assesses duplication rates in the context of **gene expression levels**. It goes beyond what Picard's `MarkDuplicates` offers by asking a more nuanced question: *are duplicates arising from highly expressed genes (expected), or are they uniformly high across all genes (problematic)?*

- A healthy library shows **low duplication at low expression** and **high duplication only at high expression**
- A problematic library shows **uniformly high duplication across all expression levels**
- **Duplication rate vs. expression level**: Plots the duplication rate of each gene against its expression level (RPK)


------------------------------------------------------------------------

**<u>5. Picard — Duplicate Marking</u>**

[Picard](https://broadinstitute.github.io/picard/) is a Java toolkit from the Broad Institute for processing sequencing data. The `MarkDuplicates` tool identifies reads that are likely PCR or optical duplicates — identical copies of the same original DNA fragment.

Two reads are considered duplicates if they map to the exact same genomic coordinates. Duplicates are **flagged** in the BAM file but not removed by default in this pipeline.

| Metric | Meaning | What to look for |
|------------------------|------------------------|------------------------|
| \% duplicate reads | Fraction of reads flagged as duplicates | \>30–40% may indicate over-amplification |
| Estimated library size | Estimated number of unique molecules in the library | Very small values (\<1M) suggest poor complexity |

> > 💡 Some duplication is expected and unavoidable in RNA-seq, especially for highly expressed transcripts. Very high duplication rates combined with low library complexity estimates indicate a problem.

------------------------------------------------------------------------

**<u>6. Preseq — Library Complexity Estimation</u>**

[Preseq](http://smithlabresearch.org/software/preseq/) estimates how many unique reads you would expect to obtain if you sequenced the library to greater depth. This tells you whether your library is **saturated** (you've already captured most of the diversity) or whether deeper sequencing would yield more information.

-   Expected distinct reads as a function of total reads sequenced
-   A steep, still-rising curve indicates the library has not been exhausted and would benefit from deeper sequencing
-   A curve that flattens early indicates the library is saturated — more sequencing yields diminishing returns

**What to look for**

-   Samples where the curve rises steeply: good complexity, potentially under-sequenced
-   Samples where the curve plateaus early: low complexity — may indicate heavy duplication or degraded input RNA

------------------------------------------------------------------------

**<u>7. RSeQC — RNA-Specific Alignment Quality</u>**

[RSeQC](https://rseqc.sourceforge.net/) is a Python package specifically designed for assessing the quality of RNA-seq alignments. Unlike SAMtools (which gives generic alignment metrics), RSeQC provides RNA-aware diagnostics.

**Key modules used by nf-core/rnaseq:**

**`infer_experiment`** Infers the strandedness of the library by examining how reads align relative to annotated gene features.

-   Confirms or contradicts the `strandedness` setting in your sample sheet
-   Important for downstream quantification accuracy

**`read_distribution`** Categorizes reads based on which genomic feature they overlap: CDS exon, UTR, intronic, intergenic, etc.

| Expected | What a Problem Looks Like |
|------------------------------------|------------------------------------|
| Majority of reads in CDS exons and UTRs | High intronic reads: unspliced RNA, nuclear contamination, or genomic DNA contamination |
| Low intergenic reads | High intergenic reads: wrong genome or annotation, or heavy contamination |

**`junction_annotation`** Compares splice junctions in the alignments to known junctions in the annotation.

-   Most junctions should be **known** (annotated)
-   A high proportion of novel junctions may indicate a poorly annotated genome or contamination

**`junction_saturation`** Shows whether you've sequenced deeply enough to detect most splice junctions. A plateauing curve means you've captured most junctions.

**`inner_distance`** Estimates the insert size of your paired-end library. Useful for detecting grossly abnormal library preparations.

**`bam_stat`** Provides a summary of alignment flags — similar to `samtools flagstat` but with additional RNA-relevant categories.

------------------------------------------------------------------------

**<u>8. Qualimap — Coverage and Bias Assessment</u>**

[Qualimap](http://qualimap.conesalab.org/) provides a comprehensive set of coverage-based QC metrics for RNA-seq BAM files.

| Metric | Meaning |
|------------------------------------|------------------------------------|
| 5'/3' bias | Measures whether reads are uniformly distributed across transcripts. High 3' bias indicates RNA degradation. |
| Coverage across transcript | A flat line is ideal. A downward slope toward the 5' end indicates degradation. |
| Reads aligned to genes | Should be high — low values suggest annotation or alignment problems. |
| Junction reads | Proportion of reads spanning splice junctions — expected to be high for mRNA. |

> > 💡 The 5' to 3' coverage plot is one of the most important diagnostics for RNA quality. If you see a strong 3' bias, it may indicate the RNA was degraded before library preparation, which can bias expression estimates toward 3' transcript ends.

------------------------------------------------------------------------

## QC Summary: Red Flags to Watch For

| Problem | Likely QC Signal | Possible Cause |
|------------------------|------------------------|------------------------|
| Low mapping rate (\<70%) | SAMtools flagstat | Wrong genome, heavy contamination, very low quality input |
| High duplication rate (\>50%) | Picard MarkDuplicates | Over-amplified library, low input RNA |
| Strong 3' bias | Qualimap coverage plot | RNA degradation |
| High adapter content | FastQC adapter content | Sequencing short inserts, trimming failure |
| Unusual GC distribution | FastQC GC content | Contamination, PCR bias |
| Low complexity | Preseq | Degraded RNA, over-amplification |
| High intronic reads | RSeQC read distribution | Genomic DNA contamination, unspliced RNA |
| Strandedness mismatch | RSeQC infer_experiment | Incorrect strandedness specified in sample sheet |

------------------------------------------------------------------------

## Using the MultiQC Report for Sample-Level Decisions

Before proceeding to differential expression, use the MultiQC report to:

-   **Identify outlier samples** — samples that cluster away from others in QC metrics
-   **Confirm acceptable mapping rates** — flag any sample below 70%
-   **Check for batch effects** — do samples from the same sequencing run cluster together?
-   **Decide whether to exclude any samples** — document any exclusions clearly
-   **Verify strandedness was correctly detected** — check the RSeQC `infer_experiment` section

> 💡 It is better to remove a poor-quality sample from the analysis than to include it and risk confounded results. Document all exclusions in your methods.

### References

-   <https://nf-co.re/rnaseq/3.23.0/docs/usage/>
-   <https://www.youtube.com/watch?v=qPbIlO_KWN0>
