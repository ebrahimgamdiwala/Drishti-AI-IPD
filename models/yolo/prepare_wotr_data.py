import os
import random
import shutil
from tqdm import tqdm
import yaml
from collections import defaultdict

# ------------------------------
# Configuration
# ------------------------------
ANNOTATIONS_DIR = "datasets/WOTR/train/labels"
IMAGES_DIR = "datasets/WOTR/train/images"
OUTPUT_DIR = "WOTR_processed_balanced" # Using a new output directory
TRAIN_RATIO = 0.8

# --- Balanced Sampling Configuration ---
# This is the maximum number of files to include for any single class.
# It prevents common classes like 'car' or 'person' from dominating the dataset.
# Classes with fewer files than this will have all their files included.
MAX_FILES_PER_CLASS = 1500

# Define the classes you want to include
CLASSES = ['ashcan', 'bicycle', 'blind_road', 'bus', 'car', 'crosswalk', 'dog', 'fire_hydrant', 'green_light', 'motorcycle', 'person', 'pole', 'red_light', 'reflective_cone', 'roadblock', 'sign', 'tree', 'tricycle', 'truck', 'warning_column']

# ------------------------------
# Helper Functions
# ------------------------------
def create_directories():
    """Create necessary directories for the processed dataset."""
    dirs = [
        os.path.join(OUTPUT_DIR, split, dtype)
        for split in ['train', 'val', 'test']
        for dtype in ['images', 'labels']
    ]
    for d in dirs:
        os.makedirs(d, exist_ok=True)

def build_class_file_map():
    """
    Analyzes all label files and maps each class to the set of files it appears in.
    Returns a dictionary: {class_index: {'file1.txt', 'file2.txt', ...}}
    """
    class_map = defaultdict(set)
    print("🔎 Building class index from all label files...")
    all_labels = [f for f in os.listdir(ANNOTATIONS_DIR) if f.endswith('.txt')]
    for label_file in tqdm(all_labels, desc="Analyzing labels"):
        with open(os.path.join(ANNOTATIONS_DIR, label_file), 'r') as f:
            for line in f:
                try:
                    class_index = int(line.split()[0])
                    class_map[class_index].add(label_file)
                except (ValueError, IndexError):
                    continue
    return class_map

def perform_balanced_sampling(class_map):
    """
    Samples files using the class map to create a more balanced dataset.
    It undersamples common classes and includes all files for rare classes.
    """
    final_files_set = set()
    print("\n⚖️ Performing balanced sampling...")
    for class_index, files in sorted(class_map.items()):
        class_name = CLASSES[class_index]
        if len(files) > MAX_FILES_PER_CLASS:
            # If a class is too common, randomly sample from its files
            sampled = random.sample(list(files), MAX_FILES_PER_CLASS)
            final_files_set.update(sampled)
            print(f"  - Class '{class_name}' has {len(files)} files. Undersampling to {MAX_FILES_PER_CLASS}.")
        else:
            # If a class is rare, include all of its files
            final_files_set.update(files)
            print(f"  - Class '{class_name}' has {len(files)} files. Including all.")

    # Convert the set of label files back to (image, label) tuples
    balanced_data = []
    for label_file in final_files_set:
        img_file = label_file.replace('.txt', '.jpg')
        balanced_data.append((img_file, label_file))

    return balanced_data

def split_data(data_files):
    """Split data into train, validation, and test sets."""
    random.shuffle(data_files)
    train_size = int(len(data_files) * TRAIN_RATIO)
    val_size = int(len(data_files) * ((1 - TRAIN_RATIO) / 2))
    
    train_files = data_files[:train_size]
    val_files = data_files[train_size:train_size + val_size]
    test_files = data_files[train_size + val_size:]
    
    return train_files, val_files, test_files

def copy_files(files, split):
    """Copy files to their respective directories."""
    for img_file, label_file in tqdm(files, desc=f"Copying {split} files"):
        # Copy image
        src_img = os.path.join(IMAGES_DIR, img_file)
        dst_img = os.path.join(OUTPUT_DIR, split, 'images', img_file)
        if os.path.exists(src_img):
            shutil.copy2(src_img, dst_img)

        # Copy label
        src_label = os.path.join(ANNOTATIONS_DIR, label_file)
        dst_label = os.path.join(OUTPUT_DIR, split, 'labels', label_file)
        if os.path.exists(src_label):
            shutil.copy2(src_label, dst_label)

def create_data_yaml(filename="wotr_balanced.yaml"):
    """Create data.yaml file for YOLOv8 training."""
    data = {
        'path': os.path.abspath(OUTPUT_DIR),
        'train': os.path.join('train', 'images'),
        'val': os.path.join('val', 'images'),
        'test': os.path.join('test', 'images'),
        'names': {i: name for i, name in enumerate(CLASSES)},
        'nc': len(CLASSES)
    }
    
    with open(os.path.join(OUTPUT_DIR, filename), 'w') as f:
        yaml.dump(data, f, sort_keys=False)

def main():
    """Main function to prepare the WOTR dataset."""
    print("🚀 Starting WOTR dataset preparation with BALANCED sampling...")
    
    create_directories()
    
    class_to_files_map = build_class_file_map()
    
    sampled_files = perform_balanced_sampling(class_to_files_map)
    print(f"\n📊 Total unique files after balanced sampling: {len(sampled_files)}")
    
    train_files, val_files, test_files = split_data(sampled_files)
    print(f"Split sizes: Train={len(train_files)}, Val={len(val_files)}, Test={len(test_files)}")
    
    copy_files(train_files, 'train')
    copy_files(val_files, 'val')
    copy_files(test_files, 'test')
    
    yaml_filename = "wotr_balanced.yaml"
    create_data_yaml(yaml_filename)
    
    print("\n✅ Dataset preparation complete!")
    print(f"📁 Processed balanced dataset saved to '{OUTPUT_DIR}'")
    print(f"👉 Use '{os.path.join(OUTPUT_DIR, yaml_filename)}' for your next training.")

if __name__ == "__main__":
    main()