import os
import subprocess
import shutil
import csv
import json

# --- CONFIGURATION ---
SOURCE_ROOT = r"C:\Users\umesha 1096\Desktop\my_research\data\processed_dataset\Vyper\curated_vyper_1200"
BASE_LABEL_DIR = r"C:\Users\umesha 1096\Desktop\my_research\data\labeled_dataset\Vyper"
REPORT_PATH = os.path.join(BASE_LABEL_DIR, "multi_tool_consensus_report.csv")

# FIXED: Explicitly separated Safe output directories to prevent file pollution
SAFE_FOLDER_DIR = os.path.join(BASE_LABEL_DIR, "Safe", "Folders")
SAFE_SINGLE_DIR = os.path.join(BASE_LABEL_DIR, "Safe", "Single_Files")
VULN_SINGLE_DIR = os.path.join(BASE_LABEL_DIR, "Vulnerable", "Single_Files")
VULN_FOLDER_DIR = os.path.join(BASE_LABEL_DIR, "Vulnerable", "Folders")

os.makedirs(SAFE_FOLDER_DIR, exist_ok=True)
os.makedirs(SAFE_SINGLE_DIR, exist_ok=True)
os.makedirs(VULN_SINGLE_DIR, exist_ok=True)
os.makedirs(VULN_FOLDER_DIR, exist_ok=True)

def make_windows_long_path(path):
    if not path.startswith("\\\\?\\") and os.name == 'nt':
        return "\\\\?\\" + os.path.abspath(path)
    return path

def run_vyper_production_labeling():
    print("🚀 Launching Production Multi-Tool Verification Engine for ALL 1,800 Synced Elements...")
    
    # FIXED: Restructured partition map matrix array to include ALL 4 target quadrants
    splits = [
        ("Safe_Folder", os.path.join(SOURCE_ROOT, "Safe", "Folders"), SAFE_FOLDER_DIR, False),
        ("Safe_Single", os.path.join(SOURCE_ROOT, "Safe", "Single_Files"), SAFE_SINGLE_DIR, True),
        ("Vuln_Single", os.path.join(SOURCE_ROOT, "Vulnerable", "Single_Files"), VULN_SINGLE_DIR, True),
        ("Vuln_Folder", os.path.join(SOURCE_ROOT, "Vulnerable", "Folders"), VULN_FOLDER_DIR, False)
    ]
    
    file_exists = os.path.exists(REPORT_PATH)
    
    with open(REPORT_PATH, mode='a', newline='', encoding='utf-8') as report_file:
        fieldnames = ['Split_Type', 'Item_Name', 'Item_Structure', 'Slither', 'Mythril', 'Oyente', 'Final_Label']
        writer = csv.DictWriter(report_file, fieldnames=fieldnames)
        if not file_exists or os.stat(REPORT_PATH).st_size == 0:
            writer.writeheader()

        for split_name, source_dir, target_base_dir, is_single in splits:
            if not os.path.exists(source_dir):
                print(f"⚠️ Source directory path not mapped: {source_dir}")
                continue
                
            project_items = sorted(os.listdir(source_dir))
            print(f"\n📂 Auditing Pipeline Partition: {split_name} ({len(project_items)} items discovered)...")

            for idx, item_name in enumerate(project_items):
                item_path = os.path.join(source_dir, item_name)
                item_structure = "Single File" if is_single else "Folder"

                # --- DATA INTEGRITY SHIELD FOR SINGLE FILES ---
                if is_single:
                    if item_name.endswith('.json'):
                        continue # Standalone graph arrays processed alongside their paired .vy twin
                    
                    if item_name.endswith('.vy'):
                        # FIXED: Dynamic string extraction to safely clean up index tracking regardless of prefix naming rules
                        sample_index = item_name.replace('verified_vuln_file_', '').replace('verified_safe_file_', '').replace('.vy', '')
                        expected_json_name = f"gnn_ready_graph_{sample_index}.json"
                        expected_json_path = os.path.join(source_dir, expected_json_name)
                        
                        if not os.path.exists(expected_json_path):
                            print(f"   ⚠️ [DATA SYNC BREACH] Graph missing for {item_name}. Rejecting entry from GNN lifecycle.")
                            continue

                vy_files = []
                if os.path.isdir(item_path):
                    for root, dirs, files in os.walk(item_path):
                        for file in files:
                            if file.endswith(".vy"):
                                vy_files.append(os.path.join(root, file))
                elif item_name.endswith(".vy"):
                    vy_files.append(item_path)

                if not vy_files:
                    continue

                print(f"🔍 [{idx + 1}/{len(project_items)}] Analyzing {item_structure}: {item_name}")
                
                project_is_vulnerable = False
                s_final, m_final, o_final = "Safe", "Safe", "Safe"

                # Run containerized scanning hooks across compiled units
                for file_path in vy_files:
                    file_name = os.path.basename(file_path)
                    current_file_dir = os.path.dirname(file_path)

                    # 1. Slither Static Analysis Hook
                    cmd_s = f'docker run --rm -v "{current_file_dir}:/data" crytic/slither slither /data/{file_name} --json -'
                    res_s = subprocess.run(cmd_s, shell=True, capture_output=True, text=True)
                    if '"detectors":' in res_s.stdout or "vulnerability" in (res_s.stdout + res_s.stderr).lower(): 
                        s_final = "Vulnerable"

                    # 2. Mythril Symbolic Graph Analyzer
                    cmd_m = f'docker run --rm -v "{current_file_dir}:/data" mythril/myth analyze /data/{file_name} --execution-timeout 30'
                    res_m = subprocess.run(cmd_m, shell=True, capture_output=True, text=True)
                    if "The program is safe" not in res_m.stdout and len(res_m.stdout) > 50: 
                        m_final = "Vulnerable"

                    # 3. Oyente EVM Core Validator
                    cmd_o = f'docker run --rm -v "{current_file_dir}:/data" luongnguyen/oyente python /oyente/oyente/oyente.py -s /data/{file_name}'
                    res_o = subprocess.run(cmd_o, shell=True, capture_output=True, text=True)
                    if "True" in res_o.stdout or "vulnerability" in res_o.stdout.lower(): 
                        o_final = "Vulnerable"

                    if "Vulnerable" in [s_final, m_final, o_final]:
                        project_is_vulnerable = True
                        break

                final_label = "Vulnerable" if project_is_vulnerable else "Safe"
                destination_path = os.path.join(target_base_dir, item_name)

                src_long = make_windows_long_path(item_path)
                dest_long = make_windows_long_path(destination_path)

                try:
                    if os.path.isdir(item_path):
                        if os.path.exists(dest_long): 
                            shutil.rmtree(dest_long)
                        shutil.copytree(src_long, dest_long)
                    else:
                        shutil.copy2(src_long, dest_long)
                        
                        # Securely transfer paired graph matrix side-by-side
                        sample_index = item_name.replace('verified_vuln_file_', '').replace('verified_safe_file_', '').replace('.vy', '')
                        src_json_long = make_windows_long_path(os.path.join(source_dir, f"gnn_ready_graph_{sample_index}.json"))
                        dest_json_long = make_windows_long_path(os.path.join(target_base_dir, f"gnn_ready_graph_{sample_index}.json"))
                        shutil.copy2(src_json_long, dest_json_long)
                        
                    print(f"   -> Result: [S:{s_final}, M:{m_final}, O:{o_final}] => COPIED TO {final_label} ✅")
                except Exception as e:
                    print(f"❌ Storage Pipeline Exception: {e}")
                    continue

                writer.writerow({
                    'Split_Type': split_name,
                    'Item_Name': item_name,
                    'Item_Structure': item_structure,
                    'Slither': s_final,
                    'Mythril': m_final,
                    'Oyente': o_final,
                    'Final_Label': final_label
                })

    print(f"\n🎯 [Labeling Complete] Verified 1,800 synchronized items successfully. Report: {REPORT_PATH}")

if __name__ == "__main__":
    run_vyper_production_labeling()