import os
import shutil

# --- CONFIGURATION ---
SOURCE_BASE = r"C:\Users\umesha 1096\Desktop\my_research\data\raw"
DEST_BASE = r"C:\Users\umesha 1096\Desktop\my_research\data\processed_dataset"

LANG_CONFIG = {
    'Vyper': ['.vy'],
    'Rust': ['.rs'],
    'Go': ['.go'],
    'C++': ['.cpp', '.hpp', '.c', '.h'],
    'Solidity': ['.sol']
}

def organize_dataset():
    print("--- Starting Dataset Organization ---")
    
    for lang, extensions in LANG_CONFIG.items():
        source_lang_path = os.path.join(SOURCE_BASE, lang)
        dest_lang_path = os.path.join(DEST_BASE, lang)
        
        if not os.path.exists(source_lang_path):
            print(f"Skipping {lang}: Source folder not found.")
            continue
            
        count = 0
        print(f"\nProcessing {lang}...")

        for root, dirs, files in os.walk(source_lang_path):
            for file in files:
                if any(file.endswith(ext) for ext in extensions):
                    relative_path = os.path.relpath(root, source_lang_path)
                    target_dir = os.path.join(dest_lang_path, relative_path)
                    
                    os.makedirs(target_dir, exist_ok=True)
                    
                    src_file = os.path.join(root, file)
                    dst_file = os.path.join(target_dir, file)
                    
                    try:
                        shutil.copy2(src_file, dst_file)
                        count += 1
                    except Exception as e:
                        print(f"Error copying {file}: {e}")

        print(f"✅ {lang} Complete: {count} source files organized by project structure.")

    print("\n--- All Done! Check your 'processed_dataset' folder ---")

if __name__ == "__main__":
    organize_dataset()