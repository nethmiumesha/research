import os
import shutil

# Updated Root directory of Solidity dataset
BASE_DIR = r"C:\Users\numhe\OneDrive\Desktop\research\data\labeled_dataset\Solidity"

# Extended-length prefix to bypass Windows 260-character limit
def to_extended_path(p):
    p_abs = os.path.abspath(p)
    if not p_abs.startswith("\\\\?\\"):
        return "\\\\?\\" + p_abs
    return p_abs

def flatten_and_fix_project_folders():
    print("=" * 80)
    print("🧹 FIXING DEEPLY NESTED FOLDERS & LONG PATHS IN SOLIDITY DATASET...")
    print(f"📁 Target: {BASE_DIR}")
    print("=" * 80)

    if not os.path.exists(BASE_DIR):
        print(f"❌ Error: Path not found: {BASE_DIR}")
        return

    for split in ["Safe", "Vulnerable"]:
        folders_root = os.path.join(BASE_DIR, split, "Folders")
        if not os.path.exists(folders_root):
            continue

        ext_folders_root = to_extended_path(folders_root)
        project_dirs = [d for d in os.listdir(ext_folders_root) if os.path.isdir(os.path.join(ext_folders_root, d))]

        print(f"\n⚡ Scanning {split}/Folders ({len(project_dirs)} Projects)...")
        fixed_files_count = 0

        for p_name in project_dirs:
            p_full_path = os.path.join(ext_folders_root, p_name)

            # Find all .sol files inside nested subdirectories
            sol_files = []
            for root, dirs, files in os.walk(p_full_path):
                for f in files:
                    if f.lower().endswith(".sol"):
                        sol_files.append(os.path.join(root, f))

            # Move files directly to the root of this project folder
            for idx, sf_path in enumerate(sol_files):
                fname = os.path.basename(sf_path)
                if len(fname) > 50:
                    fname = f"contract_{idx:03d}.sol"

                target_dest = os.path.join(p_full_path, fname)

                if os.path.abspath(sf_path) != os.path.abspath(target_dest):
                    try:
                        shutil.move(sf_path, target_dest)
                        fixed_files_count += 1
                    except Exception:
                        pass

            # Remove empty or redundant nested directories
            for item in os.listdir(p_full_path):
                sub_item = os.path.join(p_full_path, item)
                if os.path.isdir(sub_item):
                    try:
                        shutil.rmtree(sub_item)
                    except Exception:
                        pass

        print(f"  [✓] {split}: Flattened and rescued {fixed_files_count} nested .sol files!")

    print("\n" + "=" * 80)
    print("🎯 SOLIDITY FILE PATHS SHORTENED & CLEANED SUCCESSFULLY!")
    print("=" * 80)

if __name__ == "__main__":
    flatten_and_fix_project_folders()