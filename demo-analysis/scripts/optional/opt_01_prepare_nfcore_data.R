#!/usr/bin/env Rscript
# ==============================================================================
# Prepare RNA-seq Data from nf-core/rnaseq Pipeline Output
# ==============================================================================
# This script takes the output from nf-core/rnaseq pipeline (STAR + RSEM) and
# prepares it for differential expression analysis with limma-voom
#
# Author: [Your Name]
# Date: [Date]
# ==============================================================================

library(tidyverse)
library(here)

# Optional: For converting Ensembl IDs to gene symbols
# Install with: BiocManager::install("org.Hs.eg.db")  # Human
#               BiocManager::install("org.Mm.eg.db")  # Mouse
# If not installed, script will use Ensembl IDs as gene names

# ==============================================================================
# Configuration
# ==============================================================================

# Set paths - MODIFY THESE FOR YOUR DATA
# INPUT: nf-core results directory (EXTERNAL - absolute path required)
# This is the shared workshop data location on HiPerGator
# ATTENDEES: Update this to the path provided by instructors
nfcore_results_dir <- "/blue/bioinf_workshop/share/nfcore_rnaseq_output/"  

# OUTPUT: Your cloned workshop repo (using here() for portability)
# This will automatically put processed data in YOUR repo's data/ directory
output_dir <- here("demo-analysis", "output/optional/")

# INPUT: Sample metadata created during workshop setup
sample_metadata_file <- here("demo-analysis", "data", "metadata", "sample_metadata.csv")

# Show configuration for verification
cat("===========================================\n")
cat("Data Preparation Configuration\n")
cat("===========================================\n")
cat("Reading nf-core output from:", nfcore_results_dir, "\n")
cat("Writing processed data to:", output_dir, "\n")
cat("Project root (from here()):", here(), "\n")
cat("===========================================\n\n")

# Create output directory if it doesn't exist
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# ==============================================================================
# Function Definitions
# ==============================================================================

#' Find a file in nf-core results directory
find_nfcore_file <- function(results_dir, pattern, subdir = NULL) {
  search_dir <- if (!is.null(subdir)) {
    file.path(results_dir, subdir)
  } else {
    results_dir
  }
  
  if (!dir.exists(search_dir)) {
    warning(paste("Directory does not exist:", search_dir))
    return(NULL)
  }
  
  files <- list.files(search_dir, pattern = pattern, 
                      full.names = TRUE, recursive = TRUE)
  
  if (length(files) == 0) {
    warning(paste("No files found matching pattern:", pattern))
    return(NULL)
  }
  
  if (length(files) > 1) {
    warning(paste("Multiple files found, using first:", files[1]))
  }
  
  return(files[1])
}

#' Extract sample names from RSEM count matrix column names
extract_sample_names <- function(colnames) {
  samples <- colnames[!colnames %in% c("gene_id", "transcript_id(s)", "gene_name")]
  return(samples)
}

# ==============================================================================
# Main Data Loading
# ==============================================================================
cat("========================================\n")
cat("nf-core/rnaseq Data Preparation\n")
cat("========================================\n\n")

# ------------------------------------------------------------------------------
# 1. Load RSEM Gene Counts
# ------------------------------------------------------------------------------
cat("Step 1: Loading RSEM gene counts...\n")

# nf-core/rnaseq with RSEM produces several merged files:
#   - rsem.merged.gene_counts.tsv               <- WE WANT THIS ONE (raw expected counts)
#   - rsem.merged.gene_counts_scaled.tsv        (scaled by transcript length)
#   - rsem.merged.gene_counts_length_scaled.tsv (additional scaling)
#   - rsem.merged.gene_lengths.tsv              (transcript length information)
# For DE analysis with limma-voom or DESeq2, we need the RAW expected counts

counts_file <- find_nfcore_file(nfcore_results_dir, 
                                "rsem\\.merged\\.gene_counts\\.tsv$",
                                subdir = "star_rsem")

if (is.null(counts_file)) {
  counts_file <- find_nfcore_file(nfcore_results_dir, 
                                  "rsem\\.merged\\.gene_counts\\.tsv$")
}

if (is.null(counts_file)) {
  stop("ERROR: Could not find RSEM merged gene counts file!\n",
       "Expected location: star_rsem/rsem.merged.gene_counts.tsv\n",
       "Please check your nf-core results directory path.")
}

cat("  Found counts file:", counts_file, "\n")

if (grepl("scaled", counts_file, ignore.case = TRUE)) {
  stop("ERROR: Found a SCALED counts file instead of raw counts!\n",
       "  File: ", counts_file, "\n",
       "  For DE analysis, we need: rsem.merged.gene_counts.tsv (raw expected counts)\n",
       "  NOT the scaled variants (_scaled.tsv or _length_scaled.tsv)")
}

counts_raw <- read.table(counts_file, 
                         header = TRUE, 
                         sep = "\t",
                         check.names = FALSE,
                         stringsAsFactors = FALSE)

cat("  Dimensions:", nrow(counts_raw), "genes x", 
    ncol(counts_raw) - 2, "samples\n")

cat("\n  Preview of counts data:\n")
print(head(counts_raw[, 1:min(5, ncol(counts_raw))], 3))

# ------------------------------------------------------------------------------
# 2. Process Counts Matrix
# ------------------------------------------------------------------------------
cat("\nStep 2: Processing counts matrix...\n")

if (!"gene_id" %in% colnames(counts_raw)) {
  stop("ERROR: Expected column 'gene_id' not found!")
}

cat("  Columns found:", paste(head(colnames(counts_raw), 5), collapse = ", "), "...\n")

if ("transcript_id(s)" %in% colnames(counts_raw)) {
  cat("  Removing 'transcript_id(s)' column (gene-level analysis)\n")
  counts_raw <- counts_raw %>% dplyr::select(-`transcript_id(s)`)
}

sample_names <- extract_sample_names(colnames(counts_raw))
cat("  Detected", length(sample_names), "samples:\n")
cat("  ", paste(head(sample_names, 10), collapse = ", "))
if (length(sample_names) > 10) {
  cat(", ... (", length(sample_names) - 10, " more)\n", sep = "")
} else {
  cat("\n")
}

cat("\n  Processing gene identifiers...\n")

if (any(grepl("\\|", counts_raw$gene_id))) {
  cat("  Gene symbols detected in gene_id column (format: ID|SYMBOL)\n")
  counts_raw$gene_name <- sapply(strsplit(counts_raw$gene_id, "\\|"), function(x) {
    if (length(x) > 1) x[2] else x[1]
  })
} else {
  cat("  No gene symbols found in gene_id column\n")
  cat("  Attempting to extract symbols from Ensembl IDs using annotation packages...\n")
  
  sample_id <- counts_raw$gene_id[1]
  
  if (grepl("^ENSG", sample_id)) {
    organism <- "human"
    if (requireNamespace("org.Hs.eg.db", quietly = TRUE)) {
      library(org.Hs.eg.db)
      gene_symbols <- AnnotationDbi::mapIds(org.Hs.eg.db,
                                            keys = counts_raw$gene_id,
                                            column = "SYMBOL",
                                            keytype = "ENSEMBL",
                                            multiVals = "first")
      counts_raw$gene_name <- ifelse(is.na(gene_symbols), counts_raw$gene_id, gene_symbols)
      cat("  Successfully mapped", sum(!is.na(gene_symbols)), "genes to symbols using org.Hs.eg.db\n")
    } else {
      cat("  WARNING: org.Hs.eg.db not installed. Install with:\n")
      cat("    BiocManager::install('org.Hs.eg.db')\n")
      cat("  Using Ensembl IDs as gene names for now\n")
      counts_raw$gene_name <- counts_raw$gene_id
    }
  } else if (grepl("^ENSMUSG", sample_id)) {
    organism <- "mouse"
    if (requireNamespace("org.Mm.eg.db", quietly = TRUE)) {
      library(org.Mm.eg.db)
      gene_symbols <- AnnotationDbi::mapIds(org.Mm.eg.db,
                                            keys = counts_raw$gene_id,
                                            column = "SYMBOL",
                                            keytype = "ENSEMBL",
                                            multiVals = "first")
      counts_raw$gene_name <- ifelse(is.na(gene_symbols), counts_raw$gene_id, gene_symbols)
      cat("  Successfully mapped", sum(!is.na(gene_symbols)), "genes to symbols using org.Mm.eg.db\n")
    } else {
      cat("  WARNING: org.Mm.eg.db not installed. Install with:\n")
      cat("    BiocManager::install('org.Mm.eg.db')\n")
      cat("  Using Ensembl IDs as gene names for now\n")
      counts_raw$gene_name <- counts_raw$gene_id
    }
  } else {
    cat("  Could not determine organism from gene_id format\n")
    cat("  Using gene_id as gene_name\n")
    counts_raw$gene_name <- counts_raw$gene_id
  }
}

n_duplicates <- sum(duplicated(counts_raw$gene_name))
if (n_duplicates > 0) {
  cat("  WARNING:", n_duplicates, "duplicate gene symbols found\n")
  cat("  Making unique by appending gene_id suffix\n")
  dup_names <- counts_raw$gene_name[duplicated(counts_raw$gene_name) | 
                                      duplicated(counts_raw$gene_name, fromLast = TRUE)]
  for (dup in unique(dup_names)) {
    idx <- which(counts_raw$gene_name == dup)
    if (length(idx) > 1) {
      counts_raw$gene_name[idx] <- paste0(dup, "_", counts_raw$gene_id[idx])
    }
  }
}

counts_matrix <- counts_raw %>%
  dplyr::select(gene_name, all_of(sample_names)) %>%
  column_to_rownames("gene_name")

gene_annotation <- counts_raw %>%
  dplyr::select(gene_id, gene_name) %>%
  distinct()

cat("  Final matrix:", nrow(counts_matrix), "genes x", 
    ncol(counts_matrix), "samples\n")

# ------------------------------------------------------------------------------
# 3. Load Sample Metadata
# ------------------------------------------------------------------------------
cat("\nStep 3: Loading sample metadata...\n")

if (!file.exists(sample_metadata_file)) {
  stop("ERROR: sample_metadata.csv not found!\n",
       "Expected location: demo-analysis/data/metadata/sample_metadata.csv\n",
       "Please follow the setup instructions to create this file before running this script.")
}

sample_metadata <- read.csv(sample_metadata_file, stringsAsFactors = FALSE)

# Reorder to match counts matrix
sample_metadata <- sample_metadata[match(sample_names, sample_metadata$sample), ]
sample_metadata <- sample_metadata[!is.na(sample_metadata$sample), ]

cat("  Metadata loaded successfully\n")
cat("  Samples:", nrow(sample_metadata), "\n")
cat("  Groups:", paste(unique(sample_metadata$group), collapse = ", "), "\n")

# ------------------------------------------------------------------------------
# 4. Quality Checks
# ------------------------------------------------------------------------------

cat("\nStep 4: Quality checks...\n")

# Check library sizes
lib_sizes <- colSums(counts_matrix)
cat("  Library size range:", 
    format(min(lib_sizes), big.mark = ","), "to", 
    format(max(lib_sizes), big.mark = ","), "reads\n")
cat("  Mean library size:", 
    format(mean(lib_sizes), big.mark = ","), "reads\n")

# Flag low library sizes
low_threshold <- 5e6  # 5 million reads
low_libs <- lib_sizes < low_threshold
if (any(low_libs)) {
  cat("  WARNING: Low library sizes detected (<5M reads):\n")
  cat("    ", paste(names(lib_sizes)[low_libs], collapse = ", "), "\n")
}

# Count genes with zero counts across all samples
zero_genes <- rowSums(counts_matrix) == 0
cat("  Genes with zero counts in all samples:", sum(zero_genes), "\n")

# Count genes expressed in at least one sample
expressed_genes <- rowSums(counts_matrix > 0) > 0
cat("  Genes expressed in at least one sample:", sum(expressed_genes), "\n")

# ------------------------------------------------------------------------------
# 5. Extract Additional QC Information (Optional)
# ------------------------------------------------------------------------------

cat("\nStep 5: Checking for additional QC files...\n")

# Look for MultiQC data
multiqc_file <- find_nfcore_file(nfcore_results_dir, 
                                 "multiqc_data\\.json",
                                 subdir = "multiqc")

if (!is.null(multiqc_file)) {
  cat("  Found MultiQC report\n")
  cat("  Location:", multiqc_file, "\n")
  cat("  Tip: Review the MultiQC HTML report for detailed QC metrics\n")
}

# Look for STAR alignment stats
star_stats <- find_nfcore_file(nfcore_results_dir,
                               "Log\\.final\\.out",
                               subdir = "star_rsem")

if (!is.null(star_stats)) {
  cat("  Found STAR alignment statistics\n")
}

# ------------------------------------------------------------------------------
# 6. Save Processed Data
# ------------------------------------------------------------------------------

cat("\nStep 6: Saving processed data files...\n")

# Save count matrix
counts_output <- file.path(output_dir, "rsem.merged.gene_counts.tsv")
write.table(counts_matrix, 
            counts_output,
            sep = "\t",
            quote = FALSE,
            row.names = TRUE,
            col.names = NA)
cat("  ✓ Count matrix saved:", counts_output, "\n")

# Save sample metadata
metadata_output <- file.path(output_dir, "sample_info.tsv")
write.table(sample_metadata,
            metadata_output,
            sep = "\t",
            quote = FALSE,
            row.names = FALSE)
cat("  ✓ Sample metadata saved:", metadata_output, "\n")

# Save gene annotation
annotation_output <- file.path(output_dir, "gene_annotation.tsv")
write.table(gene_annotation,
            annotation_output,
            sep = "\t",
            quote = FALSE,
            row.names = FALSE)
cat("  ✓ Gene annotation saved:", annotation_output, "\n")

# Create a data summary file
summary_file <- file.path(output_dir, "data_summary.txt")
sink(summary_file)
cat("RNA-seq Data Summary\n")
cat("====================\n\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
cat("Source:\n")
cat("  nf-core results:", nfcore_results_dir, "\n")
cat("  Counts file:", counts_file, "\n\n")
cat("Data Dimensions:\n")
cat("  Genes:", nrow(counts_matrix), "\n")
cat("  Samples:", ncol(counts_matrix), "\n\n")
cat("Sample Names:\n")
cat("  ", paste(colnames(counts_matrix), collapse = ", "), "\n\n")
cat("Library Sizes:\n")
print(summary(lib_sizes))
cat("\nMetadata Columns:\n")
cat("  ", paste(colnames(sample_metadata), collapse = ", "), "\n\n")
cat("Experimental Design:\n")
if ("group" %in% colnames(sample_metadata)) {
  print(table(sample_metadata$group))
}
sink()
cat("  ✓ Data summary saved:", summary_file, "\n")

# ------------------------------------------------------------------------------
# 7. Create README
# ------------------------------------------------------------------------------

readme_file <- file.path(output_dir, "README.txt")
sink(readme_file)
cat("RNA-seq Workshop Data Files\n")
cat("============================\n\n")
cat("This directory contains processed data from the nf-core/rnaseq pipeline,\n")
cat("ready for differential expression analysis.\n\n")
cat("Files:\n")
cat("------\n")
cat("1. rsem.merged.gene_counts.tsv\n")
cat("   - Gene-level count matrix from RSEM\n")
cat("   - Rows: genes (gene symbols or Ensembl IDs as row names)\n")
cat("   - Columns: samples\n")
cat("   - Values: expected counts (suitable for limma-voom or DESeq2)\n")
cat("   - Note: Gene symbols used when available; Ensembl IDs if not\n\n")
cat("2. sample_info.tsv\n")
cat("   - Sample metadata with experimental design information\n")
cat("   - Must include 'sample' column matching count matrix columns\n")
cat("   - Should include grouping variables for analysis\n\n")
cat("3. gene_annotation.tsv\n")
cat("   - Mapping between Ensembl IDs and gene symbols\n")
cat("   - Columns: gene_id (Ensembl), gene_name (symbol or Ensembl if no symbol)\n\n")
cat("4. data_summary.txt\n")
cat("   - Summary statistics about the dataset\n\n")
cat("Usage:\n")
cat("------\n")
cat("Load these files in R for differential expression analysis:\n\n")
cat("  counts <- read.table('rsem.merged.gene_counts.tsv', \n")
cat("                       header=TRUE, row.names=1)\n")
cat("  sample_info <- read.table('sample_info.tsv', \n")
cat("                            header=TRUE)\n\n")
cat("Then proceed with edgeR/limma-voom analysis as shown in the workshop.\n\n")
cat("For questions, contact: [your email]\n")
sink()

cat("  ✓ README saved:", readme_file, "\n")

# ==============================================================================
# Final Summary
# ==============================================================================

cat("\n========================================\n")
cat("Data Preparation Complete!\n")
cat("========================================\n\n")
cat("Output directory:", output_dir, "\n")
cat("Files created:\n")
cat("  1. rsem.merged.gene_counts.tsv (", 
    nrow(counts_matrix), " genes x ", ncol(counts_matrix), " samples)\n", sep = "")
cat("  2. sample_info.tsv (", nrow(sample_metadata), " samples)\n", sep = "")
cat("  3. gene_annotation.tsv (", nrow(gene_annotation), " genes)\n", sep = "")
cat("  4. data_summary.txt\n")
cat("  5. README.txt\n\n")

cat("Next steps:\n")
cat("  1. Review the data_summary.txt file\n")
cat("  2. Check the MultiQC report for quality metrics\n")
cat("  3. Open RStudio and load the count matrix and sample info\n")
cat("  4. Begin differential expression analysis!\n\n")

# Optional: Create a simple QC plot
if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)
  
  cat("Creating library size QC plot...\n")
  
  lib_size_df <- data.frame(
    sample = names(lib_sizes),
    lib_size = lib_sizes / 1e6  # Convert to millions
  )
  
  if ("group" %in% colnames(sample_metadata)) {
    lib_size_df <- left_join(lib_size_df, 
                             sample_metadata %>% dplyr::select(sample, group),
                             by = "sample")
    
    p <- ggplot(lib_size_df, aes(x = sample, y = lib_size, fill = group)) +
      geom_col() +
      labs(title = "Library Sizes by Sample",
           x = "Sample",
           y = "Library Size (Millions of Reads)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  } else {
    p <- ggplot(lib_size_df, aes(x = sample, y = lib_size)) +
      geom_col(fill = "steelblue") +
      labs(title = "Library Sizes by Sample",
           x = "Sample",
           y = "Library Size (Millions of Reads)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  }
  
  ggsave(file.path(output_dir, "library_sizes.png"), 
         plot = p, width = 8, height = 5)
  cat("  ✓ QC plot saved: library_sizes.png\n")
}

cat("\n✓ All done!\n\n")

