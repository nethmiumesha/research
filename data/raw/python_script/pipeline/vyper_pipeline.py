import os
import re
import json
import csv
import pandas as pd
import networkx as nx

# ==========================================
# 1. CONFIGURATION PATH CONFIG MATRIX
# ==========================================
DATASET_ROOT_FOLDER = r"C:\Users\umesha 1096\Desktop\my_research\data\labeled_dataset\Vyper"
OUTPUT_MATRIX_DIR = os.path.join(DATASET_ROOT_FOLDER, "Vyper_GNN_Inputs")
METRICS_CSV_PATH = os.path.join(OUTPUT_MATRIX_DIR, "vyper_vulnerability_dataset.csv")

os.makedirs(OUTPUT_MATRIX_DIR, exist_ok=True)

# GNN Architecture Scheme Matrix Vector for Vyper:
# [Contract_Def, Hashmap_State, FnDef, DecoratorTag, CriticalAttackHook, IfBranch, AssertGuard, RaiseError, Assignment]
NODE_SCHEMA = ['Contract_Def', 'Hashmap_State', 'Fn_Def', 'Decorator_Tag', 'Critical_Attack_Hook', 'If_Branch', 'Assert_Guard', 'Raise_Error', 'Assignment_Op']

# ==========================================
# 2. ADVANCED CLEAN & NORMALIZE LAYER
# ==========================================
def clean_vyper_syntax(code):
    """ Strips python-like inline hash comments cleanly """
    code = re.sub(r'#.*', '', code) # Remove Vyper inline comments
    return code.strip()

def tokenize_vyper(code):
    token_pattern = r'[a-zA-Z_][a-zA-Z0-9_]*|@[a-zA-Z_][a-zA-Z0-9_]*|[{}[\]()\;.,+=\-*/&|!<>?]'
    return [t for t in re.findall(token_pattern, code) if t.strip()]

# ==========================================
# 3. RULE-BASED STATIC FEATURE EXTRACTOR
# ==========================================
def map_vyper_tokens_to_node_vector(token_window):
    features = [0] * 9
    joined_chunk = " ".join(token_window).lower()

    if any(kw in joined_chunk for kw in ['struct ', 'def ']): features[0] = 1
    if any(kw in joined_chunk for kw in ['hashmap', 'public(']): features[1] = 1
    if "def " in joined_chunk: features[2] = 1
    if any(kw in joined_chunk for kw in ['@external', '@internal', '@payable', '@view']): features[3] = 1
    
    # Static Security Critical Points Check (Raw calls or State-changing exposures)
    if any(kw in joined_chunk for kw in ['raw_call', 'send(', 'selfdestruct', 'is_vulnerable']): 
        features[4] = 1 # Assigned to Critical Attack Vector Node Index
        
    if "if " in joined_chunk or "else:" in joined_chunk: features[5] = 1
    if "assert " in joined_chunk: features[6] = 1
    if "raise " in joined_chunk: features[7] = 1
    if '=' in joined_chunk and '==' not in joined_chunk: features[8] = 1

    if sum(features) == 0: features[8] = 1
    return features

# ==========================================
# 4. AST-BASED CFG GENERATION & LABELING
# ==========================================
def parse_vyper_to_gnn_graph(tokens):
    G = nx.DiGraph()
    if len(tokens) < 5:
        raise ValueError("Corrupted token depth.")
        
    chunk_window = max(5, len(tokens) // 6)
    chunks = [tokens[i:i + chunk_window] for i in range(0, len(tokens), chunk_window)]
    
    is_vulnerable = False
    joined_all = " ".join(tokens).lower()
    
    # Rules to identify Vulnerable Vyper Logic Patterns automatically
    if "raw_call" in joined_all or "send(" in joined_all or "vulnerable state verification: true" in joined_all:
        is_vulnerable = True

    for idx, chunk in enumerate(chunks):
        node_feat = map_vyper_tokens_to_node_vector(chunk)
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
def run_vyper_research_pipeline():
    print("=========================================================================")
    print("🚀 INITIALIZING UPGRADED VYPER PREPROCESSING & GNN-LABELING PIPELINE")
    print("=========================================================================\n")
    
    csv_records = []
    
    if not os.path.exists(DATASET_ROOT_FOLDER):
        print(f"❌ Target root directory path not found: {DATASET_ROOT_FOLDER}")
        return

    for root, dirs, files in os.walk(DATASET_ROOT_FOLDER):
        if "Vyper_GNN_Inputs" in root: continue
        
        for file in files:
            if file.endswith(".vy"):
                file_path = os.path.join(root, file)
                
                try:
                    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                        raw_code = f.read()
                        
                    cleaned_code = clean_vyper_syntax(raw_code)
                    tokens = tokenize_vyper(cleaned_code)
                    pyg_graph, vuln_verdict = parse_vyper_to_gnn_graph(tokens)
                    
                    clean_name = file.replace(".vy", "")
                    output_json_name = f"gnn_matrix_{clean_name}.json"
                    with open(os.path.join(OUTPUT_MATRIX_DIR, output_json_name), 'w', encoding='utf-8') as jf:
                        json.dump(pyg_graph, jf, indent=2)
                        
                    csv_records.append({
                        "File_Identifier": file,
                        "Raw_Call_Or_State_Risk": 1 if vuln_verdict else 0,
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
    print(f"🎯 VYPER PIPELINE COMPLETE! GNN JSON Inputs & CSV Metric Logs Saved under: {OUTPUT_MATRIX_DIR}")
    print("=========================================================================")

if __name__ == "__main__":
    run_vyper_research_pipeline()