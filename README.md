# HPC Guide for NCSA Delta: From Login to Large-Scale Jobs

This guide provides a complete workflow for students using the NCSA Delta cluster. It covers connecting to the system, managing files for optimal performance, launching interactive sessions for development, and submitting large-scale batch jobs using Slurm.

## 1. Connecting to Delta

You will connect to Delta's login nodes using SSH from your local terminal. These nodes are for editing files, compiling code, and managing jobs, **not** for running computations.

### Login Command
Use the following command, replacing `username` with your NCSA username. The `login.delta.ncsa.illinois.edu` address automatically connects you to one of the available login nodes.

```bash
$ ssh username@login.delta.ncsa.illinois.edu
```

### Authentication
Authentication is a two-step process:
1.  You will first be prompted for your **NCSA password**.
2.  Next, you will be prompted for **NCSA Duo Multi-Factor Authentication (MFA)**. You can either type a passcode from the Duo app or type `1` to receive a push notification.

**Note:** The use of SSH key pairs is disabled for most users. You must use the password + Duo MFA method.

---

## 2. Checking Your Project Accounts

Once logged in, check which project allocations you belong to and their remaining balance in Service Units (SUs), which are measured in hours. You will need the account name for submitting jobs.

```bash
$ accounts

Account           Balance (Hours)    Deposited (Hours)
--------------  -----------------  -------------------
beyt-delta-gpu                 48                   48
```
In this example, the account name is `beyt-delta-gpu`.

---

## 3. Critical: File System and Data Management

**Where you store your files directly impacts your job's performance.** Using the wrong location can severely slow down your computations. Delta provides several file systems, each with a specific purpose.

| File System       | Path                        | Key Features & Purpose                                                                    |
| :---------------- | :-------------------------- | :---------------------------------------------------------------------------------------- |
| **HOME**          | `/u/$USER` or `$HOME`       | **Code, scripts, software environments.** Snapshots are taken daily. Small quota.          |
| **WORK - HDD**    | `/work/hdd/<account>/$USER` | **Primary computation area.** For datasets, models, and job I/O. Large quota.              |
| **WORK - NVMe**   | `/work/nvme/<account>/$USER`| **Specialist area.** Best for jobs with lots of small file read/writes. Request access.    |
| **PROJECTS**      | `/projects/<account>`       | **Shared results & data.** For final results and collaboration with project members.         |
| **NODE LOCAL TMP**| `/tmp`                      | **Ultra-fast, temporary storage.** Data is **deleted** when your job ends.                 |

### Detailed File System Guide

*   **HOME (`/u/$USER`)**: This is your landing directory. It is the **only area that has snapshots**, allowing you to recover accidentally deleted files. Use it exclusively for source code, compilation scripts, and software environments (like Python venv). **NEVER run I/O-heavy jobs from your HOME directory.**

*   **WORK (`/work/hdd/...`)**: This is the "workhorse" parallel file system. All large files—datasets, pre-trained models, and job outputs—should reside here. When your job reads or writes data, it should be from a directory in `/work/hdd`.

*   **NODE LOCAL TMP (`/tmp`)**: Each compute node has its own local, high-speed SSD available as `/tmp`. This space is not shared between nodes and is perfect for temporary files a job creates during its run.
    *   **Crucial:** Data in `/tmp` is **erased permanently** when your job finishes. Before your job ends, you **must** copy any important results from `/tmp` back to your `/work/hdd` directory.

### The Recommended Data Workflow

1.  **Code & Environment (`$HOME`):**
    *   Store your Git repository, source code, and Python virtual environments in `$HOME`.
    *   Example: `cd ~; git clone ...; python3 -m venv env`

2.  **Data Staging (`/work/hdd`):**
    *   Create directories for your project in `/work/hdd`.
    *   Download large datasets and models directly into this space.
    *   Example: `mkdir -p /work/hdd/beyt-delta-gpu/$USER/datasets`

3.  **Job Execution (in `/work/hdd` or `/tmp`):**
    *   Your Slurm script should `cd` into your `/work/hdd` directory.
    *   Your program reads inputs from `/work/hdd` and writes outputs to `/work/hdd`.
    *   For I/O-intensive intermediate files, your code can use `/tmp` on the compute node, but must copy results back to `/work/hdd` before exiting.

4.  **Results Archiving (`/projects`):**
    *   After your job is complete, move the final, important results from `/work/hdd` to `/projects` for long-term storage and sharing with collaborators.

---

## 4. Launching Interactive GPU Sessions (For Development & Debugging)

Use `srun` for an interactive shell on a compute node. This is ideal for testing, debugging, and short tasks. To exit the session, simply type `exit`.

### Case 1: A40 GPU
```bash
$ srun --account=beyt-delta-gpu --partition=gpuA40x4-interactive --nodes=1 --gpus-per-node=1 --tasks-per-node=1 --cpus-per-task=10 --mem=10g --time=01:00:00 --pty bash
```

### Case 2: A100 GPU
```bash
$ srun --account=beyt-delta-gpu --partition=gpuA100x4-interactive --nodes=1 --gpus-per-node=2 --tasks-per-node=1 --cpus-per-task=10 --mem=10g --time=01:00:00 --pty bash
```

### Case 3: H200 GPU
```bash
$ srun --account=beyt-delta-gpu --partition=gpuH200x8-interactive --nodes=1 --gpus-per-node=1 --tasks-per-node=1 --cpus-per-task=20 --mem=87g --time=01:00:00 --pty bash
```
### Commands for an Interactive Session

Once you have an interactive session running on a compute node (e.g., `gpub001`), use these commands.

```bash
# Check GPU availability and status (will now work)
$ nvidia-smi

# View CPU architecture and core count
$ lscpu

# Load any necessary software modules
$ module load anaconda3_gpu

# Start an interactive Python session to test code
$ ipython
```
---

## 5. Submitting Batch Jobs (For Production Runs)

For long-running, non-interactive computations, create a Slurm script and submit it with `sbatch`.

### Example: Slurm Script for Fine-Tuning a Model

This script, named `finetune_job.sh`, follows all the data management best practices.

```bash
#!/bin/bash

#==============================================================================
# SLURM JOB SCRIPT FOR FINETUNING A LARGE LANGUAGE MODEL
#==============================================================================

#------------------------------------------------------------------------------
# PART 1: SLURM DIRECTIVES (THE "ORDER")
#------------------------------------------------------------------------------
#SBATCH --job-name=finetune-llm
#SBATCH --account=beyt-delta-gpu
#SBATCH --partition=gpuA100x4
#SBATCH --nodes=1
#SBATCH --tasks-per-node=1
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=128G
#SBATCH --time=04:00:00
#SBATCH --output=slurm_logs/slurm-%j.out

#------------------------------------------------------------------------------
# PART 2: THE RECIPE (COMMANDS TO EXECUTE)
#------------------------------------------------------------------------------
echo "=========================================================="
echo "Job started on $(hostname) at $(date)"
echo "Job ID: $SLURM_JOB_ID"
echo "=========================================================="

# 1. Create a directory for slurm logs if it doesn't exist
mkdir -p slurm_logs

# 2. Activate your Python environment (located in your HOME directory)
source /u/rraut/my-project/env/bin/activate

# 3. Define paths on the /work file system
ACCOUNT="beyt-delta-gpu"
USER_NAME="rraut"
BASE_WORK_DIR="/work/hdd/$ACCOUNT/$USER_NAME"
PROJECT_CODE_DIR="/u/$USER_NAME/my-project"

MODEL_PATH="$BASE_WORK_DIR/models/llama-2-7b-hf"
DATASET_PATH="$BASE_WORK_DIR/datasets/my_squad_dataset"
OUTPUT_DIR="$BASE_WORK_DIR/output/llama-2-7b-squad-finetuned"

# Create the output directory on the /work filesystem
mkdir -p $OUTPUT_DIR

# 4. Navigate to your code directory
cd $PROJECT_CODE_DIR

# 5. Run the fine-tuning script
#    The script reads data from /work and writes its output back to /work
python run_language_modeling.py \
    --model_name_or_path $MODEL_PATH \
    --dataset_name $DATASET_PATH \
    --do_train \
    --do_eval \
    --output_dir $OUTPUT_DIR \
    --num_train_epochs 3 \
    --per_device_train_batch_size 4 \
    --save_steps 1000

echo "=========================================================="
echo "Job finished at $(date)"
echo "=========================================================="
```

### Submitting and Monitoring Your Job

1.  **Submit the job script:**
    ```bash
    $ sbatch finetune_job.sh
    ```

2.  **Check the status of your job:**
    ```bash
    $ squeue -u $USER
    ```

---



## 7. Official Documentation

This guide covers common workflows, but the official NCSA documentation is the definitive source of information.

*   **[NCSA Delta User Guide (System Architecture)](https://docs.ncsa.illinois.edu/systems/delta/en/latest/user_guide/architecture.html)**
