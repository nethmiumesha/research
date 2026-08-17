import os
import re
import json

# ==========================================
# 1. CONFIGURATION PATH
# ==========================================
DATASET_ROOT_FOLDER = r"C:\Users\numhe\OneDrive\Desktop\my_research (2)\data\labeled_dataset\Solidity"

MAX_NAME_LENGTH = 35

MAPPING_LOG_FILE = os.path.join(DATASET_ROOT_FOLDER, "name_mapping_log.json")

SKIP_FOLDERS = {"Solidity_GNN_Inputs", "Line_Level_Features"}

# ==========================================
# 2. HELPER FUNCTIONS
# ==========================================
def run_dataset_shortener():
    print("=========================================================================")
    print("🚀 INITIALIZING SOLIDITY DATASET INDEXED RENAMING PIPELINE")
    print("=========================================================================")

    if not os.path.exists(DATASET_ROOT_FOLDER):
        print(f"❌ Error: Root directory path not found: {DATASET_ROOT_FOLDER}")
        return

    name_mapping = {}
    renamed_files_count = 0
    renamed_folders_count = 0

    # Process bottom-up to rename files inside folders before renaming parent folders
    for root, dirs, files in os.walk(DATASET_ROOT_FOLDER, topdown=False):
        # Skip utility and generated feature folders
        if any(skip_f in root for skip_f in SKIP_FOLDERS):
            continue

        # 1. Rename Files sequentially in current directory
        file_counter = 1
        for file_name in files:
            if file_name == "name_mapping_log.json" or file_name.endswith(".csv") or file_name.endswith(".json"):
                continue

            old_file_path = os.path.join(root, file_name)
            base_name, ext = os.path.splitext(file_name)
            
            # Generate indexed candidate name like verified_workspace_001.sol
            new_file_name = f"verified_workspace_{file_counter:03d}{ext}"
            new_file_path = os.path.join(root, new_file_name)

            while os.path.exists(new_file_path) and new_file_name != file_name:
                file_counter += 1
                new_file_name = f"verified_workspace_{file_counter:03d}{ext}"
                new_file_path = os.path.join(root, new_file_name)

            if new_file_name != file_name:
                os.rename(old_file_path, new_file_path)
                rel_old = os.path.relpath(old_file_path, DATASET_ROOT_FOLDER)
                rel_new = os.path.relpath(new_file_path, DATASET_ROOT_FOLDER)
                name_mapping[rel_old] = rel_new
                renamed_files_count += 1
                print(f"📄 File Renamed: {file_name} ➔ {new_file_name}")

            file_counter += 1

        # 2. Rename Directories sequentially in current directory
        dir_counter = 1
        for dir_name in dirs:
            if dir_name in SKIP_FOLDERS:
                continue

            old_dir_path = os.path.join(root, dir_name)
            new_dir_name = f"verified_workspace_{dir_counter:03d}"
            new_dir_path = os.path.join(root, new_dir_name)

            while os.path.exists(new_dir_path) and new_dir_name != dir_name:
                dir_counter += 1
                new_dir_name = f"verified_workspace_{dir_counter:03d}"
                new_dir_path = os.path.join(root, new_dir_name)

            if new_dir_name != dir_name:
                os.rename(old_dir_path, new_dir_path)
                rel_old = os.path.relpath(old_dir_path, DATASET_ROOT_FOLDER)
                rel_new = os.path.relpath(new_dir_path, DATASET_ROOT_FOLDER)
                name_mapping[rel_old] = rel_new
                renamed_folders_count += 1
                print(f"📁 Folder Renamed: {dir_name} ➔ {new_dir_name}")

            dir_counter += 1

    # Save mapping log for future reference
    with open(MAPPING_LOG_FILE, "w", encoding="utf-8") as f:
        json.dump(name_mapping, f, indent=4)

    print("=========================================================================")
    print(f"🎯 INDEXED RENAMING COMPLETE!")
    print(f"   - Indexed Files   : {renamed_files_count}")
    print(f"   - Indexed Folders : {renamed_folders_count}")
    print(f"   - Mapping Saved   : {MAPPING_LOG_FILE}")
    print("=========================================================================")

if __name__ == "__main__":
    run_dataset_shortener()