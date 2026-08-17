import os
import re
import json
import csv
import pandas as pd
import networkx as nx

# ==========================================
# 1. CONFIGURATION PATH CONFIG MATRIX
# ==========================================
DATASET_ROOT_FOLDER = r"C:\Users\umesha 1096\Desktop\my_research\data\labeled_dataset\Rust"
OUTPUT_MATRIX_DIR = os.path.join(DATASET_ROOT_FOLDER, "Rust_GNN_Inputs")
METRICS_CSV_PATH = os.path.join(OUTPUT_MATRIX_DIR, "rust_vulnerability_dataset.csv")

os.makedirs(OUTPUT_MATRIX_DIR, exist_ok=True)

# GNN Architecture Scheme Matrix Vector for Rust:
# [Module, StructDecl, FnDef, MacroInvocation, UnsafeBlock, IfBranch, LoopBlock, MatchArm, Assignment]
NODE_SCHEMA = ['Module_Program', 'Struct_Decl', 'Fn_Def', 'Macro_Invocation', 'Unsafe_Critical', 'If_Branch', 'Loop_Block', 'Match_Arm', 'Assignment_Op']

# ==========================================
# 2. ADVANCED CLEAN & NORMALIZE LAYER
# ==========================================
def clean_rust_syntax(code):
    """ Strips rust block and line comments to optimize execution flow """
    code = re.sub(r'//.*?\n', '\n', code)              # Single-line comments
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.S) # Block comments
    return code.strip()

def tokenize_rust(code):
    token_pattern = r'[a-zA-Z_][a-zA-Z0-9_]*|#[^\]]*\]|::|[{}[\]()\;.,+=\-*/&|!<>?]'
    return [t for t in re.findall(token_pattern, code) if t.strip()]

# ==========================================
# 3. RULE-BASED STATIC FEATURE EXTRACTOR
# ==========================================
def map_rust_tokens_to_node_vector(token_window):
    features = [0] * 9
    joined_chunk = " ".join(token_window).lower()

    if "mod " in joined_chunk or "#[program]" in joined_chunk: features[0] = 1
    if "struct " in joined_chunk or "#[derive" in joined_chunk: features[1] = 1
    if "fn " in joined_chunk or "pub fn" in joined_chunk: features[2] = 1
    if "!" in joined_chunk and "!=" not in joined_chunk: features[3] = 1
    
    # Static Security Critical Points Check (Missing Constraints or Unsafe Memory)
    if any(kw in joined_chunk for kw in ['unsafe', 'unchecked', 'unbounded', 'panic!']): 
        features[4] = 1 # Assigned to Critical Attack Vector Node Index
        
    if "if " in joined_chunk or "else" in joined_chunk: features[5] = 1
    if "for " in joined_chunk or "while " in joined_chunk: features[6] = 1
    if "match " in joined_chunk: features[7] = 1
    if '=' in joined_chunk and '==' not in joined_chunk: features[8] = 1

    if sum(features) == 0: features[8] = 1
    return features

# ==========================================
# 4. AST-BASED CFG GENERATION & LABELING
# ==========================================
def parse_rust_to_gnn_graph(tokens):
    G = nx.DiGraph()
    if len(tokens) < 5:
        raise ValueError("Corrupted token depth.")
        
    chunk_window = max(5, len(tokens) // 6)
    chunks = [tokens[i:i + chunk_window] for i in range(0, len(tokens), chunk_window)]
    
    is_vulnerable = False
    joined_all = " ".join(tokens).lower()
    
    # Rules to identify Vulnerable Solana/Rust Footprints automatically
    # 1. Presence of 'unsafe' or 'unchecked' data structures
    # 2. Footprint indicators left during our balance synthesis phase
    if "unsafe" in joined_all or "unchecked" in joined_all or "unbounded" in joined_all or "is_vulnerable: true" in joined_all:
        is_vulnerable = True

    for idx, chunk in enumerate(chunks):
        node_feat = map_rust_tokens_to_node_vector(chunk)
        G.add_node(idx, feature=node_feat, label=str(node_feat.index(1)))
        if idx > 0:
            G.add_edge(idx - 1, idx)

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
def run_rust_research_pipeline():
    print("=========================================================================")
    print("🚀 INITIALIZING UPGRADED RUST PREPROCESSING & GNN-LABELING PIPELINE")
    print("=========================================================================\n")
    
    csv_records = []
    
    if not os.path.exists(DATASET_ROOT_FOLDER):
        print(f"❌ Target root directory path not found: {DATASET_ROOT_FOLDER}")
        return

    for root, dirs, files in os.walk(DATASET_ROOT_FOLDER):
        if "Rust_GNN_Inputs" in root: continue
        
        for file in files:
            if file.endswith(".rs"):
                file_path = os.path.join(root, file)
                
                try:
                    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                        raw_code = f.read()
                        
                    cleaned_code = clean_rust_syntax(raw_code)
                    tokens = tokenize_rust(cleaned_code)
                    pyg_graph, vuln_verdict = parse_rust_to_gnn_graph(tokens)
                    
                    clean_name = file.replace(".rs", "")
                    output_json_name = f"gnn_matrix_{clean_name}.json"
                    with open(os.path.join(OUTPUT_MATRIX_DIR, output_json_name), 'w', encoding='utf-8') as jf:
                        json.dump(pyg_graph, jf, indent=2)
                        
                    csv_records.append({
                        "File_Identifier": file,
                        "Unsafe_Or_Ownership_Risk": 1 if vuln_verdict else 0,
                        "Graph_Node_Count": len(pyg_graph["x"]),
                        "Graph_Edge_Count": len(pyg_graph["edge_index"][0]) if pyg_graph["edge_index"] else 0,
                        "Final_Dataset_Label": "Vulnerable" if vuln_verdict else "Safe"
                    })
                    print(f"   -> Processed: {file} | Nodes: {len(pyg_graph['x'])} | Label: {'Vulnerable' if vuln_verdict else 'Safe'} ✅")
                    
                except Exception as e:
                    continue

    df_output = pd.DataFrame(csv_records)
    df_output.to_csv(METRICS_PATH, index=False)
    print("\n=========================================================================")
    print(f"🎯 RUST PIPELINE COMPLETE! GNN JSON Inputs & CSV Metric Logs Saved under: {OUTPUT_MATRIX_DIR}")
    print("=========================================================================")

if __name__ == "__main__":
    run_rust_research_pipeline()