import os

ROOT_DIR = r"C:\Users\numhe\OneDrive\Desktop\my_research (2)\data\labeled_dataset"

# Target extensions per language
LANG_EXTENSIONS = {
    "Solidity": [".sol"],
    "Rust": [".rs"],
    "Vyper": [".vy"],
    "Go": [".go"],
    "C++": [".cpp", ".hpp", ".h", ".cc"]
}

def scan_all_artifacts():
    print("=" * 105)
    print("🔍 COMPREHENSIVE DATASET AUDIT (SOURCE CODE, JSON GRAPHS & PyG .PT FILES)")
    print("=" * 105)
    print(f"{'Language':<10} | {'Category':<12} | {'Source Code':<14} | {'Graph JSON':<14} | {'Folders Count':<16} | {'PyG (.pt)':<12}")
    print("-" * 105)

    grand_sources = 0
    grand_jsons = 0
    grand_pts = 0

    for lang, src_exts in LANG_EXTENSIONS.items():
        lang_dir = os.path.join(ROOT_DIR, lang)
        if not os.path.exists(lang_dir):
            continue

        stats = {
            "Safe": {"src": 0, "json": 0, "folders": 0, "pt": 0},
            "Vulnerable": {"src": 0, "json": 0, "folders": 0, "pt": 0}
        }

        for root, dirs, files in os.walk(lang_dir):
            root_lower = root.lower()
            
            # Determine Category
            cat = None
            if "safe" in root_lower or "non-vulnerable" in root_lower or "clean" in root_lower:
                cat = "Safe"
            elif "vulnerab" in root_lower or "vuln" in root_lower or "bad" in root_lower:
                cat = "Vulnerable"

            # Check PyG Processed Dataset folder directly
            if "pyg_processed_dataset" in root_lower:
                for f in files:
                    if f.endswith(".pt"):
                        # Count labels from file or filename convention
                        if "safe" in f.lower() or "_0.pt" in f:
                            stats["Safe"]["pt"] += 1
                        else:
                            stats["Vulnerable"]["pt"] += 1
                continue

            if not cat:
                continue

            # Count Source code files
            src_count = sum(1 for f in files if any(f.endswith(e) for e in src_exts))
            # Count JSON graph files
            json_count = sum(1 for f in files if f.endswith(".json"))

            stats[cat]["src"] += src_count
            stats[cat]["json"] += json_count
            
            if "folder" in root_lower or "project" in root_lower:
                if len(files) > 0:
                    stats[cat]["folders"] += 1

        for cat_name, val in stats.items():
            print(f"{lang:<10} | {cat_name:<12} | {val['src']:<14} | {val['json']:<14} | {val['folders']:<16} | {val['pt']:<12}")
            grand_sources += val["src"]
            grand_jsons += val["json"]
            grand_pts += val["pt"]

        print("-" * 105)

    print("=" * 105)
    print(f"📊 TOTALS ACROSS ALL 5 LANGUAGES:")
    print(f"   • Total Source Code Files (.sol/.rs/etc) : {grand_sources}")
    print(f"   • Total Graph JSON Files                 : {grand_jsons}")
    print(f"   • Total PyTorch Geometric Graphs (.pt)   : {grand_pts}")
    print("=" * 105)

if __name__ == "__main__":
    scan_all_artifacts()