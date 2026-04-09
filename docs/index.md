<p style="font-size: 0.9em; color: grey;">UF Health Cancer Institute Biostatistics and Computational Biology Shared Resource</p>

# Bioinformatics Workshop: Basics of Bulk RNA-Seq Analysis

**Audience:** Trainees, staff, and faculty in the UF Health Cancer Institute community with beginner to intermediate experience with bioinformatics analysis.  

**Hosted by:** [UF Health Cancer Institute Biostatistics and Computational Biology Bioinformatics Unit](https://cancer.ufl.edu/research/shared-resources/biostatistics-computational-biology-shared-resource/bioinformatics-unit/)

---

!!! danger "Do this now if you haven't already"

    **Everyone:** [Create a GitHub account](https://github.com/signup) if you don't have one.

    **Windows users only:** [Install Git for Windows](https://gitforwindows.org/) to get a Linux-style terminal.

---

## Overview

This workshop guides participants through a complete bulk RNA-seq analysis workflow, from raw sequencing reads to biological interpretation. To facilitate this for all participants regardless of previous experience, we also include modules on basics of bash, Hipergator, and R.

As a worked example we use a published mouse melanoma dataset examining the transcriptional effects of PRMT7 knockdown in B16.F10 cells, with and without IFN-γ treatment. The methods covered apply to any bulk RNA-seq experiment regardless of organism or experimental design.

---

## Workshop Modules

| Time | # | Module | Description |
|------|---|--------|-------------|
| 10:15 AM | 1 | [Command Line Basics](01_command-line-basics/command-line-basics.md) | Navigating the terminal, essential commands for bioinformatics |
| | 2 | [HiPerGator Basics](02_hipergator-basics/hipergator-basics.md) | Logging in, storage, loading software, and submitting SLURM jobs |
| | 3 | [R Basics](05_r-basics/r-basics.md) | RStudio on HiPerGator, reading and writing files, installing packages |
| | 4 | [AI Chatbot Tips](06_ai-chatbot/ai-chatbot.md) | How to use AI tools effectively and responsibly for bioinformatics |
| 11:45 AM | 5 | [Preprocessing](03_preprocessing/quantification.md) | Expression quantification concepts and the nf-core/rnaseq workflow |
| 🍽️ 12:30 PM | — | **Lunch Break** | |
| 1:00 PM | 6 | [Differential Expression](04_differential-expression/overview.md) | Statistical testing with limma-voom in R |
| | 7 | [Visualization](04_differential-expression/visualization.md) | Volcano plots, heatmaps, and gene expression plots |
| | 8 | [Pathway Analysis](04_differential-expression/pathway-analysis.md) | GO and KEGG enrichment analysis with clusterProfiler |
| 2:00 PM | 9 | [Demo Analysis](04_differential-expression/workshop_setup.md) | Hands-on end-to-end differential expression analysis |
| 3:30 PM | — | **Wrap-up & Questions** | |

---

## Prerequisites

The only software you need to install before the workshop is a terminal application:

- **Mac:** Terminal is built in — no installation needed
- **Windows:** Install a Linux-style terminal like [Git Bash](https://gitforwindows.org/) or [MobaXterm](https://mobaxterm.mobatek.net/download.html)

HiPerGator accounts will be set up for all participants in advance — you do not need to do anything. Details will be sent by email before the workshop.

---

## Key Resources

A curated, annotated list of references and tools used throughout this workshop can be found in [annotated-resources.txt](annotated-resources.txt).

---

## How to Use This Workshop

Each module page provides conceptual background, code snippets, and links to further reading. The hands-on analysis is done through prepared files and an interactive R notebook which will be made available on Github during the workshop. We recommend reading through each module page before the workshop session and referring back to it during the hands-on portion.

---

## Contact

Questions? Contact the [UF Health Cancer Institute Bioinformatics team](mailto:UFHCC-BCB-SR@ufl.edu).

