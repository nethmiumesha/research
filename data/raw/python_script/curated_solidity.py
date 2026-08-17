import os
import shutil
import random
import re

raw_data_path = r"C:\Users\umesha 1096\Desktop\my_research\data\raw\Solidity"
target_path = r"C:\Users\umesha 1096\Desktop\my_research\data\raw\Solidity\curated_solidity_1300"

sources = ["DAppSCAN", "Etherscan", "SmartBugs", "SolidiFI"]

TOTAL_REQUIRED = 1300
LIMIT_PER_SOURCE = 325

# Clean and shorten names (fix Windows issues)
def clean_name(name):
    name = re.sub(r'[<>:"/\\|?*]', '', name)  # remove invalid chars
    return name[:60]  # limit length

def curate_data():
    if not os.path.exists(target_path):
        os.makedirs(target_path)

    selected_files = {}
    total_selected = 0

    # First pass (take up to 325 per source)
    for source in sources:
        source_path = os.path.join(raw_data_path, source)

        if not os.path.exists(source_path):
            print(f"Missing source: {source}")
            selected_files[source] = []
            continue

        files = os.listdir(source_path)
        take = min(len(files), LIMIT_PER_SOURCE)

        chosen = random.sample(files, take)
        selected_files[source] = chosen

        total_selected += take
        print(f"{source}: taking {take}")

    # Second pass (fill remaining evenly)
    remaining = TOTAL_REQUIRED - total_selected
    print(f"\nRemaining to fill: {remaining}")

    while remaining > 0:
        progress = False

        for source in sources:
            if remaining <= 0:
                break

            source_path = os.path.join(raw_data_path, source)
            files = os.listdir(source_path)

            already_taken = set(selected_files[source])
            remaining_files = list(set(files) - already_taken)

            if not remaining_files:
                continue

            extra = random.choice(remaining_files)
            selected_files[source].append(extra)

            remaining -= 1
            progress = True

        if not progress:
            print(" Not enough files to reach 1300")
            break

    # Copy files
    total_copied = 0

    for source, items in selected_files.items():
        source_path = os.path.join(raw_data_path, source)

        for item in items:
            src_item_path = os.path.join(source_path, item)

            safe_name = clean_name(f"{source}_{item}")
            dest_item_path = os.path.join(target_path, safe_name)

            try:
                if os.path.isdir(src_item_path):
                    shutil.copytree(src_item_path, dest_item_path)
                else:
                    shutil.copy2(src_item_path, dest_item_path)

                total_copied += 1

            except Exception as e:
                print(f"Error copying {item}: {e}")

                # Retry with shorter name
                try:
                    short_name = clean_name(item)
                    dest_item_path = os.path.join(target_path, short_name)

                    if os.path.isdir(src_item_path):
                        shutil.copytree(src_item_path, dest_item_path)
                    else:
                        shutil.copy2(src_item_path, dest_item_path)

                    total_copied += 1

                except Exception as e2:
                    print(f"Still failed: {e2}")

    print(f"\n Done! Total files copied: {total_copied}")

if __name__ == "__main__":
    random.seed(42)  # optional reproducibility
    curate_data()