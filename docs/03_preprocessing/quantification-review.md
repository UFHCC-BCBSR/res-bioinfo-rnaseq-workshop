# Quantifying Expression: A Brief Review

**Attribution:** Portions of this page are inspired by the [Harvard FAS Informatics RNA-seq tutorial](https://informatics.fas.harvard.edu/resources/tutorials/differential-expression-analysis/) by Adam Freedman c. 2023-2025

In order to obtain counts of RNA abundance from fastq files, one must employ statistical methods that account for two levels of uncertainty. The first is identifying the most likely transcript of origin of each RNA-seq read. The second is the conversion of read assignments to a count matrix, and doing so in a way that models the uncertainty inherent in many read assignments.

While some reads may uniquely map to a transcript from a gene without alternative splicing, in many cases shared genomic segments among alternatively spliced transcripts within a gene will make it challenging (and in some cases impossible) to definitively identify the true transcript of origin. Early bioinformatics approaches to RNA-seq quantification simply discarded reads of uncertain origin, leading to substantial loss of information that undoubtedly undermined the robustness of expression estimates, and effectively precluded investigations of expression variation among alternatively spliced transcripts. Fortunately, there are now two common approaches for handling read assignment uncertainty.

## Sequence Alignment

The first entails formally aligning sequencing reads to either a genome or a set of transcripts derived from a genome annotation, such that exact coordinates of sequence matches, mismatches, and small structural variations are recorded. In both cases, a *sam* (or bam) format output file is produced. Alignment directly to a genome requires using a splice-aware aligner to accommodate alignment gaps due to introns, with STAR being the most popular, while tools like bowtie2 can be used to map reads to a set of transcript sequences.

## Pseudo-alignment

The second approach, called "pseudo-alignment", does not undertake formal sequence alignment but instead uses substring matching to probabilistically determine locus of origin without obtaining base-level precision of where any given read came from. It also allows for uncertainty in the transcript of origin. The pseudo-alignment approach is much quicker than sequence alignment. Tools such as Salmon and kallisto employ this approach. An added bonus of pseudo-alignment tools is that they simultaneously figure out where reads come from and convert assignments to counts, producing sample-level counts that can later be converted to the count matrix format taken as input by differential expression tools.

A different approach to converting read assignments to counts is to model assignment uncertainty recorded in sequence alignment *sam* or *bam* files produced by tools like *STAR* and *bowtie2*. A popular tool for doing this is RSEM, which uses an expectation maximization algorithm to estimate counts.

## Our Recommended Approach

Because bam files contain information useful for performing quality checks on your data, we believe it is worthwhile to perform sequence alignment unless it is computationally infeasible. We recommend a hybrid approach involving two steps:

1. Use `STAR` to align reads to the genome to facilitate the generation of QC metrics for individual samples.
2. Use `RSEM` to perform expression quantification, leveraging its statistical model for handling uncertainty in converting read origins to counts.

## Summary

1. There are two levels of uncertainty when producing expression estimates from fastq files: assigning reads to a transcript of origin, and converting read assignments to counts.
2. Read alignment is computationally expensive, but can be important if extended quality checks on individual RNA-seq libraries are likely to be important.
3. Pseudo-alignment is much faster than read alignment, and can be a sensible choice when thousands of samples are being analyzed.
4. Some tools such as `salmon` can use sequence alignments, or run pseudo-alignment directly on fastq files to produce expression estimates.
5. Neither alignment nor pseudo-alignment based quantification tools generate the count matrix required for differential expression analysis. However the `nf-core/rnaseq` workflow (described in the next section) will generate them, and tools like `RSEM` have utilities for creating them from a set of samples.
