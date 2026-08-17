import os
import re

# ==========================================
# 1. CONFIGURATION PATHS FOR ALL LANGUAGES
# ==========================================
DATASET_ROOT_FOLDER = r"C:\Users\nethmi_h\Desktop\learn\my_research\my_research\data\labeled_dataset"

# ==========================================
# 2. LANGUAGE-SPECIFIC SYNTAX CLEANERS
# ==========================================

def clean_c_style_comments(code):
    """ Strips comments for Solidity, Rust, Go, and C++ (// and /* */) """
    # Multi-line comments /* ... */ 
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.DOTALL)
    # Single-line comments // ... 
    code = re.sub(r'//.*', '', code)
    
    clean_lines = [line.rstrip() for line in code.splitlines() if line.strip()]
    return "\n".join(clean_lines)

def clean_vyper_comments(code):
    """ Strips comments for Vyper (# and triple quotes) """
    # Triple-quoted multi-line comments (docstrings)  
    code = re.sub(r'"""[\s\S]*?"""', '', code)
    code = re.sub(r"'''[\s\S]*?'''", '', code)
    # Single-line comments # ...  
    code = re.sub(r'#.*', '', code)
    
    clean_lines = [line.rstrip() for line in code.splitlines() if line.strip()]
    return "\n".join(clean_lines)

# ==========================================
# 3. BOILERPLATE SUPPRESSION MATRIX
# ==========================================

def suppress_boilerplate(code, file_extension):
    """ Suppresses high-dimensional boilerplate noise dynamically based on language """
    lines = code.splitlines()
    optimized_lines = []
    skip_mode = False
    brace_count = 0
    
    for line in lines:
        stripped = line.strip()
        
        # Solidity Boilerplate Filter (SafeMath & IERC20)
        if file_extension == ".sol":
            if not skip_mode and ("library SafeMath" in line or "interface IERC20" in line):
                skip_mode = True
                brace_count = 0
            if skip_mode:
                brace_count += stripped.count("{")
                brace_count -= stripped.count("}")
                if brace_count <= 0 and "}" in stripped:
                    skip_mode = False
                continue
        
        # Rust (Solana) Boilerplate Filter (Empty/Test modules noise)
        elif file_extension == ".rs":
            if not skip_mode and "#[cfg(test)]" in line:
                skip_mode = True
                brace_count = 0
            if skip_mode:
                brace_count += stripped.count("{")
                brace_count -= stripped.count("}")
                if brace_count <= 0 and "}" in stripped:
                    skip_mode = False
                continue
                
        # Vyper Boilerplate Filter (Optional: Standard mock interfaces)
        elif file_extension == ".vy":
            if not skip_mode and "interface ERC20:" in line:
                skip_mode = True
                # Vyper uses indentation instead of braces, skip until indentation resets
                continue
            if skip_mode:
                if line.startswith(" ") or line.startswith("\t") or not line.strip():
                    continue
                else:
                    skip_mode = False

        optimized_lines.append(line)
        
    return "\n".join(optimized_lines)

# ==========================================
# 4. UNIFIED MULTI-LANGUAGE PIPELINE ORCHESTRATION
# ==========================================

def run_multilanguage_cleaner():
    print("=========================================================================")
    print("🚀 INITIALIZING MULTI-LANGUAGE IN-PLACE PREPROCESSING PIPELINE")
    print("=========================================================================")
    
    if not os.path.exists(DATASET_ROOT_FOLDER):
        print(f"❌ Error: Root directory path not found: {DATASET_ROOT_FOLDER}")
        return
        
    cleaned_count = 0
    supported_extensions = {".sol", ".rs", ".vy", ".go", ".cpp", ".h"}
    
    for root, dirs, files in os.walk(DATASET_ROOT_FOLDER):
        for file in files:
            name, ext = os.path.splitext(file)
            ext = ext.lower()
            
            if ext in supported_extensions:
                file_path = os.path.join(root, file)
                
                try:
                    # 1. initial file reading
                    with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                        raw_code = f.read()
                    
                    # 2. cleaning steps (Clean Comments)
                    if ext in {".sol", ".rs", ".go", ".cpp", ".h"}:
                        clean_code = clean_c_style_comments(raw_code)
                    elif ext == ".vy":
                        clean_code = clean_vyper_comments(raw_code)
                    
                    # 3. boilerplate removal (Boilerplate Suppression)
                    optimized_code = suppress_boilerplate(clean_code, ext)
                    
                    # 4. save in the same place, with the same name (In-place Overwrite)
                    with open(file_path, "w", encoding="utf-8") as f:
                        f.write(optimized_code)
                        
                    cleaned_count += 1
                    relative_path = os.path.relpath(file_path, DATASET_ROOT_FOLDER)
                    print(f"✅ In-place Cleaned [{ext.upper()}]: {relative_path}")
                    
                except Exception as e:
                    print(f"⚠️ Error cleaning file {file}: {e}")
                    
    print("=========================================================================")
    print(f"🎯 PIPELINE COMPLETE! Total Multi-Language Files Cleaned In-Place: {cleaned_count}")
    print("=========================================================================")

if __name__ == "__main__":
    run_multilanguage_cleaner()