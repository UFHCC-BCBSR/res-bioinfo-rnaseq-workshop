# Introduction to Nextflow and the nf-core Community

---

## What is Nextflow?

[Nextflow](https://www.nextflow.io/) is an open-source workflow management system designed specifically for running complex, multi-step bioinformatics pipelines in a **reproducible, portable, and scalable** way.

Before tools like Nextflow existed, running an RNA-seq analysis meant manually executing each step — trimming reads, aligning, quantifying — one at a time, in the right order, on the right files, with the right software versions installed. This was error-prone, difficult to share, and nearly impossible to reproduce exactly.

Nextflow solves this by letting you define your entire analysis as a pipeline: a series of connected computational steps that automatically handle file passing, job scheduling, parallelization, and error recovery.

---

**Why Use Nextflow?**

**Reproducibility**
One of the biggest challenges in bioinformatics is reproducing someone else's (or your own) analysis. Nextflow addresses this through:
- **Containers**: Nextflow integrates natively with **Singularity** and **Docker**, which bundle the exact software versions used in a pipeline into a portable image. This means the same tool versions run on any machine, any cluster, any time.
- **Execution logs**: Every run produces a detailed log of what was executed, when, with what inputs, and what outputs were produced.
- **Version pinning**: Pipelines can specify exact versions of tools and the pipeline itself.

**Portability**
The same Nextflow script can run:
- On your **local laptop** (for testing small datasets)
- On a **SLURM HPC cluster** like UF's HiPerGator
- On **cloud platforms** like AWS, Google Cloud, or Azure

This way even if you change the local configuration, you do not touch the pipeline structure.

**Scalability**
Nextflow automatically parallelizes tasks where possible. For example, if you have 20 samples, Nextflow will trim, align, and quantify all 20 in parallel (subject to available resources), without any extra effort from you. It holds the jobs till the resources are available. It allows flexibility to change time, resources of intermediate steps, skip any if required. 

**Fault Tolerance**
If a job fails halfway through (e.g., due to a memory limit), Nextflow can resume from where it left off using the `-resume` flag, without rerunning completed steps.

---

**How Nextflow Works: A Conceptual Overview**


Each box is a **process**. The arrows are **channels** carrying files. Nextflow figures out which processes can run simultaneously and submits them as independent jobs to SLURM.

You, as the user, only need to provide the starting inputs and the pipeline takes care of the rest.




## Introduction to nf-core
nf-core is a community-driven, open-source project that provides a curated collection of high-quality, peer-reviewed Nextflow pipelines for bioinformatics.

Treasure of pipelines can be found here: https://nf-co.re/pipelines/


---

**Running Nextflow: Basic Syntax**

```bash
nextflow run <pipeline> \
    --input <samplesheet> \
    --outdir <output_directory> \
    -profile <profile> \
    -c <config_file> \
    -resume
```

Parameters starting with -- (double dash) are pipeline-specific parameters defined by the pipeline developer (e.g., --input, --outdir).
Parameters starting with - (single dash) are Nextflow engine parameters (e.g., -profile, -resume, -c).

## Common Pipeline Errors

**1. Memory or Time Limit Exceeded (Exit status 137 or 140 or similar)**
Jobs fail with exit code 137 (killed by OOM), 140 (time exceeded), or similar.

Fix: Increase the memory/time limits in your config file:

```
process {
    withName : 'NFCORE_RNASEQ:RNASEQ:DUPRADAR' 
    memory = 12.GB 
    time   = 8.h
    maxRetries = 3
}
```

**2. Missing input files**

A file path in your sample sheet or parameters does not exist. It could be a typo in the file path of relative paths are incorrect.

Fix: Always verify the paths before running a pipeline.

```bash
ls -lh /path/to/your/fastq/sample1_R1.fastq.gz
```

**3. Invalid input files**

Another common error is providing input files in invalid format. A simple extra tab or a comma, missing column, misspelled column header can cause validation failures. The genome files such as the .gtf or the fasta files are recommended to be in a certain format as available from the sources.

Fix: Use templates from the websites, refrain from manually tampering the input files. 


**4. -resume Does Not Resume the Pipeline**

Nextflow is rerunning steps that were already completed.

Potential causes:

The work/ directory was deleted or moved
Input files changed (even modification timestamps can invalidate the cache)
You are running from a different launch directory

Fix: Always run Nextflow from the same directory as the previous run, and never delete the work/ directory until you are done. You can inspect and clean up older failed runs using the 'nextflow clean' command. 

## References & Citations

- https://training.nextflow.io/2.0/
- https://training.nextflow.io/2.0/basic_training/rnaseq_pipeline/
- https://nf-co.re/docs/usage/troubleshooting/basics
- https://nf-co.re/pipelines/

If you use nf-core/rnaseq for your analysis, please cite it using the following doi:10.5281/zenodo.1400710

You can cite the nf-core publication as follows:

The nf-core framework for community-curated bioinformatics pipelines.

Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.

Nat Biotechnol. 2020 Feb 13. doi: 10.1038/s41587-020-0439-x.


