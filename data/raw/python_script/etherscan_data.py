import requests
import os
import time
import re
import json

# --- CONFIGURATION ---
API_KEY = "GAFJ9NBRUBNH76EWNTWRGSXYR81UWBK8ZH"
CSV_FILE = "export-verified-contractaddress-opensource-license.csv"
SAVE_PATH = r"C:\Users\umesha 1096\Desktop\my_research\data\raw\Solidity\Etherscan"
TARGET_COUNT = 350 

os.makedirs(SAVE_PATH, exist_ok=True)

def test_api_key():
    """Test if API key is working with Etherscan API V2"""
    test_addr = "0x7a250d5630b4cf539739df2c5dacb4c659f2488d"
    # V2 API requires chainid parameter (1 = Ethereum Mainnet)
    url = f"https://api.etherscan.io/v2/api?chainid=1&module=contract&action=getsourcecode&address={test_addr}&apikey={API_KEY}"
    
    print("="*60)
    print("TESTING API KEY WITH V2 ENDPOINT...")
    print(f"URL: {url.replace(API_KEY, '***API_KEY***')}")
    
    try:
        response = requests.get(url, timeout=15)
        print(f"Status Code: {response.status_code}")
        
        data = response.json()
        print(f"API Status: {data.get('status')}")
        print(f"API Message: {data.get('message')}")
        
        if data.get('status') == '1':
            print("API KEY IS WORKING!")
            return True
        else:
            print("API KEY FAILED!")
            return False
            
    except Exception as e:
        print(f"REQUEST FAILED: {e}")
        return False

def extract_addresses(file_path):
    print("Reading CSV and extracting addresses...")
    addr_pattern = re.compile(r'0x[a-fA-F0-9]{40}')
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            addresses = list(set(addr_pattern.findall(content)))
            return [addr.lower() for addr in addresses]
    except Exception as e:
        print(f"Error reading CSV: {e}")
        return []

def clean_source_code(source_code):
    if not source_code:
        return None
        
    if source_code.startswith('{{') and source_code.endswith('}}'):
        try:
            parsed = json.loads(source_code[1:-1])
            if isinstance(parsed, dict) and 'sources' in parsed:
                combined = []
                for filepath, filedata in parsed['sources'].items():
                    content = filedata.get('content', '')
                    combined.append(f"// File: {filepath}\n{content}")
                return "\n\n".join(combined)
            return json.dumps(parsed, indent=2)
        except json.JSONDecodeError:
            source_code = source_code[1:-1]
    
    return source_code

def download_data():
    if not test_api_key():
        print("\nAPI KEY TEST FAILED! Exiting...")
        return
    
    all_addresses = extract_addresses(CSV_FILE)
    
    if len(all_addresses) == 0:
        print("No addresses found in CSV!")
        return
        
    if len(all_addresses) < 200:
        addresses = all_addresses
    else:
        addresses = all_addresses[200:1000] 
    
    print(f"\nTotal addresses found: {len(all_addresses)}")
    print(f"Starting to check {len(addresses)} samples...")
    print(f"Target: Collect {TARGET_COUNT} verified contracts\n")
    
    success_count = 0
    checked_count = 0
    no_code_count = 0
    
    for addr in addresses:
        if success_count >= TARGET_COUNT:
            break
            
        checked_count += 1
        
        # V2 API with chainid=1 (Ethereum Mainnet)
        url = f"https://api.etherscan.io/v2/api?chainid=1&module=contract&action=getsourcecode&address={addr}&apikey={API_KEY}"
        
        try:
            response = requests.get(url, timeout=15)
            data = response.json()
            
            if data.get('status') != '1':
                msg = data.get('message', 'Unknown')
                print(f"[{checked_count}] API Error for {addr}: {msg}")
                no_code_count += 1
                continue
                
            result = data.get('result', [{}])[0]
            source_code = result.get('SourceCode', '')
            contract_name = result.get('ContractName', 'Unknown')
            
            source_code = clean_source_code(source_code)
            
            if not source_code or len(source_code) < 100:
                print(f"[{checked_count}] No source code: {contract_name}")
                no_code_count += 1
                continue
            
            clean_name = re.sub(r'[\\/*?:"<>|]', "", contract_name) or "Unnamed"
            file_path = os.path.join(SAVE_PATH, f"{addr}_{clean_name}.sol")
            
            with open(file_path, "w", encoding="utf-8") as f:
                header = f"// Contract: {contract_name}\n"
                header += f"// Address: {addr}\n"
                header += f"// Compiler: {result.get('CompilerVersion', 'Unknown')}\n"
                header += f"// Chain ID: 1 (Ethereum Mainnet)\n"
                header += "//" + "="*50 + "\n\n"
                f.write(header + source_code)
            
            success_count += 1
            print(f"[{checked_count}] [{success_count}/{TARGET_COUNT}]: {contract_name} ({len(source_code)} chars)")
            
        except Exception as e:
            print(f"[{checked_count}] Exception for {addr}: {e}")
        
        # V2 API has same rate limits: 5 calls/sec for free tier
        time.sleep(0.25)
    
    print(f"\n{'='*60}")
    print(f"FINISHED!")
    print(f"Checked: {checked_count}")
    print(f"Downloaded: {success_count}")
    print(f"No code/errors: {no_code_count}")
    print(f"Success rate: {success_count/checked_count*100:.1f}%")
    print(f"{'='*60}")

if __name__ == "__main__":
    download_data()