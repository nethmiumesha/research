import os
import subprocess
import csv
import json

# --- CONFIGURATION ---
INPUT_ROOT = r"C:\Users\umesha 1096\Desktop\my_research\data\labeled_dataset\Vyper"
EXPORT_CSV_PATH = os.path.join(INPUT_ROOT, "multi_tool_consensus_dataset.csv")

def run_slither_analysis(file_path):
    """
    Runs Slither Docker analyzer core hook.
    """
    try:
        # Docker engine wrapper to bind volume dynamically
        cmd = f'docker run --rm -v "{file_path}:/data" crytic/slither slither /data'
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        # Checking for common vulnerability strings in the output stream
        output = result.stdout + result.stderr
        if any(keyword in output.lower() for keyword in ["reentrancy", "shadowing", "uninitialized", "vulnerability"]):
            return 1 # Flagged as vulnerable
        return 0
    except Exception:
        return 0

def run_mythril_analysis(file_path):
    """
    Runs Mythril symbolic execution suite analyzer via docker framework.
    """
    try:
        cmd = f'docker run --rm -v "{file_path}:/data" mythril/myth analyze /data'
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        output = result.stdout + result.stderr
        if any(keyword in output.lower() for keyword in ["vulnerability", "warning", "exception", "reentrancy"]):
            return 1
        return 0
    except Exception:
        return 0

def run_oyente_analysis(file_path):
    """
    Runs Oyente EVM execution engine analysis matrix container.
    """
    try:
        # Oyente requires fallback execution environments bound via legacy docker flags
        cmd = f'docker run --rm -v "{file_path}:/data" luongnguyen/oyente python oyente.py -s /data'
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        output = result.stdout + result.stderr
        if "vulnerability" in output.lower() or "assertion" in output.lower():
            return 1
        return 0
    except Exception:
        return 0

def execute_triple_tool_consensus():
    print("🚀 Initiating Triple-Tool Security Consensus Verification Matrix...")
    consensus_logs = []
    
    splits = [
        ("Safe_Folder", os.path.join(INPUT_ROOT, "Safe", "Folders")),
        ("Vuln_Single", os.path.join(INPUT_ROOT, "Vulnerable", "Single_Files")),
        ("Vuln_Folder", os.path.join(INPUT_ROOT, "Vulnerable", "Folders"))
    ]
    
    for split_name, directory_path in splits:
        if not os.path.exists(directory_path):
            print(f"⚠️ Target path directory path empty or missing mapping boundary: {directory_path}")
            continue
            
        print(f"\n📂 Auditing and Labeled Profiling for split scope: {split_name}...")
        
        # Linear iteration scanner logic across files array
        for root, dirs, files in os.walk(directory_path):
            for file in files:
                if file.endswith(('.vy', '.sol')): # Supports multi-language processing if scaled later
                    full_target_file_path = os.path.join(root, file)
                    print(f"   ⚙️ Scanning smart contract instance element: {file}...")
                    
                    # Parallel tracking matrix assignments
                    slither_vote = run_slither_analysis(full_target_file_path)
                    mythril_vote = run_mythril_analysis(full_target_file_path)
                    oyente_vote = run_oyente_analysis(full_target_file_path)
                    
                    # --- TRIPLE CONSENSUS VOTING CORE LOGIC ---
                    # Consensus = True alignment value if at least 2 tools detect the flaw anomaly
                    total_votes = slither_vote + mythril_vote + oyente_vote
                    final_consensus_label = 1 if total_votes >= 2 else 0
                    
                    consensus_logs.append([
                        split_name, 
                        file, 
                        slither_vote, 
                        mythril_vote, 
                        oyente_vote, 
                        final_consensus_label
                    ])
                    
                    print(f"      📊 Results -> Slither: {slither_vote}, Mythril: {mythril_vote}, Oyente: {oyente_vote} | Consensus Label: {final_consensus_label}")

    # --- SAVE SHIELD COMPLIANT PROOFS MATRIX ---
    with open(EXPORT_CSV_PATH, mode='w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Split_Context', 'Smart_Contract_Name', 'Slither_Detector', 'Mythril_Detector', 'Oyente_Detector', 'Final_Consensus_Label'])
        writer.writerows(consensus_logs)
        
    print(f"\n🎯 [Verification Loop Complete] Multi-tool Consensus dataset logged securely inside target array node: {EXPORT_CSV_PATH}")

if __name__ == "__main__":
    execute_triple_tool_consensus()