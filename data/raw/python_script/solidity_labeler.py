import os
import subprocess
import shutil
import csv

# --- CONFIGURATION ---
SOURCE_DIR = r"C:\Users\umesha 1096\Desktop\my_research\data\processed_dataset\Solidity\curated_solidity_1300"
BASE_LABEL_DIR = r"C:\Users\umesha 1096\Desktop\my_research\data\labeled_dataset\Solidity"
REPORT_PATH = os.path.join(BASE_LABEL_DIR, "multi_tool_consensus_report.csv")

SAFE_DIR = os.path.join(BASE_LABEL_DIR, "Safe", "curated_solidity_1300")
VULN_DIR = os.path.join(BASE_LABEL_DIR, "Vulnerable", "curated_solidity_1300")

IGNORE_KEYWORDS = ['test', 'tests', 'testing', 'mock', 'node_modules']

os.makedirs(SAFE_DIR, exist_ok=True)
os.makedirs(VULN_DIR, exist_ok=True)

# Function to handle Windows Long Paths safely
def make_windows_long_path(path):
    if not path.startswith("\\\\?\\") and os.name == 'nt':
        return "\\\\?\\" + os.path.abspath(path)
    return path

def run_project_level_labeling(start_index=905, end_index=1019):
    project_items = sorted(os.listdir(SOURCE_DIR))
    executed_items = project_items[start_index:end_index]
    print(f"🚀 Found {len(project_items)} total items. Processing range [{start_index}:{end_index}]...")

    file_exists = os.path.exists(REPORT_PATH)
    
    # FIX: Explicitly added encoding='utf-8' to handle non-standard Cyrillic/Unicode characters smoothly
    with open(REPORT_PATH, mode='a', newline='', encoding='utf-8') as report_file:
        fieldnames = ['Item_Name', 'Item_Type', 'Slither', 'Mythril', 'Oyente', 'Final_Label']
        writer = csv.DictWriter(report_file, fieldnames=fieldnames)
        if not file_exists or os.stat(REPORT_PATH).st_size == 0:
            writer.writeheader()

        for idx, item_name in enumerate(executed_items):
            item_path = os.path.join(SOURCE_DIR, item_name)
            current_real_index = start_index + idx + 1
            item_type = "Folder" if os.path.isdir(item_path) else "Single File"
            print(f"\n🔍 [{current_real_index}/{end_index}] Analyzing {item_type}: {item_name}")

            sol_files = []
            if os.path.isdir(item_path):
                for root, dirs, files in os.walk(item_path):
                    if any(kw in root.lower() for kw in IGNORE_KEYWORDS): continue
                    for file in files:
                        if file.endswith(".sol"):
                            sol_files.append(os.path.join(root, file))
            elif item_name.endswith(".sol"):
                sol_files.append(item_path)

            if not sol_files:
                print(f"   ⚠️ No valid Solidity files found in {item_name}. Skipping.")
                continue

            project_is_vulnerable = False
            s_final, m_final, o_final = "Safe", "Safe", "Safe"

            for file_path in sol_files:
                file_name = os.path.basename(file_path)
                current_file_dir = os.path.dirname(file_path)

                # 1. Slither
                cmd_s = f'docker run --rm -v "{current_file_dir}:/data" trailofbits/eth-security-toolbox slither /data/{file_name} --json -'
                res_s = subprocess.run(cmd_s, shell=True, capture_output=True, text=True)
                if '"detectors":' in res_s.stdout: s_final = "Vulnerable"

                # 2. Mythril
                cmd_m = f'docker run --rm -v "{current_file_dir}:/data" mythril/myth analyze /data/{file_name} --execution-timeout 30'
                res_m = subprocess.run(cmd_m, shell=True, capture_output=True, text=True)
                if "The program is safe" not in res_m.stdout and len(res_m.stdout) > 50: m_final = "Vulnerable"

                # 3. Oyente
                cmd_o = f'docker run --rm -v "{current_file_dir}:/data" luongnguyen/oyente python /oyente/oyente/oyente.py -s /data/{file_name}'
                res_o = subprocess.run(cmd_o, shell=True, capture_output=True, text=True)
                if "True" in res_o.stdout: o_final = "Vulnerable"

                if "Vulnerable" in [s_final, m_final, o_final]:
                    project_is_vulnerable = True
                    break

            final_label = "Vulnerable" if project_is_vulnerable else "Safe"
            target_base_dir = VULN_DIR if final_label == "Vulnerable" else SAFE_DIR
            destination_path = os.path.join(target_base_dir, item_name)

            # Apply Long Path Fix dynamically before copying
            src_long = make_windows_long_path(item_path)
            dest_long = make_windows_long_path(destination_path)

            try:
                if os.path.isdir(item_path):
                    if os.path.exists(dest_long): 
                        shutil.rmtree(dest_long)
                    shutil.copytree(src_long, dest_long)
                else:
                    shutil.copy2(src_long, dest_long)
                print(f"   -> Result: [S:{s_final}, M:{m_final}, O:{o_final}] => COPIED TO {final_label} ✅")
            except Exception as e:
                print(f"❌ File Copy Error: {e}")
                continue

            writer.writerow({
                'Item_Name': item_name,
                'Item_Type': item_type,
                'Slither': s_final,
                'Mythril': m_final,
                'Oyente': o_final,
                'Final_Label': final_label
            })

if __name__ == "__main__":
    run_project_level_labeling(start_index=905, end_index=1019)