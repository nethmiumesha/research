import os
import re
import json
import csv

# Configuration
DATASET_DIR = r"c:\Users\nethmi_h\Desktop\learn\my_research\my_research\data\labeled_dataset\Solidity"
OUTPUT_DIR = os.path.join(DATASET_DIR, "Line_Level_Features")
os.makedirs(OUTPUT_DIR, exist_ok=True)

def strip_comments(code):
    # Strip block comments
    code = re.sub(r'/\*[\s\S]*?\*/', '', code)
    # Strip line comments
    code = re.sub(r'//.*?\n', '\n', code)
    return code

def strip_boilerplate(code):
    # Safely strip interface and library declarations using balanced brace matching
    pattern = re.compile(r'\b(interface|library)\s+\w+')
    while True:
        match = pattern.search(code)
        if not match:
            break
        start_idx = match.start()
        # Find opening brace '{'
        brace_idx = code.find('{', start_idx)
        if brace_idx == -1:
            code = code[:start_idx] + code[match.end():]
            continue
        # Find matching closing brace
        brace_count = 1
        curr_idx = brace_idx + 1
        while curr_idx < len(code) and brace_count > 0:
            if code[curr_idx] == '{':
                brace_count += 1
            elif code[curr_idx] == '}':
                brace_count -= 1
            curr_idx += 1
        if brace_count == 0:
            code = code[:start_idx] + code[curr_idx:]
        else:
            code = code[:start_idx] + code[brace_idx:]
    return code

def is_functional_row(line):
    line_clean = line.strip()
    if not line_clean:
        return False
    # Exclude lines that only contain punctuation/structural characters (e.g. '{', '}', ';', '};')
    if re.match(r'^[{}();,\s]*$', line_clean):
        return False
    return True

def map_line_to_node_vector(line):
    features = [0] * 9
    line_lower = line.lower()
    
    # Feature Map Vector Schema for Solidity:
    # 0: Contract Core
    # 1: Interface
    # 2: Function
    # 3: Modifier
    # 4: Reentrancy Hook / Critical Attack Hook
    # 5: If/Else Branch
    # 6: Loop/Require Guard
    # 7: Math Op
    # 8: Assignment Op
    
    if "contract " in line_lower: features[0] = 1
    if "interface " in line_lower: features[1] = 1
    if "function " in line_lower: features[2] = 1
    if "modifier " in line_lower: features[3] = 1
    
    if any(kw in line_lower for kw in ['call{', 'delegatecall', 'tx.origin', 'selfdestruct']):
        features[4] = 1
        
    if "if " in line_lower or "if(" in line_lower or "else" in line_lower:
        features[5] = 1
        
    if any(kw in line_lower for kw in ['require', 'assert', 'revert']):
        features[6] = 1
        
    if any(op in line_lower for op in ['+', '-', '*', '/']):
        features[7] = 1
        
    if '=' in line_lower and '==' not in line_lower and '<=' not in line_lower and '>=' not in line_lower and '!=' not in line_lower:
        features[8] = 1

    if sum(features) == 0:
        features[8] = 1  # Fallback safeguard
        
    return features

def process_solidity_file(file_path):
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        raw_code = f.read()
        
    # 1. Strip comments
    code_no_comments = strip_comments(raw_code)
    
    # 2. Strip boilerplate (interfaces, libraries)
    cleaned_code = strip_boilerplate(code_no_comments)
    
    # 3. Process line by line to extract functional rows and feature vectors
    lines = cleaned_code.split('\n')
    functional_rows = []
    node_vectors = []
    
    for line_num, line in enumerate(lines, 1):
        if is_functional_row(line):
            vector = map_line_to_node_vector(line)
            functional_rows.append({
                "line_num": line_num,
                "content": line.strip(),
                "vector": vector
            })
            node_vectors.append(vector)
            
    return functional_rows, node_vectors

def main():
    print("Starting line-level GNN node feature extraction...")
    summary_records = []
    
    for root, dirs, files in os.walk(DATASET_DIR):
        # Avoid traversing output directory recursively
        if "Line_Level_Features" in root:
            continue
        for file in files:
            if file.endswith('.sol'):
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, DATASET_DIR)
                
                try:
                    rows, vectors = process_solidity_file(file_path)
                    
                    if not rows:
                        print(f"I> No functional rows extracted for {rel_path}")
                        continue
                    
                    # Save individual JSON payload
                    clean_name = file.replace('.sol', '')
                    payload = {
                        "file_name": file,
                        "relative_path": rel_path,
                        "functional_rows": rows
                    }
                    
                    output_file_name = f"features_{clean_name}.json"
                    output_file_path = os.path.join(OUTPUT_DIR, output_file_name)
                    with open(output_file_path, 'w', encoding='utf-8') as out_f:
                        json.dump(payload, out_f, indent=2)
                        
                    summary_records.append({
                        "file": file,
                        "relative_path": rel_path,
                        "functional_rows_count": len(rows)
                    })
                    
                except Exception as e:
                    print(f"X> Error processing {rel_path}: {e}")
                    
    # Save master summary CSV
    summary_csv_path = os.path.join(OUTPUT_DIR, "extraction_summary.csv")
    with open(summary_csv_path, 'w', newline='', encoding='utf-8') as csv_f:
        fieldnames = ["file", "relative_path", "functional_rows_count"]
        writer = csv.DictWriter(csv_f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(summary_records)
        
    print(f"Success! Processed {len(summary_records)} files.")
    print(f"Line level features saved in: {OUTPUT_DIR}")
    print(f"Summary saved in: {summary_csv_path}")

if __name__ == "__main__":
    main()
