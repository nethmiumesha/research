import os

# Root data directory
DATA_ROOT = r"C:\Users\numhe\OneDrive\Desktop\my_research (2)\data"

def inspect_tree(root_dir, max_depth=3):
    print("=" * 110)
    print(f"📂 DIRECTORY STRUCTURE & FILE INVENTORY MAP: {root_dir}")
    print("=" * 110)
    print(f"{'Relative Folder Path':<65} | {'Subfolders':<10} | {'.sol/.rs/.vy/.go/.cpp':<20} | {'.json':<8} | {'.pt':<6}")
    print("-" * 110)

    src_extensions = ('.sol', '.rs', '.vy', '.go', '.cpp', '.hpp', '.h', '.cc')

    root_dir = os.path.abspath(root_dir)
    root_level = root_dir.rstrip(os.sep).count(os.sep)

    for current_root, dirs, files in os.walk(root_dir):
        current_level = current_root.count(os.sep) - root_level
        if current_level > max_depth:
            continue

        rel_path = os.path.relpath(current_root, root_dir)
        if rel_path == ".":
            rel_path = "[ROOT] data"

        # Count file categories in this specific directory
        src_count = sum(1 for f in files if f.lower().endswith(src_extensions))
        json_count = sum(1 for f in files if f.lower().endswith('.json'))
        pt_count = sum(1 for f in files if f.lower().endswith('.pt'))
        subfolder_count = len(dirs)

        # Show if it has any relevant items or subfolders
        if src_count > 0 or json_count > 0 or pt_count > 0 or subfolder_count > 0 or current_level <= 2:
            # Indent visually based on depth
            indent = "  " * current_level
            display_name = indent + ("📁 " if subfolder_count > 0 else "📄 ") + os.path.basename(current_root)
            if current_root == root_dir:
                display_name = "📦 data"
                
            print(f"{display_name:<65} | {subfolder_count:<10} | {src_count:<20} | {json_count:<8} | {pt_count:<6}")

    print("=" * 110)

if __name__ == "__main__":
    inspect_tree(DATA_ROOT, max_depth=4)