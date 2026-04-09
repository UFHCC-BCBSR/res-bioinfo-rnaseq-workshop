# HiPerGator Basics

HiPerGator is the University of Florida's high-performance computing (HPC) cluster, managed by UF Research Computing. It gives you access to far more computational power than a personal computer, which is essential for steps like running the nf-core/rnaseq pipeline. This section covers everything you need to know to get started on HiPerGator for this workshop.

For more comprehensive documentation, see the [UF Research Computing docs](https://docs.rc.ufl.edu/).

## Logging In

You connect to HiPerGator via SSH from your terminal. If you haven't set up your terminal yet, see the [Command Line Basics](../01_command-line-basics/command-line-basics.md) section. Replace `username` with your GatorLink username:

```bash
ssh username@hpg.rc.ufl.edu
```

You will be prompted for your password and then a Duo two-factor authentication push. After authenticating you will land on a **login node**, which looks like this:

```
[username@login1 ~]$
```

!!! warning "Do not run work on login nodes"
    Login nodes are shared resources for everyone on the cluster. All real work must be submitted as SLURM jobs. Running computationally intensive work on login nodes is against HiPerGator policy and can result in account suspension.

## The HiPerGator Filesystem

HiPerGator has three main storage locations, each with a different purpose:

| **Location** | **Path** | **Quota** | **Use for** |
|---|---|---|---|
| Home | `/home/username` | 40 GB | Scripts, configuration files, important small files |
| Blue | `/blue/group/username` | Varies | All active research work and data |
| Orange | `/orange/group/username` | Varies | Long-term archival storage |

Always run your analyses from `/blue` — it is a high-performance storage system designed to handle the input/output demands of HPC workloads. `/home` and `/orange` are not suitable for running analyses.

!!! danger "Already have a HiPerGator account?"
    If you already have an active HiPerGator account, do not use your personal `/blue` directory for this workshop. Instead, create and use a personal folder inside the shared workshop directory:

    ```bash
    mkdir /blue/bioinf_workshop/$USER
    cd /blue/bioinf_workshop/$USER
    ```

For this workshop, your working directory will be:

```
/blue/bioinf_workshop/username
```

To navigate there:

```bash
cd /blue/bioinf_workshop/$USER
```

You can check your storage quotas with:

```bash
home_quota
```

```bash
blue_quota
```

```bash
orange_quota
```

## Open OnDemand

Open OnDemand (OOD) is a web interface for HiPerGator available at [https://ood.rc.ufl.edu](https://ood.rc.ufl.edu). It provides a graphical file browser for navigating, uploading, downloading, and editing files, a dashboard for monitoring your jobs, and a browser-based terminal if you prefer not to use SSH. For this workshop, OOD is particularly useful for uploading input files and downloading results without needing to use `scp` on the command line.

## Loading Software with Modules

HiPerGator uses a module system to manage software. Software is not available by default — you need to load it first.

<span class="command-title">module spider — search for available software</span>

```bash
module spider nextflow
```

type `q` to exit the documentation 

<span class="command-title">module load — load a module</span>

```bash
module load nextflow
```

<span class="command-title">module list — see what you have loaded</span>

```bash
module list
```

<span class="command-title">module unload — unload a module</span>

```bash
module unload nextflow
```

Some software requires loading a prerequisite module first. `module spider` will tell you if this is the case and what to load.

## Writing and Submitting SLURM Jobs

HiPerGator uses the SLURM scheduler to manage jobs. Rather than running commands directly on the login node, you write a job script that specifies the resources you need and the commands to run, then submit it to the scheduler with `sbatch`.

A SLURM script is just a regular bash script with a block of `#SBATCH` directives at the top that tell the scheduler what resources to allocate. To illustrate this, here is a simple bash script — each `echo` command just prints a line of text to the screen:

```bash
#!/bin/bash
echo "Hello from HiPerGator!"
echo "My username is: $(whoami)"
echo "Today's date is: $(date)"
echo "I am running on node: $(hostname)"
```

You can run this directly on the login node by copying this text in a file that you create and name `hello.sh` and run with `bash hello.sh`. 

Now here is the exact same script as a SLURM job — the only difference is the `#SBATCH` header:

```bash
#!/bin/bash
#SBATCH --job-name=hello
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1gb
#SBATCH --time=00:05:00
#SBATCH --account=bioinf_workshop
#SBATCH --qos=bioinf_workshop
#SBATCH --output=hello_%j.out
#SBATCH --error=hello_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=$USER@ufl.edu

echo "Hello from HiPerGator!"
echo "My username is: $(whoami)"
echo "Today's date is: $(date)"
echo "I am running on node: $(hostname)"
```

Now create this file on HiPerGator. Open a new file with nano:

```bash
nano hello.sbatch
```

??? tip "Need a nano refresher?"
    - Type or paste your content
    - `Ctrl+O` then `Enter` to save
    - `Ctrl+X` to exit

Paste the script above into nano, save, and exit. Then verify the file was created:

```bash
cat hello.sbatch
```

The key `#SBATCH` flags are summarized here:

| **Flag** | **Description** |
|---|---|
| `--cpus-per-task` | Number of CPU cores. Only request multiple if your software can use them. |
| `--mem` | Total memory, e.g. `16gb`. If your job exceeds this it will be killed. |
| `--time` | Maximum runtime. Job will be cancelled if it exceeds this. Request ~20% more than you expect. |
| `--partition` | The queue to submit to. Use `[training-partition]` for this workshop. |
| `--account` and `--qos` | Must match your group. Use `bioinf_workshop` for this workshop. |

??? info "Using burst QOS for your own group"
    Most HiPerGator groups have access to a burst QOS that allows you to temporarily use more resources than your group's allocation. To use it, append `-b` to your group name for the `--qos` flag:

    ```bash
    #SBATCH --account=mygroup
    #SBATCH --qos=mygroup-b
    ```

    Burst jobs are lower priority and can be preempted (cancelled and requeued) if the resources are needed by higher-priority jobs, so it's best used for jobs that can be restarted or that you don't need to complete by a specific time.

Now submit it:

```bash
sbatch hello.sbatch
```

> `Submitted batch job 12345678`

SLURM will give you a job ID — keep track of it. You can check the status of your job with `squeue`. The `ST` column shows job state: `PD` = pending, `R` = running, `CG` = completing:

```bash
squeue -u $USER
```

If you need to cancel the job:

```bash
scancel 12345678
```

Once the job completes, check the output log (replace `12345678` with your actual job ID). SLURM writes output and errors to separate log files — these are the first place to look if something goes wrong:

```bash
cat hello_12345678.out
```

> Hello from HiPerGator!  
> My username is: username  
> Today's date is: Thu Apr  3 10:42:11 EDT 2026  
> I am running on node: c0709a-s30

If you want to follow the log in real time while a job is still running, use `tail -f` (press `Ctrl+C` to stop):

```bash
tail -f hello_12345678.out
```

To check the error log:

```bash
tail hello_12345678.err
```

To see a summary of your recent completed jobs:

```bash
sacct
```

To see overall resource usage for your group:

```bash
slurmInfo
```
