
---

## 📄 File 3: `03_quality_control.md`

```markdown
# Quality Control in RNA-Seq: Tools and Interpretation

---

## Why Quality Control Matters

Before trusting any downstream analysis — differential expression, pathway analysis, or otherwise — you need to verify that your raw data and processed outputs meet basic quality standards. Poor-quality RNA-seq data can arise from many sources:

- Degraded RNA at time of library preparation
- Low sequencing depth
- Adapter contamination
- rRNA or DNA contamination
- PCR over-amplification (duplicates)
- Biased coverage (e.g., 3' bias in degraded samples)
- Sample swaps or mislabeling

The `nf-core/rnaseq` pipeline automates QC at every stage and compiles all results into a single **MultiQC report**. This section explains each QC tool, what it measures, and what to look for.

---

## The MultiQC Report: Summary Guide 

[**MultiQC**](https://multiqc.info/) aggregates the output of all QC tools across all samples into a single, interactive HTML report. It is the first place to look after a pipeline run.

### How to Open It

< Add information about using OnDemand to browse files or use scp. Download the html file otherwise it opens as an html>

```bash
# Copy to your local machine and open in a browser
scp username@hpg.rc.ufl.edu:/OUTPUT/star_rsem/multiqc/star_rsem/multiqc_report.html ./
open multiqc_report.html   # macOs
```

The report includes sections for every tool that ran — FastQC, Trim Galore, STAR, Picard, RSeQC, Qualimap, Preseq, and RSEM. Each section shows per-sample metrics and highlights any samples that fall outside expected ranges.


# Tool-by-Tool Guide to Understand MultiQC
