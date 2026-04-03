# HiPerGator Basics

HiPerGator is the University of Florida's high-performance computing (HPC) cluster, managed by UF Research Computing. It gives you access to far more computational power than a personal computer, which is essential for steps like running the nf-core/rnaseq pipeline. This section covers everything you need to know to get started on HiPerGator for this workshop.

For more comprehensive documentation, see the [UF Research Computing docs](https://docs.rc.ufl.edu/).

## Logging In

You connect to HiPerGator via SSH from your terminal. If you haven't set up your terminal yet, see the [Command Line Basics](../01_command-line-basics/command-line-basics.md) section.

```
$ ssh username@hpg.rc.ufl.edu
```

Replace `username` with your GatorLink username. You will be prompted for your password and then a Duo two-factor authentication push. After authenticating you will land on a **login node**, which looks like this:

```
[username@login1 ~]$
```

> **Important:** Login nodes are shared resources for everyone on the cluster. Do not run computationally intensive work on login nodes — this is against HiPerGator policy and can result in account suspension. All real work should be submitted as SLURM jobs.

## The HiPerGator Filesystem

HiPerGator has three main storage locations, each with a different purpose:

| **Location** | **Path** | **Quota** | **Use for** |
|---|---|---|---|
| Home | `/home/username` | 40 GB | Scripts, configuration files, important small files |
| Blue | `/blue/group/username` | Varies | All active research work and data |
| Orange | `/orange/group/username` | Varies | Long-term archival storage |

> **Always run your analyses from `/blue`**. It is a high-performance storage system designed to handle the input/output demands of HPC workloads. `/home` and `/orange` are not suitable for running analyses.

For this workshop, your working directory will be:

```
/blue/[training-group]/username
```

To navigate there:

```
$ cd /blue/[training-group]/username
```

You can check your storage quotas with:

```
$ home_quota
$ blue_quota
$ orange_quota
```

## Open OnDemand

Open OnDemand (OOD) is a web interface for HiPerGator available at [https://ood.rc.ufl.edu](https://ood.rc.ufl.edu). It provides:

- **Files**: A graphical file browser for navigating, uploading, downloading, and editing files on HiPerGator
- **Jobs**: A dashboard for monitoring your running, pending, and recently completed jobs
- **Clusters**: A terminal window in your browser if you prefer not to use SSH

For this workshop, OOD is particularly useful for uploading input files and downloading results to your local computer without needing to use `scp` on the command line.

## Loading Software with Modules

HiPerGator uses a module system to manage software. Software is not available by default — you need to load it first. To search for available software:

```
$ module spider nextflow
```

To load a module:

```
$ module load nextflow
```

To see what modules you currently have loaded:

```
$ module list
```

To unload a module:

```
$ module unload nextflow
```

Some software requires loading a prerequisite module first. `module spider` will tell you if this is the case and what to load.

## Writing and Submitting SLURM Jobs

HiPerGator uses the SLURM scheduler to manage jobs. Rather than running commands directly on the login node, you write a job script that specifies the resources you need and the commands to run, and submit it to the scheduler with `sbatch`.

The key insight is that a SLURM script is just a regular bash script with a block of `#SBATCH` directives at the top that tell the scheduler what resources to allocate. To illustrate this, here is a simple bash script:

```bash
#!/bin/bash

echo "Hello from HiPerGator!"
echo "My username is: $(whoami)"
echo "Today's date is: $(date)"
echo "I am running on node: $(hostname)"
```

You could run this directly on the login node with `bash hello.sh`. Now here is the exact same script as an SLURM job:

```bash
#!/bin/bash
#SBATCH --job-name=hello
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1gb
#SBATCH --time=00:05:00
#SBATCH --partition=[training-partition]
#SBATCH --account=[training-group]
#SBATCH --qos=[training-group]
#SBATCH --output=hello_%j.out
#SBATCH --error=hello_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=username@ufl.edu

echo "Hello from HiPerGator!"
echo "My username is: $(whoami)"
echo "Today's date is: $(date)"
echo "I am running on node: $(hostname)"
```

The only difference is the `#SBATCH` header. Save this as `hello.sh` and submit it:

```
$ sbatch hello.sh
Submitted batch job 12345678
```

When the job completes, check the output log:

```
$ cat hello_12345678.out
Hello from HiPerGator!
My username is: username
Today's date is: Thu Apr  3 10:42:11 EDT 2026
I am running on node: c0709a-s30
```

### Key SLURM Resource Flags

| **Flag** | **Description** |
|---|---|
| `--cpus-per-task` | Number of CPU cores. Only request multiple if your software can use them. |
| `--mem` | Total memory, e.g. `16gb`. If your job exceeds this it will be killed. |
| `--time` | Maximum runtime. Job will be cancelled if it exceeds this. Request ~20% more than you expect. |
| `--partition` | The queue to submit to. Use `[training-partition]` for this workshop. |
| `--account` and `--qos` | Must match your group. Use `[training-group]` for this workshop. |

## Monitoring Jobs

To check the status of your jobs:

```
$ squeue -u username
```

The `ST` column shows job state: `PD` = pending, `R` = running, `CG` = completing.

To see resource usage for your group:

```
$ slurmInfo
```

To cancel a job:

```
$ scancel 12345678
```

To see a summary of recent completed jobs:

```
$ sacct
```

## Checking Job Logs

When you submit a job, SLURM writes output and error messages to log files (named by job ID by default, e.g. `12345678.out` and `12345678.err`). These are the first place to look if something goes wrong.

```
$ cat 12345678.out          # view full output log
$ tail -f 12345678.out      # follow the log in real time as the job runs
$ tail 12345678.err         # check the last few lines of the error log
```

`tail -f` is particularly useful for monitoring a running job — it will keep printing new lines as they are written to the log file. Press `Ctrl+C` to stop following.
