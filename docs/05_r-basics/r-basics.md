# R Basics

R is a programming language designed for statistical computing and data analysis. It is the language we use for differential expression analysis in this workshop. This section covers the essentials you need to get started — if you want to go deeper, we recommend the [R for Data Science](https://r4ds.hadley.nz/) book, which is freely available online.

## Running RStudio on HiPerGator

For this workshop we run RStudio through HiPerGator rather than on your local computer, so that everyone has access to the same software environment and data. We use RStudio Server, which runs on a compute node and is accessed through your web browser.

### Starting an RStudio Server Session

> **Warning:** RStudio Server will change the permissions on your working directory to 777, which makes files visible to other users. Never run it from your `/home` directory or the top level of your `/blue` directory. Always run it from a directory well inside your personal storage, e.g. `/blue/[training-group]/username/rnaseq-workshop/`.

First, create a job script. Save the following as `rserver.sh` in your working directory:

```bash
#!/bin/bash
#SBATCH --job-name=rserver
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=8gb
#SBATCH --time=48:00:00
#SBATCH --output=rserver_%j.log
#SBATCH --partition=[training-partition]
#SBATCH --account=[training-group]
#SBATCH --qos=[training-group]

module purge; module load R
rserver
```

Submit the job:

```
$ sbatch rserver.sh
Submitted batch job 12345678
```

Once the job starts, check the log file for connection instructions:

```
$ cat rserver_12345678.log
Starting rserver on port 37546 in the /blue/training-group/username/rnaseq-workshop directory.
Create an SSH tunnel with:
ssh -N -L 8080:c12345a-s42.ufhpc:37546 username@hpg.rc.ufl.edu
Then, open in the local browser:
http://localhost:8080
```

Open a new terminal on your local computer and run the `ssh` command from the log file. The terminal will appear to hang — this is normal, leave it running.

Then open [http://localhost:8080](http://localhost:8080) in your browser. You should see the RStudio interface.

## The RStudio Interface

RStudio has four panels:

- **Source** (top left): where you write and save R scripts
- **Console** (bottom left): where code is executed and output is printed
- **Environment** (top right): shows all objects currently loaded in memory
- **Files / Plots / Help** (bottom right): file browser, plot viewer, and help documentation

You can type code directly in the Console to run it immediately, or write it in the Source panel and run it with `Ctrl+Enter` (one line) or `Ctrl+Shift+Enter` (entire script).

## R Basics

### Installing and Loading Packages

R packages extend the base language with additional functions. You only need to install a package once, but you need to load it every time you start a new R session:

```r
# Install a package (only do this once)
install.packages("tidyverse")

# Install Bioconductor packages
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("limma")

# Load a package (do this every session)
library(tidyverse)
library(limma)
```

### R Versions

Different R versions can have different package compatibility. On HiPerGator you can check your R version with:

```r
R.version
```

For this workshop we use the version loaded by `module load R`. If you install R on your own computer, we recommend using the same major version to avoid compatibility issues.

### Objects and Assignment

In R, you store data in objects using the assignment operator `<-`:

```r
x <- 42
name <- "HiPerGator"
counts <- c(100, 200, 300, 400)
```

You can see all objects in your current session in the Environment panel, or with:

```r
ls()
```

### Reading Files

The most common file types you will encounter in this workshop:

```r
# Tab-separated files (.tsv)
sample_info <- read.table("dme_elev_samples.tsv", header=TRUE, sep="\t")

# Comma-separated files (.csv)
sample_info <- read.csv("sample_info.csv", header=TRUE)

# Both of the above can also be read with tidyverse
library(tidyverse)
sample_info <- read_tsv("dme_elev_samples.tsv")
sample_info <- read_csv("sample_info.csv")
```

To quickly check what a file looks like after reading it in:

```r
head(sample_info)       # first 6 rows
dim(sample_info)        # number of rows and columns
colnames(sample_info)   # column names
str(sample_info)        # structure and data types
```

### Saving Objects to Files

To save a data frame or results table to a file:

```r
# Save as tab-separated
write.table(results, file="de_results.tsv", sep="\t", row.names=TRUE, quote=FALSE)

# Save as CSV
write.csv(results, file="de_results.csv", row.names=TRUE)

# Save as tidyverse TSV
write_tsv(results, file="de_results.tsv")
```

To save an R object so you can reload it later without rerunning your analysis:

```r
# Save
saveRDS(DGE, file="dge_object.rds")

# Reload
DGE <- readRDS("dge_object.rds")
```

## Getting Help

To get help on any function in R:

```r
?read.table
help(lmFit)
```

The Help panel in RStudio will display the documentation. You can also search for functions in the Help panel search box.
