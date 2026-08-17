import os
import shutil

SPL_SOURCE = r"C:\Users\umesha 1096\Downloads\solana-program-library-master"
SPL_DEST = r"C:\Users\umesha 1096\Desktop\my_research\data\raw\Rust\SPL_Contracts"

if not os.path.exists(SPL_DEST):
    os.makedirs(SPL_DEST)

count = 0
for root, dirs, files in os.walk(SPL_SOURCE):
    for file in files:
        if file.endswith(".rs"):
            src_file = os.path.join(root, file)
            dest_file = os.path.join(SPL_DEST, f"spl_{count}_{file}")
            shutil.copy2(src_file, dest_file)
            count += 1

print(f"Finished! Collected {count} Rust files from SPL.")