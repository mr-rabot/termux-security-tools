#!/usr/bin/env python3
import sys
import os
import argparse

# Colors
GREEN = '\033[1;32m'
YELLOW = '\033[1;33m'
BLUE = '\033[1;34m'
RED = '\033[1;31m'
NC = '\033[0m'

# File Signatures (Magic Bytes)
SIGNATURES = {
    'jpg': [b'\xFF\xD8\xFF'],
    'png': [b'\x89\x50\x4E\x47'],
    'pdf': [b'\x25\x50\x44\x46'],
    'zip': [b'\x50\x4B\x03\x04'],
}

def banner():
    print(f"{BLUE}")
    print("  =========================================")
    print("  |      DEEP-RECOVER v1.0                |")
    print("  |   File Carving & Memory Forensics     |")
    print("  =========================================")
    print(f"{NC}")

def carve_file(input_path, output_dir, extension, signature):
    found_count = 0
    print(f"{YELLOW}[*] Scanning for .{extension} files...{NC}")
    
    try:
        with open(input_path, 'rb') as f:
            chunk_size = 1024 * 1024  # 1MB chunks
            buffer = b""
            
            while True:
                chunk = f.read(chunk_size)
                if not chunk:
                    break
                
                buffer += chunk
                start = 0
                
                while True:
                    index = buffer.find(signature[0], start)
                    if index == -1:
                        break
                    
                    found_count += 1
                    filename = f"recovered_{found_count}.{extension}"
                    filepath = os.path.join(output_dir, filename)
                    
                    # Extract 5MB from that point
                    end_index = min(index + (5 * 1024 * 1024), len(buffer))
                    data = buffer[index:end_index]
                    
                    with open(filepath, 'wb') as out_f:
                        out_f.write(data)
                        
                    print(f"  {GREEN}[+]{NC} Found: {filename} at offset {index}")
                    start = index + 1
                
                # Keep last bytes for next chunk
                if len(buffer) > len(signature[0]):
                    buffer = buffer[-len(signature[0]):]
                else:
                    buffer = b""

    except Exception as e:
        print(f"{RED}[!] Error: {e}{NC}")
        
    return found_count

def main():
    banner()
    
    parser = argparse.ArgumentParser(description="Deep Data Recovery Tool")
    parser.add_argument("input", help="Path to disk image or memory dump")
    parser.add_argument("-o", "--output", help="Output directory", default="./recovered")
    parser.add_argument("-t", "--type", help="File type (jpg, png, pdf, zip)", default="all")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        print(f"{RED}[!] Input file not found: {args.input}{NC}")
        sys.exit(1)
        
    os.makedirs(args.output, exist_ok=True)
    
    print(f"{BLUE}[*] Target: {args.input}{NC}")
    print(f"{BLUE}[*] Output: {args.output}{NC}\n")
    
    total_found = 0
    types_to_scan = list(SIGNATURES.keys()) if args.type == "all" else [args.type]
    
    for ext in types_to_scan:
        if ext in SIGNATURES:
            sigs = SIGNATURES[ext]
            if sigs:
                count = carve_file(args.input, args.output, ext, sigs)
                total_found += count
                
    print(f"\n{GREEN}========================================={NC}")
    print(f"{GREEN}[+] Scan Complete. Recovered {total_found} fragments.{NC}")
    print(f"{GREEN}========================================={NC}")

if __name__ == "__main__":
    main()
