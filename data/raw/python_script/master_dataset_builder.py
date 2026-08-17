import os
import glob
import json
import torch
import networkx as nx
from torch_geometric.data import Data

BASE_DIR = r"C:\Users\numhe\OneDrive\Desktop\my_research (2)\data\labeled_dataset"

LANG_EXTENSIONS = {
    "Solidity": [".sol"],
    "Rust": [".rs"],
    "Vyper": [".vy"],
    "Go": [".go"],
    "C++": [".cpp", ".hpp", ".h", ".cc"]
}

def extract_features(code_str, lang):
    features = [0.0] * 9
    code_lower = code_str.lower()
    lines = code_str.splitlines()

    # Feature 0: Density
    features[0] = min(len(lines) / 100.0, 1.0)
    # Feature 1: Control Depth
    features[1] = min(sum(1 for l in lines if any(k in l for k in ['if ', 'for ', 'while '])) / 10.0, 1.0)
    # Feature 2: State Writes / Allocations
    if any(k in code_lower for k in ['self.', 'mut ', 'state', 'storage', ' = ', '+=']): features[2] = 1.0
    # Feature 3: External Calls
    if any(k in code_lower for k in ['call{', 'call.value', 'raw_call', 'invoke', 'extern']): features[3] = 1.0
    # Feature 4: Delegate / Dynamic Dispatch
    if any(k in code_lower for k in ['delegatecall', 'unsafe', 'syscall', 'pointer']): features[4] = 1.0
    # Feature 5: Protection / Guards
    if any(k in code_lower for k in ['reentrant', 'nonreentrant', 'mutex', 'lock', 'guard']): features[5] = 1.0
    # Feature 6: Value / Asset Transfer
    if any(k in code_lower for k in ['transfer', 'send', 'msg.value', 'balance', 'coin', 'mint']): features[6] = 1.0
    # Feature 7: Destruct / Panic / Abort
    if any(k in code_lower for k in ['selfdestruct', 'panic!', 'abort', 'revert', 'assert']): features[7] = 1.0
    # Feature 8: Public / Entrypoints
    if any(k in code_lower for k in ['public', 'external', 'pub fn', 'export']): features[8] = 1.0

    return features

def build_graph_from_text(code_str, label, lang):
    chunks = [c for c in code_str.split('\n\n') if c.strip()]
    if not chunks:
        chunks = [code_str]

    node_features = [extract_features(c, lang) for c in chunks]
    x = torch.tensor(node_features, dtype=torch.float)
    num_nodes = len(node_features)

    if num_nodes > 1:
        src = list(range(num_nodes - 1)) + list(range(1, num_nodes))
        dst = list(range(1, num_nodes)) + list(range(num_nodes - 1))
        edge_index = torch.tensor([src, dst], dtype=torch.long)
    else:
        edge_index = torch.empty((2, 0), dtype=torch.long)

    y = torch.tensor([label], dtype=torch.long)
    return Data(x=x, edge_index=edge_index, y=y)

def process_language(lang):
    lang_root = os.path.join(BASE_DIR, lang)
    out_dir = os.path.join(lang_root, "PyG_Processed_Dataset")
    os.makedirs(out_dir, exist_ok=True)

    # Clean previous .pt
    for old_f in glob.glob(os.path.join(out_dir, "*.pt")):
        os.remove(old_f)

    splits = [
        ("Safe", 0),
        ("Vulnerable", 1)
    ]

    print(f"\n⚡ Processing {lang} Dataset...")
    counts = {0: 0, 1: 0}

    for cat_name, label in splits:
        cat_dir = os.path.join(lang_root, cat_name)
        if not os.path.exists(cat_dir):
            continue

        # 1. Look for pre-existing JSON graphs
        json_files = glob.glob(os.path.join(cat_dir, "**", "*.json"), recursive=True)
        for jf in json_files:
            try:
                with open(jf, 'r', encoding='utf-8') as f:
                    payload = json.load(f)
                x = torch.tensor(payload["x"], dtype=torch.float)
                if len(payload["edge_index"]) == 2 and len(payload["edge_index"][0]) > 0:
                    edge_index = torch.tensor(payload["edge_index"], dtype=torch.long)
                else:
                    edge_index = torch.empty((2, 0), dtype=torch.long)
                data = Data(x=x, edge_index=edge_index, y=torch.tensor([label], dtype=torch.long))
                torch.save(data, os.path.join(out_dir, f"{lang.lower()}_{cat_name.lower()}_json_{counts[label]:05d}.pt"))
                counts[label] += 1
            except Exception:
                pass

        # 2. Process all source files (Single Files + Folders)
        exts = LANG_EXTENSIONS[lang]
        src_files = [f for f in glob.glob(os.path.join(cat_dir, "**", "*"), recursive=True) if any(f.endswith(e) for e in exts)]

        for sf in src_files:
            try:
                with open(sf, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read()
                if len(content.strip()) < 10:
                    continue
                data = build_graph_from_text(content, label, lang)
                torch.save(data, os.path.join(out_dir, f"{lang.lower()}_{cat_name.lower()}_src_{counts[label]:05d}.pt"))
                counts[label] += 1
            except Exception:
                pass

    print(f"  [+] {lang} -> Safe (y=0): {counts[0]} | Vulnerable (y=1): {counts[1]} | Total .pt: {counts[0] + counts[1]}")

def main():
    print("=" * 80)
    print("🚀 MASTER RECURSIVE PyG DATASET GENERATION (ALL 5 LANGUAGES)")
    print("=" * 80)

    for lang in LANG_EXTENSIONS.keys():
        process_language(lang)

    print("\n" + "=" * 80)
    print("🎯 ALL 5 LANGUAGES SUCCESSFULLY COMPILED INTO PyG DATASETS!")
    print("=" * 80)

if __name__ == "__main__":
    main()