
# HPC Interactive Session Guide on NSCA Delta GPU

This guide provides instructions for launching interactive GPU sessions on the HPC cluster using SLURM's `srun` command.


## Available Accounts

```bash
$ accounts

Account           Balance (Hours)    Deposited (Hours)
--------------  -----------------  -------------------
beyt-delta-gpu                 48                   48
```

## Launching Interactive GPU Sessions

Use the `srun` command to request interactive GPU resources. Below are three common configurations:

### Case 1: A40 GPU Configuration
```bash
$ srun --account=beyt-delta-gpu \
       --partition=gpuA40x4-interactive \
       --nodes=1 \
       --gpus-per-node=1 \
       --tasks=1 \
       --tasks-per-node=1 \
       --cpus-per-task=10 \
       --mem=10g \
       --pty bash
```

### Case 2: A100 GPU Configuration
```bash
$ srun --account=beyt-delta-gpu \
       --partition=gpuA100x4-interactive \
       --nodes=1 \
       --gpus-per-node=2 \
       --tasks=1 \
       --tasks-per-node=1 \
       --cpus-per-task=10 \
       --mem=10g \
       --pty bash
```

### Case 3: H200 GPU Configuration
```bash
$ srun --account=beyt-delta-gpu \
       --partition=gpuH200x8-interactive \
       --nodes=1 \
       --gpus-per-node=1 \
       --tasks=1 \
       --tasks-per-node=1 \
       --cpus-per-task=20 \
       --mem=87g \
       --pty bash
```

---

## Post-Connection Commands

After establishing your interactive session, run the following commands to verify resources and load the required environment:

```bash
# Check GPU availability and status
$ nvidia-smi

# View CPU architecture and core count
$ lscpu

# Load Anaconda environment for GPU computing
$ module load anaconda3_gpu

# Start interactive Python session
$ ipython
```

---

## Notes
- Replace the account name if you have access to different accounts.
- Adjust CPU, memory, and GPU counts based on your computational needs.
- The `--pty bash` flag provides an interactive shell environment.
- Ensure you're using the appropriate partition based on available hardware.
```
