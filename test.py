import torch

def print_gpu_info():
    if not torch.cuda.is_available():
        print("No GPU available. CUDA is not detected.")
        return

    # Get the number of GPUs
    num_gpus = torch.cuda.device_count()
    print(f"Number of GPUs available: {num_gpus}")

    # Iterate over each GPU
    for i in range(num_gpus):
        print(f"\nGPU {i} Details:")
        print(f"  Name: {torch.cuda.get_device_name(i)}")
        print(f"  Compute Capability: {torch.cuda.get_device_capability(i)}")
        print(f"  Total Memory: {torch.cuda.get_device_properties(i).total_memory / 1024**3:.2f} GB")
        print(f"  CUDA Version: {torch.version.cuda}")
        print(f"  Device ID: {torch.cuda.get_device_properties(i).multi_processor_count} Multiprocessors")

if __name__ == "__main__":
    print_gpu_info()
