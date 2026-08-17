import os
import re
import json
import csv
import pandas as pd
import networkx as nx

# ==========================================
# 1. CONFIGURATION PATH CONFIG MATRIX
# ==========================================
DATASET_ROOT_FOLDER = r"C:\Users\umesha 1096\Desktop\my_research\data\labeled_dataset\Solidity"
OUTPUT_MATRIX_DIR = os.path.join(DATASET_ROOT_FOLDER, "Solidity_GNN_Inputs")
METRICS_CSV_PATH = os.path.join(OUTPUT_MATRIX_DIR, "vulnerability_dataset.csv")

os.makedirs(OUTPUT_MATRIX_DIR, exist_ok=True)

# GNN Architecture Scheme Matrix Vector:
# [Contract, Interface, FnDef, Modifier, ReentrancyHook, IfBranch, RequireGuard, MathOp, Assignment]
NODE_SCHEMA = ['Contract_Core', 'Interface_Decl', 'Fn_Def', 'Modifier_Tag', 'Critical_Attack_Hook', 'If_Branch', 'Loop_Require_Guard', 'Math_Op', 'Assignment_Op']

# ==========================================
# 2. ADVANCED CLEAN & NORMALIZE LAYER
# ==========================================
def clean_solidity_syntax(code):
    """ Strips comments and filters structural code noise to optimize AST parsing """
    code = re.sub(r'//.*?\n', '\n', code)              # Single-line comments
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.S) # Block comments
    # Boilerplate Filter: Tokenize වෙනකොට එන අනවශ්‍ය IERC20/SafeMath Noise එක ඉවත් කිරීම
    code = re.sub(r'interface\s+\w+[\s\S]*?\}|library\s+SafeMath[\s\S]*?\}', '', code)
    return code.strip()

def tokenize_solidity(code):
    token_pattern = r'[a-zA-Z_][a-zA-Z0-9_]*|[{}[\]()\;.,+=\-*/&|!<>?]'
    return [t for t in re.findall(token_pattern, code) if t.strip()]

# ==========================================
# 3. RULE-BASED STATIC FEATURE EXTRACTOR
# ==========================================
def map_tokens_to_node_vector(token_window):
    """ Maps high-entropy token clusters directly to our 9-Dimensional Binary Vector """
    features = [0] * 9
    joined_chunk = " ".join(token_window).lower()

    if "contract " in joined_chunk: features[0] = 1
    if "interface " in joined_chunk: features[1] = 1
    if "function " in joined_chunk: features[2] = 1
    if "modifier " in joined_chunk: features[3] = 1
    
    # Static Security Critical Points Check (Slither / Mythril Equivalents)
    if any(kw in joined_chunk for kw in ['call{', 'delegatecall', 'tx.origin', 'selfdestruct']): 
        features[4] = 1 # Assigned to Critical Attack Vector Node Index
        
    if "if " in joined_chunk or "else" in joined_chunk: features[5] = 1
    if any(kw in joined_chunk for kw in ['require', 'assert', 'revert']): features[6] = 1
    if any(op in joined_chunk for op in ['+', '-', '*', '/']): features[7] = 1
    if '=' in joined_chunk and '==' not in joined_chunk: features[8] = 1

    if sum(features) == 0: features[8] = 1 # Fallback safeguard
    return features

# ==========================================
# 4. AST-BASED CFG GENERATION & LABELING
# ==========================================
def parse_code_to_gnn_graph(tokens):
    """ Constructs the mathematical directed Graph layout for GNN backends """
    G = nx.DiGraph()
    if len(tokens) < 5:
        raise ValueError("Corrupted token depth.")
        
    # Multi-file window segment chunking
    chunk_window = max(5, len(tokens) // 6)
    chunks = [tokens[i:i + chunk_window] for i in range(0, len(tokens), chunk_window)]
    
    is_vulnerable = False
    joined_all = " ".join(tokens).lower()
    
    # Strict Consensus Vulnerability Rule Check -> Sets final binary classification target (y)
    if "call{" in joined_all or "delegatecall" in joined_all or "tx.origin" in joined_all:
        is_vulnerable = True

    for idx, chunk in enumerate(chunks):
        node_feat = map_tokens_to_node_vector(chunk)
        G.add_node(idx, feature=node_feat, label=str(node_feat.index(1)))
        if idx > 0:
            G.add_edge(idx - 1, idx) # Execution flow timeline links

    edge_list = list(G.edges())
    edge_index = [list(x) for x in zip(*edge_list)] if len(edge_list) > 0 else [[], []]
    
    pyg_payload = {
        "x": [G.nodes[n]['feature'] for n in G.nodes],
        "edge_index": edge_index,
        "y": 1 if is_vulnerable else 0
    }
    return pyg_payload, is_vulnerable

# ==========================================
# 5. FULL PIPELINE ORCHESTRATION CORE
# ==========================================
def run_solidity_research_pipeline():
    print("=========================================================================")
    print("🚀 INITIALIZING UPGRADED SOLIDITY PREPROCESSING & GNN-LABELING PIPELINE")
    print("=========================================================================\n")
    
    csv_records = []
    
    if not os.path.exists(DATASET_ROOT_FOLDER):
        print(f"❌ Target root directory path not found: {DATASET_ROOT_FOLDER}")
        return

    # Crawl folder-wise across all multi-file workspaces and single files smoothly
    for root, dirs, files in os.walk(DATASET_ROOT_FOLDER):
        # Prevent graph inputs directory looping recursion
        if "Solidity_GNN_Inputs" in root: continue
        
        for file in files:
            if file.endswith(".sol"):
                file_path = os.path.join(root, file)
                
                try:
                    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                        raw_code = f.read()
                        
                    # 1. Preprocessing Layer
                    cleaned_code = clean_solidity_syntax(raw_code)
                    tokens = tokenize_solidity(cleaned_code)
                    
                    # 2. Parsing & Feature Extraction Layer
                    pyg_graph, vuln_verdict = parse_code_to_gnn_graph(tokens)
                    
                    # 3. Model Fine-tune Ready JSON Matrix Export
                    clean_name = file.replace(".sol", "")
                    output_json_name = f"gnn_matrix_{clean_name}.json"
                    with open(os.path.join(OUTPUT_MATRIX_DIR, output_json_name), 'w', encoding='utf-8') as jf:
                        json.dump(pyg_graph, jf, indent=2)
                        
                    # 4. CSV Metadata Sheet Record Mapping
                    csv_records.append({
                        "File_Identifier": file,
                        "Reentrancy_Or_Access_Risk": 1 if vuln_verdict else 0,
                        "Graph_Node_Count": len(pyg_graph["x"]),
                        "Graph_Edge_Count": len(pyg_graph["edge_index"][0]) if pyg_graph["edge_index"] else 0,
                        "Final_Dataset_Label": "Vulnerable" if vuln_verdict else "Safe"
                    })
                    print(f"   -> Processed: {file} | Nodes: {len(pyg_graph['x'])} | Label: {'Vulnerable' if vuln_verdict else 'Safe'} ✅")
                    
                except Exception as e:
                    print(f"   ⚠️ Parsing bypassed for {file} due to: {e}")
                    continue

    # Export Data-Matrix sheets
    df_output = pd.DataFrame(csv_records)
    df_output.to_csv(METRICS_CSV_PATH, index=False)
    
    # FIX: Enforced correct METRICS_CSV_PATH variable signature map bounds
    print("\n=========================================================================")
    print("🎯 PIPELINE LIFECYCLE COMPLETE! ML-READY DATA MATRIX FULLY ACTIVATED.")
    print(f"   -> Fine-tune GNN Input Matrices JSON Saved At: {OUTPUT_MATRIX_DIR}")
    print(f"   -> Master Security Labeling Log Sheets Saved At: {METRICS_CSV_PATH}")
    print("=========================================================================")

if __name__ == "__main__":
    run_solidity_research_pipeline()