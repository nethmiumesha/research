import os
import subprocess
import shutil
import csv

# --- CONFIGURATION FOR RUST ---
SOURCE_DIR = r"C:\Users\umesha 1096\Desktop\my_research\data\processed_dataset\Rust"
BASE_LABEL_DIR = r"C:\Users\umesha 1096\Desktop\my_research\data\labeled_dataset\Rust"
REPORT_PATH = os.path.join(BASE_LABEL_DIR, "rust_multi_tool_report.csv")

SAFE_DIR = os.path.join(BASE_LABEL_DIR, "Safe", "Rust")
VULN_DIR = os.path.join(BASE_LABEL_DIR, "Vulnerable", "Rust")

IGNORE_KEYWORDS = ['target', 'node_modules', '.git', 'tests', 'fuzz']

os.makedirs(SAFE_DIR, exist_ok=True)
os.makedirs(VULN_DIR, exist_ok=True)

def make_windows_long_path(path):
    if not path.startswith("\\\\?\\") and os.name == 'nt':
        return "\\\\?\\" + os.path.abspath(path)
    return path

def run_rust_dynamic_labeling(start_index=0, end_index=2000):
    if not os.path.exists(SOURCE_DIR):
        print(f"Execution Halt: SOURCE_DIR not found at {SOURCE_DIR}")
        return

    # List all top-level items (Folders AND Standalone .rs files)
    raw_items = sorted(os.listdir(SOURCE_DIR))
    target_items = []

    for item in raw_items:
        item_path = os.path.join(SOURCE_DIR, item)
        
        # 1. Handle special Solana Program Library folder
        if os.path.isdir(item_path) and item.lower() == "solana-program-library":
            for sub_item in sorted(os.listdir(item_path)):
                sub_path = os.path.join(item_path, sub_item)
                if os.path.isdir(sub_path) and not any(kw in sub_item.lower() for kw in IGNORE_KEYWORDS):
                    target_items.append(("solana-program-library", sub_item, sub_path, "Folder"))
        
        # 2. Handle normal project folders
        elif os.path.isdir(item_path):
            target_items.append(("Root", item, item_path, "Folder"))
            
        # 3. Handle standalone single Rust files
        elif item.endswith(".rs"):
            target_items.append(("Root", item, item_path, "Single File"))

    executed_targets = target_items[start_index:end_index]
    print(f"Discovered {len(target_items)} total Rust items (Folders + Files). Processing range [{start_index}:{end_index}]...")

    file_exists = os.path.exists(REPORT_PATH)
    
    with open(REPORT_PATH, mode='a', newline='', encoding='utf-8') as report_file:
        fieldnames = ['Scope', 'Item_Name', 'Item_Type', 'Soteria_Clippy', 'Cargo_Audit', 'Final_Label']
        writer = csv.DictWriter(report_file, fieldnames=fieldnames)
        if not file_exists or os.stat(REPORT_PATH).st_size == 0:
            writer.writeheader()

        for idx, (scope, name, path, item_type) in enumerate(executed_targets):
            current_real_index = start_index + idx + 1
            print(f"\n🔍 [{current_real_index}/{end_index}] Auditing Rust {item_type}: {name} (Scope: {scope})")

            s_final, c_final = "Safe", "Safe"

            if item_type == "Folder":
                # --- FOLDER SCANNING MODE (Soteria + Cargo Audit) ---
                # 1. Soteria Folder Scan
                cmd_s = f'docker run --rm -v "{path}:/workspace" logisec/soteria /workspace'
                res_s = subprocess.run(cmd_s, shell=True, capture_output=True, text=True)
                if any(w in res_s.stdout.upper() for w in ["CRITICAL", "VULNERABILITY", "ERROR"]):
                    s_final = "Vulnerable"

                # 2. Cargo Audit Scan
                cmd_c = f'docker run --rm -v "{path}:/workspace" rustsec/cargo-audit cargo audit --directory /workspace --json'
                res_c = subprocess.run(cmd_c, shell=True, capture_output=True, text=True)
                if '"vulnerabilities":' in res_c.stdout and not '"vulnerabilities":[]' in res_c.stdout.replace(" ", ""):
                    c_final = "Vulnerable"

            else:
                # --- SINGLE FILE SCANNING MODE (Clippy / Standalone Checker) ---
                # For single files, we mount the file's parent directory and run analysis on the file
                file_dir = os.path.dirname(path)
                
                # Using a robust Rust analysis container to run clippy or security check on standalone file
                cmd_s = f'docker run --rm -v "{file_dir}:/data" rust:latest rustc --crate-type lib /data/{name} 2>&1'
                res_s = subprocess.run(cmd_s, shell=True, capture_output=True, text=True)
                # If there are compiler safety warnings or critical lint issues
                if "error" in res_s.stdout.lower() or "warning" in res_s.stdout.lower():
                    s_final = "Vulnerable"
                
                c_final = "Not Applicable (Single File)"

            # High-sensitivity union criteria
            final_label = "Vulnerable" if s_final == "Vulnerable" or c_final == "Vulnerable" else "Safe"

            # Context replication logic mapping
            target_base = VULN_DIR if final_label == "Vulnerable" else SAFE_DIR
            relative_structure = os.path.relpath(path, SOURCE_DIR)
            destination_path = os.path.join(target_base, relative_structure)

            src_long = make_windows_long_path(path)
            dest_long = make_windows_long_path(destination_path)
            os.makedirs(os.path.dirname(dest_long), exist_ok=True)

            try:
                if os.path.exists(dest_long):
                    if os.path.isdir(dest_long): shutil.rmtree(dest_long)
                    else: os.remove(dest_long)
                    
                if item_type == "Folder":
                    shutil.copytree(src_long, dest_long, ignore=shutil.ignore_patterns('target', '.git'))
                else:
                    shutil.copy2(src_long, dest_long)
                print(f"   -> Result: [Soteria/Rustc:{s_final}, Cargo_Audit:{c_final}] => COPIED TO {final_label} ✅")
            except Exception as e:
                print(f"IO Context Replica Failure: {e}")
                continue

            writer.writerow({
                'Scope': scope,
                'Item_Name': name,
                'Item_Type': item_type,
                'Soteria_Clippy': s_final,
                'Cargo_Audit': c_final,
                'Final_Label': final_label
            })

if __name__ == "__main__":
    # Configure end_index based on total discovered items
    run_rust_dynamic_labeling(start_index=0, end_index=2000)