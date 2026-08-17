import os, glob, torch
from torch_geometric.data import Data

BASE_DIR = r"C:\Users\numhe\OneDrive\Desktop\my_research (2)\data\labeled_dataset\Solidity"
OUT_DIR = os.path.join(BASE_DIR, "PyG_Project_Level_Dataset")
os.makedirs(OUT_DIR, exist_ok=True)

def extract_solidity_features(chunk_str):
    features = [0.0] * 9
    c = chunk_str.lower()
    lines = chunk_str.splitlines()
    features[0] = min(len(lines) / 100.0, 1.0)
    features[1] = min(sum(1 for l in lines if any(k in l for k in ['if ', 'for ', 'while '])) / 10.0, 1.0)
    if any(k in c for k in ['contract ', 'interface ', 'function ']): features[2] = 1.0
    if any(k in c for k in ['call{', 'call.value', 'delegatecall', 'selfdestruct', 'tx.origin', 'transfer(']): features[4] = 1.0
    if any(k in c for k in ['require', 'assert', 'revert']): features[6] = 1.0
    if any(op in c for op in ['+', '-', '*', '/']): features[7] = 1.0
    if '=' in c and '==' not in c: features[8] = 1.0
    if sum(features) == 0: features[8] = 1.0
    return features

def build_combined_graph(files, label):
    all_chunks, offsets = [], []
    for fp in files:
        try:
            with open(fp, 'r', encoding='utf-8', errors='ignore') as f: code = f.read()
            chunks = [c for c in code.split('\n\n') if c.strip()] or [code]
            offsets.append((len(all_chunks), len(chunks)))
            all_chunks.extend(chunks)
        except Exception: pass
    if not all_chunks: return None

    x = torch.tensor([extract_solidity_features(c) for c in all_chunks], dtype=torch.float)
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
    print("🚀 Building Solidity Project-Level Graphs...")
    for old_f in glob.glob(os.path.join(OUT_DIR, "*.pt")): os.remove(old_f)
    counts = {"Safe": 0, "Vulnerable": 0}
    for split, label in [("Safe", 0), ("Vulnerable", 1)]:
        s_dir = os.path.join(BASE_DIR, split)
        # Single files
        for sf in glob.glob(os.path.join(s_dir, "Single_Files", "*.sol")):
            g = build_combined_graph([sf], label)
            if g:
                torch.save(g, os.path.join(OUT_DIR, f"sol_{split.lower()}_proj_{counts[split]:05d}.pt"))
                counts[split] += 1
        # Project Folders
        p_dir = os.path.join(s_dir, "Folders")
        if os.path.exists(p_dir):
            for pd in [os.path.join(p_dir, d) for d in os.listdir(p_dir) if os.path.isdir(os.path.join(p_dir, d))]:
                p_files = glob.glob(os.path.join(pd, "**", "*.sol"), recursive=True)
                if p_files:
                    g = build_combined_graph(p_files, label)
                    if g:
                        torch.save(g, os.path.join(OUT_DIR, f"sol_{split.lower()}_proj_{counts[split]:05d}.pt"))
                        counts[split] += 1
    print(f"✅ Solidity -> Safe Projects: {counts['Safe']} | Vuln Projects: {counts['Vulnerable']} | Total: {counts['Safe'] + counts['Vulnerable']}")

if __name__ == "__main__": run()