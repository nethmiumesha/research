import os

# --- PATH CONFIGURATION ---
RUST_RAW_ROOT = r"C:\Users\umesha 1096\Desktop\my_research\data\raw\Rust"
# ඔයා සඳහන් කළ උප-ෆෝල්ඩර දෙකේ පථයන්
TARGET_SUBFOLDERS = ['SPL_Contracts', 'Github_Scraped']
IGNORE_KEYWORDS = ['test', 'tests', 'testing', 'mock', 'node_modules', 'target', '.git']

def profile_nested_rust_dataset():
    print("🔍 Commencing Structural Profiling of Nested Rust Dataset Pools...")
    
    single_files_pool = []
    folder_projects_pool = []
    
    if not os.path.exists(RUST_RAW_ROOT):
        print(f"❌ Root directory path does not exist: {RUST_RAW_ROOT}")
        return

    # මුලින්ම ප්‍රධාන root එකේ තියෙන items (jet-v2, mango-v3 වැනි ප්‍රධාන ප්‍රොජෙක්ට්ස්) බලනවා
    for item in os.listdir(RUST_RAW_ROOT):
        if item in TARGET_SUBFOLDERS:
            continue # උප-ෆෝල්ඩර දෙක පසුව වෙනමම ස්කෑන් කරන නිසා මෙතනදී මඟහරිනවා
            
        item_path = os.path.join(RUST_RAW_ROOT, item)
        if any(kw in item.lower() for kw in IGNORE_KEYWORDS):
            continue
            
        if os.path.isdir(item_path):
            if "Cargo.toml" in os.listdir(item_path) or "Anchor.toml" in os.listdir(item_path):
                folder_projects_pool.append(item_path)

    # දැන් ඔයා ඉල්ලපු SPL_Contracts සහ Github_Scraped ඇතුළත ගැඹුරටම ස්කෑන් කිරීම
    for sub in TARGET_SUBFOLDERS:
        sub_path = os.path.join(RUST_RAW_ROOT, sub)
        if not os.path.exists(sub_path):
            print(f"⚠️ Sub-folder path not found, skipping: {sub_path}")
            continue
            
        print(f"📂 Deep scanning sub-directory: {sub}")
        for item in os.listdir(sub_path):
            item_path = os.path.join(sub_path, item)
            if any(kw in item.lower() for kw in IGNORE_KEYWORDS):
                continue
                
            if os.path.isdir(item_path):
                # ෆෝල්ඩරයක් ඇතුළේ Cargo.toml තියෙනවා නම් ඒක Project එකක්
                if "Cargo.toml" in os.listdir(item_path) or "Anchor.toml" in os.listdir(item_path):
                    folder_projects_pool.append(item_path)
                else:
                    # Cargo.toml නැත්නම් ඒ ෆෝල්ඩරය ඇතුළේ තියෙන හැම .rs එකක්ම Single File එකක් ලෙස ගනියි
                    for root, _, files in os.walk(item_path):
                        for f in files:
                            if f.endswith(".rs") and not any(kw in f.lower() for kw in IGNORE_KEYWORDS):
                                single_files_pool.append(os.path.join(root, f))
            elif item.endswith(".rs"):
                single_files_pool.append(item_path)

    print("\n📊 --- NESTED DATASET STRUCTURE INSIGHTS ---")
    print(f"🔹 Total Folder Projects Discovered : {len(folder_projects_pool)}")
    print(f"🔹 Total Standalone Single (.rs) Files Discovered: {len(single_files_pool)}")
    print("---------------------------------------------")
    
    return len(folder_projects_pool), len(single_files_pool)

if __name__ == "__main__":
    profile_nested_rust_dataset()