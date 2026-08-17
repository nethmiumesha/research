import requests
import os
import time
import base64

# --- CONFIGURATION ---
GITHUB_TOKEN = "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"
SAVE_PATH = r"C:\Users\umesha 1096\Desktop\my_research\data\raw\Rust\GitHub_Scraped"
TARGET_COUNT = 1100

headers = {"Authorization": f"token {GITHUB_TOKEN}"}

if not os.path.exists(SAVE_PATH):
    os.makedirs(SAVE_PATH)

def download_rust_files(query):
    count = len(os.listdir(SAVE_PATH))
    page = 1
    
    while count < TARGET_COUNT:
        # Rust files (.rs) සහ විශේෂිත framework එකක් සෙවීම
        url = f"https://api.github.com/search/code?q={query}+extension:rs&page={page}&per_page=100"
        response = requests.get(url, headers=headers).json()
        
        if 'items' not in response:
            print("API Limit එකක් හෝ Error එකක් ආවා. විනාඩියක් ඉමු...")
            time.sleep(60)
            continue
            
        for item in response['items']:
            if count >= TARGET_COUNT: break
            
            file_url = item['url']
            file_name = f"rust_{count}_{item['name']}"
            
            # ගොනුවේ අන්තර්ගතය ලබාගැනීම
            file_data = requests.get(file_url, headers=headers).json()
            if 'content' in file_data:
                code = base64.b64decode(file_data['content']).decode('utf-8', errors='ignore')
                
                with open(os.path.join(SAVE_PATH, file_name), "w", encoding="utf-8") as f:
                    f.write(code)
                
                count += 1
                if count % 10 == 0: print(f"Downloaded {count}/{TARGET_COUNT} files...")
            
            time.sleep(1) # GitHub API limit නොවීමට
            
        page += 1
        if page > 10: break # පේජ් 10කට වඩා සෙවීම නවත්වන්න

if __name__ == "__main__":
    # Solana (anchor) සහ Near SDK දත්ත සොයමු
    print("Starting Rust Data Collection...")
    download_rust_files("anchor_lang") # Solana
    download_rust_files("near_sdk")    # Near
    print(f"Finished! Files saved at: {SAVE_PATH}")