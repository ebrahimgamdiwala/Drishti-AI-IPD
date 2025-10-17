import torch
print(torch.cuda.is_available())  # Should return True if GPU is available
print(torch.cuda.get_device_name(0))  # Print the name of the GPU
print(torch.cuda.device_count())  # Print the number of GPUs available