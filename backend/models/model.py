import clip
import torch

# Set device to GPU if available, otherwise CPU
device = "cuda" if torch.cuda.is_available() else "cpu"

# Load the CLIP model and preprocessor
model, preprocess = clip.load("ViT-B/32", device=device)

# Set the model to evaluation mode
model.eval()