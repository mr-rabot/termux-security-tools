# Termux-Security-Tools

My custom security toolbox for Termux + Ubuntu Proot.

## ??????? Tools Included

### `my-tools.sh`
Auto-detecting security toolbox that categorizes installed tools with colors and serial numbers.

**Features:**
- Auto-detects installed security tools
- Categorizes by: RECON, SCAN, EXPLOIT, WIRELESS, NETWORK, FORENSICS, DEFENSE
- Colorful output with serial numbers
- Smart pattern matching for unknown tools

**Usage:**
```bash
my-tools
```

### `anonsurf.sh`
Anonymous surfing tool (like Parrot OS Anonsurf) for Termux.

**Features:**
- Routes traffic through Tor
- MAC address spoofing
- Proxychains configuration
- Identity changing

**Usage:**
```bash
anonsurf start    # Start anonymous mode
anonsurf stop     # Stop anonymous mode
anonsurf change   # Get new Tor circuit + MAC
anonsurf myip     # Check current IP
anonsurf status   # Show full status
```

## ???? Installation

```bash
# Copy scripts to /usr/local/bin/
sudo cp my-tools.sh /usr/local/bin/my-tools
sudo cp anonsurf.sh /usr/local/bin/anonsurf
sudo chmod +x /usr/local/bin/my-tools /usr/local/bin/anonsurf
```

## ?????? Disclaimer
For educational purposes only. Use responsibly and legally.

### `deep-recover.py`
Forensic file carving tool for deep data recovery from disk images and memory dumps.

**Features:**
- Scans raw binary data for file signatures (magic bytes)
- Recovers deleted files: JPG, PNG, PDF, ZIP
- Works on disk images, partitions, and memory dumps
- Bypasses file system to find hidden data

**Usage:**
```bash
# Scan for all file types
deep-recover disk_image.img -o ./recovered

# Scan for specific type
deep-recover memory_dump.dmp -t jpg -o ./found_files
```

**Supported file types:** jpg, png, pdf, zip
