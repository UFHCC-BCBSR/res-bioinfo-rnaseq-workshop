# R Basics

R is a programming language designed for statistical computing and data analysis. It is the language we use for differential expression analysis in this workshop. This section covers the essentials you need to get started — if you want to go deeper, we recommend the [R for Data Science](https://r4ds.hadley.nz/) book, which is freely available online.

## Running RStudio on HiPerGator

For this workshop we run RStudio through HiPerGator rather than on your local computer, so that everyone has access to the same software environment and data. We use RStudio Server, which runs on a compute node and is accessed through your web browser.

!!! warning "Run RStudio Server from inside your working directory"
    RStudio Server will change the permissions on your working directory to 777, which makes files visible to other users. Never run it from your `/home` directory or the top level of your `/blue` directory. Always run it from a directory well inside your personal storage, e.g. `/blue/bioinf_workshop/$USER/`.

First, navigate to your workshop directory and create the job script:

<div class="bash-block">
```bash
cd /blue/bioinf_workshop/$USER
nano rserver.sbatch
```
</div>

??? tip "Need a nano refresher?"
    - Type or paste your content
    - `Ctrl+O` then `Enter` to save
    - `Ctrl+X` to exit

Paste the following into nano, save, and exit:

<div class="bash-block">
```bash
#!/bin/bash
#SBATCH --job-name=rserver
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8gb
#SBATCH --time=02:00:00
#SBATCH --output=rserver_%j.log
#SBATCH --account=bioinf_workshop
#SBATCH --qos=bioinf_workshop
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=$USER@ufl.edu

module purge; module load R
rserver
```
</div>

Submit the job:

<div class="bash-block">
```bash
sbatch rserver.sbatch
```
</div>

> `Submitted batch job 12345678`

Check the status until it shows `R` (running):

<div class="bash-block">
```bash
squeue -u $USER
```
</div>

Once running, check the log file for connection instructions (replace `12345678` with your job ID):

<div class="bash-block">
```bash
cat rserver_12345678.log
```
</div>

> Starting rserver on port 37546 in the /blue/bioinf_workshop/username/ directory.  
> Create an SSH tunnel with:  
> `ssh -N -L 8080:c12345a-s42.ufhpc:37546 username@hpg.rc.ufl.edu`  
> Then, open in the local browser:  
> `http://localhost:8080`

!!! info "What is all that other stuff in the log?"
    You will see a lot of RStudio Server startup messages after the SSH tunnel instructions — including an `ERROR` line about a missing config file. This is normal and can be ignored. If RStudio loaded in your browser, everything is working correctly.

Open a **new terminal on your local computer** and run the `ssh` command from the log file. The terminal will appear to hang — this is normal, leave it running. Then open [http://localhost:8080](http://localhost:8080) in your browser and you should see the RStudio interface.

## The RStudio Interface

RStudio has four panels:

- **Source** (top left): where you write and save R scripts
- **Console** (bottom left): where code is executed and output is printed
- **Environment** (top right): shows all objects currently loaded in memory
- **Files / Plots / Help** (bottom right): file browser, plot viewer, and help documentation

You can type code directly in the Console to run it immediately, or write it in the Source panel and run it with `Ctrl+Enter` (one line) or `Ctrl+Shift+Enter` (entire script).

## R Basics

### R Packages

R packages extend the base language with additional functions. You only need to install a package once per library location, but you need to load it with `library()` every time you start a new R session — `library()` simply tells R to make that package's functions available in your current session.

### Where Do Packages Live?

Before installing anything, it's worth understanding what "installing a package" actually means. When you run `install.packages()`, R downloads the package and copies its files into a directory on your filesystem — this is your **package library**. You can see where R is currently looking for packages by running this in the RStudio console:

<div class="r-block">
```r
.libPaths()
```
</div>

> `[1] "/home/username/R/libs"`  
> `[2] "/apps/R/4.3/library"`

R searches these paths in order — the first one is where new packages get installed by default. This matters a lot for reproducibility: if you install packages into a shared or system directory, other users or future sessions may get different versions, or your packages may be overwritten when R is updated on the cluster.

For this workshop, we will create a dedicated library folder inside your workshop directory so your packages are isolated and you can see exactly where they live. Run this in your HiPerGator terminal:

<div class="bash-block">
```bash
mkdir -p /blue/bioinf_workshop/$USER/R_libs
```
</div>

??? tip "Where do I run bash vs. R commands?"
    Throughout this workshop you will see two types of code blocks — green **HiPerGator Terminal** blocks are bash commands that run in the terminal where you SSH into HiPerGator, and blue **RStudio Console** blocks are R commands that run in RStudio. If you are ever unsure, the colored label at the top of each block tells you exactly where to run it.

Now tell R to use it by adding it to the front of your library path:

<div class="r-block">
```r
.libPaths(c(paste0("/blue/bioinf_workshop/", Sys.getenv("USER"), "/R_libs"), .libPaths()))
```
</div>

Verify it worked:

<div class="r-block">
```r
.libPaths()
```
</div>

> `[1] "/blue/bioinf_workshop/username/R_libs"`  
> `[2] "/home/username/R/libs"`  
> `[3] "/apps/R/4.3/library"`

Your workshop directory is now first, so any packages you install will go there.

??? info "Making this permanent with .Rprofile"
    Running `.libPaths()` in the console only applies to your current session. To make it permanent, you can add it to your `~/.Rprofile` file, which R reads automatically at startup. Note that `$USER` does not expand in R — we use `Sys.getenv("USER")` instead:

    <div class="bash-block">
    ```bash
    echo '.libPaths(c(paste0("/blue/bioinf_workshop/", Sys.getenv("USER"), "/R_libs"), .libPaths()))' >> ~/.Rprofile
    ```
    </div>

    Be cautious with this on a shared cluster — if you later work on a different project you may want a different library path.

### Installing and Loading Packages

To install and load a CRAN package:

<div class="r-block">
```r
install.packages("tidyverse")
```
</div>

<div class="r-block">
```r
library(tidyverse)
```
</div>

To install Bioconductor packages:

<div class="r-block">
```r
if (!require("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("limma")
```
</div>

<div class="r-block">
```r
library(limma)
```
</div>

If it asks `Update all/some/none? [a/s/n]:` you can type `n` and press Enter.

After installing, you can verify the packages are in your workshop library by checking in your HiPerGator terminal:

<div class="bash-block">
```bash
ls /blue/bioinf_workshop/$USER/R_libs
```
</div>

??? tip "Do I need to reinstall packages every session?"
    No — `install.packages()` only needs to be run once per library location. The package files stay on disk and `library()` just loads them into memory for that session.

    However, if your `.libPaths()` changes between sessions — for example if you start R from a different directory, use a different job script, or your `.Rprofile` isn't set up — R may not find your previously installed packages. This is one of the most common sources of "it worked last time" confusion on HPC systems. If you get an error like `there is no package called 'tidyverse'`, the first thing to check is `.libPaths()` and whether your workshop library path is listed.

### Objects and Assignment

In R, you store data in objects using the assignment operator `<-`. Let's create a few to practice:

<div class="r-block">
```r
x <- 42
name <- "HiPerGator"
counts <- c(100, 200, 300, 400)
```
</div>

You can see all objects in your current session in the Environment panel, or list them with:

<div class="r-block">
```r
ls()
```
</div>

> `[1] "counts" "name"   "x"`

To check the value of an object, just type its name:

<div class="r-block">
```r
x
```
</div>

> `[1] 42`

<div class="r-block">
```r
counts
```
</div>

> `[1] 100 200 300 400`

### R Versions

Different R versions can have different package compatibility. You can check your R version with:

<div class="r-block">
```r
R.version
```
</div>

For this workshop we use the version loaded by `module load R` on HiPerGator. If you install R on your own computer, we recommend using the same major version to avoid compatibility issues.

### Reading Files

Let's create a small practice file to read in. Run this in your HiPerGator terminal:

<div class="bash-block">
```bash
cat > /blue/bioinf_workshop/$USER/practice_samples.tsv << 'EOF'
sample_id	condition	batch
sample1	control	1
sample2	control	1
sample3	treatment	2
sample4	treatment	2
EOF
```
</div>

Now read it into R. We can use `Sys.getenv("USER")` to avoid hardcoding your username:

<div class="r-block">
```r
sample_info <- read.table(
    paste0("/blue/bioinf_workshop/", Sys.getenv("USER"), "/practice_samples.tsv"),
    header=TRUE, sep="\t"
)
```
</div>

Or with tidyverse:

<div class="r-block">
```r
library(tidyverse)
sample_info <- read_tsv(paste0("/blue/bioinf_workshop/", Sys.getenv("USER"), "/practice_samples.tsv"))
```
</div>

To quickly check what a file looks like after reading it in:

<div class="r-block">
```r
head(sample_info)
```
</div>

<div class="r-block">
```r
dim(sample_info)
```
</div>

<div class="r-block">
```r
colnames(sample_info)
```
</div>

<div class="r-block">
```r
str(sample_info)
```
</div>

### Saving Objects to Files

To save a data frame to a file:

<div class="r-block">
```r
write.table(sample_info, file="sample_info_out.tsv", sep="\t", row.names=TRUE, quote=FALSE)
```
</div>

<div class="r-block">
```r
write.csv(sample_info, file="sample_info_out.csv", row.names=TRUE)
```
</div>

To save an R object so you can reload it later without rerunning your analysis:

<div class="r-block">
```r
saveRDS(sample_info, file="sample_info.rds")
```
</div>

<div class="r-block">
```r
sample_info <- readRDS("sample_info.rds")
```
</div>

You can verify the files were created in your HiPerGator terminal:

<div class="bash-block">
```bash
ls /blue/bioinf_workshop/$USER/
```
</div>

## Getting Help

To get help on any function in R, use `?`:

<div class="r-block">
```r
?read.table
```
</div>

The Help panel in RStudio will display the documentation. You can also search for functions directly in the Help panel search box.