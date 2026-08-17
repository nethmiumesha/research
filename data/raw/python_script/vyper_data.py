import requests
import os
import time
import base64

# --- CONFIGURATION ---
GITHUB_TOKEN = "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" 
SAVE_PATH = r"C:\Users\umesha 1096\Desktop\my_research\data\raw\Vyper\Github_Scraped"
TARGET_COUNT = 1300

headers = {"Authorization": f"token {GITHUB_TOKEN}"}

# Ensure the directory exists
if not os.path.exists(SAVE_PATH):
    os.makedirs(SAVE_PATH)

def download_vyper_files():
    # Count existing files to resume from where the script stopped
    existing_files = os.listdir(SAVE_PATH)
    count = len(existing_files)
    print(f"Current progress: {count} files found. Resuming download...")

    # Calculate the starting page (GitHub provides 100 results per page)
    page = (count // 100) + 1 
    
    while count < TARGET_COUNT:
        # Search query for Vyper files
        url = f"https://api.github.com/search/code?q=language:vyper+extension:vy&page={page}&per_page=100"
        
        try:
            response = requests.get(url, headers=headers, timeout=15).json()
            
            # Handle Secondary Rate Limits or API errors
            if 'items' not in response:
                print("API Limit reached or error occurred. Sleeping for 2 minutes...")
                time.sleep(120)
                continue
                
            for item in response['items']:
                if count >= TARGET_COUNT: break
                
                file_url = item['url']
                file_name = f"vyper_{count}_{item['name']}"
                
                try:
                    # Fetch the individual file content
                    res = requests.get(file_url, headers=headers, timeout=15).json()
                    if 'content' in res:
                        # GitHub returns content in Base64 encoding
                        code = base64.b64decode(res['content']).decode('utf-8', errors='ignore')
                        
                        file_full_path = os.path.join(SAVE_PATH, file_name)
                        with open(file_full_path, "w", encoding="utf-8") as f:
                            f.write(code)
                        
                        count += 1
                        if count % 20 == 0: 
                            print(f"Progress: {count}/{TARGET_COUNT} Vyper files downloaded...")
                
                except Exception as e:
                    print(f"Error downloading specific file: {e}")
                    time.sleep(5)
                
                # Sleep interval to avoid triggering GitHub's anti-abuse system
                time.sleep(1.5) 
            
            page += 1
            # Safety break if we run out of unique GitHub search results
            if page > 20: 
                print("Reached maximum available search results for Vyper.")
                break

        except Exception as e:
            print(f"Connection error: {e}. Retrying in 10 seconds...")
            time.sleep(10)

    print(f"Process complete. Total Vyper files in folder: {count}")

if __name__ == "__main__":
    download_vyper_files()