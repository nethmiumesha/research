import os, glob, torch
from torch_geometric.data import Data

BASE_DIR = r"C:\Users\numhe\OneDrive\Desktop\research\data\labeled_dataset\Vyper"
OUT_DIR = os.path.join(BASE_DIR, "PyG_Project_Level_Dataset")
os.makedirs(OUT_DIR, exist_ok=True)

def extract_vyper_features(chunk_str):
    features = [0.0] * 9
    c = chunk_str.lower()
    lines = chunk_str.splitlines()
    
    # 1. Code density
    features[0] = min(len(lines) / 80.0, 1.0)
    # 2. Control flow
    features[1] = min(sum(1 for l in lines if any(k in l for k in ['if ', 'for ', 'while '])) / 8.0, 1.0)
    # 3. Structural entity / decorators
    if any(k in c for k in ['@external', '@internal', '@view', '@pure', '@payable', 'def ']): 
        features[2] = 1.0
    # 4. State & visibility
    if any(k in c for k in ['public(', 'constant(', 'immutable(']): 
        features[3] = 1.0
    # 5. Critical Vulnerability Hooks (Reentrancy, raw_call, send, selfdestruct)
    if any(k in c for k in ['raw_call', 'send(', 'selfdestruct', 'create_minimal_proxy_to', 'raw_revert', 'unprotected']): 
        features[4] = 1.0
    # 6. Error handling & assertions
    if any(k in c for k in ['assert ', 'raise ', 'revert']): 
        features[5] = 1.0
    # 7. Arithmetic mutation & unsafe math
    if any(op in c for op in ['+', '-', '*', '/', '%', 'unsafe_add', 'unsafe_sub']): 
        features[6] = 1.0
    # 8. State variable assignment
    if '=' in c and '==' not in c and '<=' not in c and '>=' not in c and '!=' not in c: 
        features[7] = 1.0
    # 9. Fallback activation
    if any(k in c for k in ['__init__', '__default__', 'event ']): 
        features[8] = 1.0
    if sum(features) == 0: 
        features[8] = 1.0
        
    return features

def build_combined_graph(files, label):
    all_chunks, offsets = [], []
    for fp in files:
        try:
            with open(fp, 'r', encoding='utf-8', errors='ignore') as f: 
                code = f.read()
            chunks = [c for c in code.split('\n\n') if c.strip()] or [code]
            offsets.append((len(all_chunks), len(chunks)))
            all_chunks.extend(chunks)
        except Exception: 
            pass
    if not all_chunks: 
        return None

    x = torch.tensor([extract_vyper_features(c) for c in all_chunks], dtype=torch.float)
    edges = []
    for start, length in offsets:
        for i in range(start, start + length - 1):
            edges.extend([(i, i+1), (i+1, i)])
    if len(offsets) > 1:
        for start, _ in offsets[1:]:
            edges.extend([(0, start), (start, 0)])
    edge_index = torch.tensor(edges, dtype=torch.long).t().contiguous() if edges else torch.empty((2, 0), dtype=torch.long)
    return Data(x=x, edge_index=edge_index, y=torch.tensor([label], dtype=torch.long))

def run():
    print("🚀 Rebuilding Vyper Project-Level Graphs with Enhanced Security Features...")
    for old_f in glob.glob(os.path.join(OUT_DIR, "*.pt")): 
        os.remove(old_f)
    counts = {"Safe": 0, "Vulnerable": 0}
    for split, label in [("Safe", 0), ("Vulnerable", 1)]:
        s_dir = os.path.join(BASE_DIR, split)
        for sf in [f for f in glob.glob(os.path.join(s_dir, "Single_Files", "*")) if f.lower().endswith('.vy')]:
            g = build_combined_graph([sf], label)
            if g:
                torch.save(g, os.path.join(OUT_DIR, f"vyper_{split.lower()}_proj_{counts[split]:05d}.pt"))
                counts[split] += 1
        p_dir = os.path.join(s_dir, "Folders")
        if os.path.exists(p_dir):
            for pd in [os.path.join(p_dir, d) for d in os.listdir(p_dir) if os.path.isdir(os.path.join(p_dir, d))]:
                p_files = [f for f in glob.glob(os.path.join(pd, "**", "*"), recursive=True) if f.lower().endswith('.vy')]
                if p_files:
                    g = build_combined_graph(p_files, label)
                    if g:
                        torch.save(g, os.path.join(OUT_DIR, f"vyper_{split.lower()}_proj_{counts[split]:05d}.pt"))
                        counts[split] += 1
    print(f"✅ Vyper -> Safe: {counts['Safe']} | Vuln: {counts['Vulnerable']} | Total: {counts['Safe'] + counts['Vulnerable']}")

if __name__ == "__main__": 
    run()