#!/bin/bash                         # Specifies that the script should be run in a Bash shell

#SBATCH --account=beyt-delta-gpu    # Specifies the account to charge GPU usage to
#SBATCH --job-name=GPU73125         # Sets the name of the job (useful for job monitoring)
#SBATCH --partition=gpuA40x4        # Specifies the partition/queue to submit the job to (e.g., a GPU partition with A40 GPUs)
#SBATCH --nodes=1                   # Requests 1 node (machine)
#SBATCH --ntasks-per-node=1         # Requests 1 task per node (i.e., a single process)
#SBATCH --gpus-per-node=1           # Requests 1 GPU on the node
#SBATCH --cpus-per-task=10          # Allocates 10 CPU cores for the task (useful for data preprocessing, etc.)
#SBATCH --mem=16g                   # Requests 16 GB of RAM for the job
#SBATCH --time=00:10:00             # Sets the maximum allowed runtime to 10 minutes
#SBATCH --output=GPU73125_%j.out    # Standard output will be written to this file (%j is replaced by the job ID)
#SBATCH --error=GPU73125_%j.err     # Standard error will be written to this file (%j is replaced by the job ID)

module reset                        # Resets the module environment to a clean state
module load anaconda3_gpu           # Loads the Anaconda module configured for GPU usage
module list                         # Lists all currently loaded modules for logging/debugging

# Launch Python code...
time python ./test.py              
# Runs the Python script `test.py` and prints the execution time
