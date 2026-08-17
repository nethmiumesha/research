import requests
import os
import time
import re
import pandas as pd

# --- CONFIGURATION ---
API_KEY = "GAFJ9NBRUBNH76EWNTWRGSXYR81UWBK8ZH"
CSV_FILE = "sourcify_vyper_addresses.csv" # ඔබ අලුතින් සාදාගත් CSV එක
SAVE_PATH = r"C:\Users\umesha 1096\Desktop\my_research\data\raw\Vyper\Etherscan"
TARGET_COUNT = 1300 

# Folders නිර්මාණය කිරීම
os.makedirs(os.path.join(SAVE_PATH, "Source_Code"), exist_ok=True)
os.makedirs(os.path.join(SAVE_PATH, "ABI_JSON"), exist_ok=True)

def test_api_key():
    test_addr = "0xD533a949740bb3306d119CC777fa900bA034cd52"
    url = f"https://api.etherscan.io/v2/api?chainid=1&module=contract&action=getsourcecode&address={test_addr}&apikey={API_KEY}"
    try:
        response = requests.get(url, timeout=20)
        return response.json().get('status') == '1'
    except:
        return False

def download_vyper_data():
    if not test_api_key():
        print("\n❌ API KEY TEST FAILED! Please check your Etherscan API Key.")
        return
    
    # CSV එක කියවීම
    try:
        df = pd.read_csv(CSV_FILE)
        addresses = df['ContractAddress'].unique().tolist()
        print(f"\n🚀 Total unique addresses to check from CSV: {len(addresses)}")
    except Exception as e:
        print(f"❌ Error reading CSV: {e}")
        return

    success_count = 0
    checked_count = 0
    
    for addr in addresses:
        if success_count >= TARGET_COUNT:
            break
            
        checked_count += 1
        url = f"https://api.etherscan.io/v2/api?chainid=1&module=contract&action=getsourcecode&address={addr}&apikey={API_KEY}"
        
        try:
            response = requests.get(url, timeout=30) 
            data = response.json()
            
            if data.get('status') == '1':
                result = data.get('result', [{}])[0]
                compiler = result.get('CompilerVersion', '').lower()
                source_code = result.get('SourceCode', '')
                abi_data = result.get('ABI', '')

                # Vyper කොන්ත්‍රාත්තුවක් දැයි තහවුරු කිරීම
                if "vyper" in compiler and source_code:
                    contract_name = result.get('ContractName', 'Unknown')
                    clean_name = re.sub(r'[\\/*?:"<>|]', "", contract_name)
                    
                    # 1. Source Code එක Save කිරීම (.vy)
                    vy_path = os.path.join(SAVE_PATH, "Source_Code", f"{addr}_{clean_name}.vy")
                    with open(vy_path, "w", encoding="utf-8") as f:
                        f.write(f"# Compiler: {compiler}\n# Address: {addr}\n\n{source_code}")
                    
                    # 2. ABI එක Save කිරීම (.json) - ඔබේ Navigation UI එකට මෙය ඉතා වැදගත්
                    if abi_data:
                        abi_path = os.path.join(SAVE_PATH, "ABI_JSON", f"{addr}_{clean_name}.json")
                        with open(abi_path, "w", encoding="utf-8") as f:
                            f.write(abi_data)
                    
                    success_count += 1
                    print(f"✅ [{checked_count}] [VYPER FOUND {success_count}]: {contract_name}")
                else:
                    if checked_count % 50 == 0:
                        print(f"Checked {checked_count} addresses... (Finding Vyper is hard!)")

        except Exception as e:
            print(f"⚠️ Error for {addr}: {e}")
            time.sleep(2)
            continue
        
        # Free Tier API එක නිසා තත්පරයකට calls 5 කට සීමා වේ
        time.sleep(0.25)

    print(f"\n🎯 DONE! Collected {success_count} Vyper contracts and their ABIs.")

if __name__ == "__main__":
    download_vyper_data()