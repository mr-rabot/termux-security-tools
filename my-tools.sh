#!/bin/zsh

# Colors
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
GRAY='\033[0;37m'
NC='\033[0m'

# --- KNOWN SECURITY DATABASE ---
declare -A db
db=(
  [nmap]="RECON:Network/port scanner"
  [subfinder]="RECON:Passive subdomain discovery"
  [amass]="RECON:Attack surface mapping"
  [theharvester]="RECON:Email/subdomain OSINT"
  [sherlock]="RECON:Social media username hunt"
  [phoneinfoga]="RECON:Phone number OSINT"
  [recon-ng]="RECON:OSINT framework"
  [spiderfoot]="RECON:Automated OSINT"
  [shodan]="RECON:Internet device search"
  [whois]="RECON:Domain lookup"
  [dig]="RECON:DNS interrogation"
  [masscan]="SCAN:Fast port scanner"
  [nikto]="SCAN:Web server scanner"
  [dirb]="SCAN:Directory scanner"
  [gobuster]="SCAN:Directory/DNS brute-force"
  [ffuf]="SCAN:Fast web fuzzer"
  [nuclei]="SCAN:Vulnerability scanner"
  [netdiscover]="SCAN:ARP reconnaissance"
  [tshark]="SCAN:Packet analyzer (CLI)"
  [wireshark]="SCAN:Packet analyzer (GUI)"
  [katana]="SCAN:Web crawler"
  [waybackurls]="SCAN:Wayback URL fetcher"
  [metasploit]="EXPLOIT:Exploitation framework"
  [msfconsole]="EXPLOIT:Metasploit console"
  [hydra]="EXPLOIT:Login brute-forcer"
  [sqlmap]="EXPLOIT:SQL injection tool"
  [john]="EXPLOIT:Password hash cracker"
  [hashcat]="EXPLOIT:GPU password cracker"
  [netexec]="EXPLOIT:Network execution"
  [searchsploit]="EXPLOIT:Exploit DB search"
  [arjun]="EXPLOIT:HTTP param discovery"
  [medusa]="EXPLOIT:Login brute-forcer"
  [burpsuite]="EXPLOIT:Web proxy & testing suite"
  [dalfox]="EXPLOIT:Blind XSS scanner"
  [commix]="EXPLOIT:Command injection tool"
  [pacu]="EXPLOIT:AWS exploitation framework"
  [aircrack-ng]="WIRELESS:WiFi auditing suite"
  [macchanger]="WIRELESS:MAC address changer"
  [kismet]="WIRELESS:Wireless sniffer"
  [wifite]="WIRELESS:Auto WiFi auditor"
  [bully]="WIRELESS:WPS attack tool"
  [tor]="NETWORK:Anonymity network"
  [proxychains]="NETWORK:Force apps via proxy"
  [chisel]="NETWORK:HTTP tunnel for pivoting"
  [socat]="NETWORK:Multipurpose relay tool"
  [volatility3]="FORENSICS:Memory forensics"
  [binwalk]="FORENSICS:Firmware analysis"
  [exiftool]="FORENSICS:Metadata reader"
  [foremost]="FORENSICS:File carving"
  [pspy]="FORENSICS:Process monitor"
  [ghidra]="FORENSICS:Software reverse engineering"
  [radare2]="FORENSICS:Reverse engineering framework"
  [fail2ban]="DEFENSE:Intrusion prevention"
  [lynis]="DEFENSE:Security auditing"
  [chkrootkit]="DEFENSE:Rootkit detector"
  [rkhunter]="DEFENSE:Rootkit hunter"
  [trivy]="SCAN:Container vulnerability scanner"
)

# Category Labels
declare -A labels
labels=(
  [RECON]="RECONNAISSANCE & OSINT"
  [SCAN]="SCANNING & ENUMERATION"
  [EXPLOIT]="EXPLOITATION & PASSWORDS"
  [WIRELESS]="WIRELESS ATTACKS"
  [NETWORK]="NETWORK & ANONYMITY"
  [FORENSICS]="FORENSICS & REVERSE ENG"
  [DEFENSE]="DEFENSE & BLUE TEAM"
  [AUTO]="AUTO-DETECTED SECURITY TOOLS"
)

# --- AUTO-DETECTION (Only security patterns) ---
categorize_security() {
  local name=$1
  case "$name" in
    *2john)          echo "EXPLOIT:Password-to-hash converter" ;;
    airdecap*|airbase*|aireplay*|airmon*|airodump*|aircrack*|airolib*|buddy-ng|ivstools|kstats|makeivs*|packetforge*|wpaclean) 
                     echo "WIRELESS:Aircrack suite component" ;;
    *scan*|*enum*)   echo "SCAN:Scanning/Enumeration tool" ;;
    *crack*|*brute*) echo "EXPLOIT:Cracking/Brute-force tool" ;;
    *forensic*|*carv*|*recover*) echo "FORENSICS:Forensic analysis tool" ;;
    *proxy*|*tunnel*|*socks*) echo "NETWORK:Network tunneling/proxy" ;;
    *aws*|*cloud*|*kube*) echo "EXPLOIT:Cloud/Container security" ;;
    *xss*|*sqli*|*inject*) echo "EXPLOIT:Web vulnerability tool" ;;
    *hash*|*pass*|*cred*) echo "EXPLOIT:Credential/hash tool" ;;
    *)               return 1 ;;  # Not a security tool
  esac
}

# --- MAIN EXECUTION ---
echo ""
echo -e "${BLUE}===================================================${NC}"
echo -e "${BLUE}        ${CYAN}SECURITY TOOLBOX${BLUE}  -  Auto-Detected${NC}"
echo -e "${BLUE}===================================================${NC}"

declare -A found
total=0
global_count=1

# 1. Check ONLY the known database tools
for tool cat_desc in ${(kv)db}; do
  if command -v "$tool" >/dev/null 2>&1; then
    cat="${cat_desc%%:*}"
    desc="${cat_desc#*:}"
    found[$cat]+="${tool}|${desc}"$'\n'
    ((total++))
  fi
done

# 2. Auto-detect NEW security tools (only security patterns, NOT system utils)
declare -A already_seen
for tool in ${(k)db}; do already_seen[$tool]=1; done

for path in /usr/bin /usr/local/bin /root/go/bin; do
  [[ -d "$path" ]] || continue
  for bin in "$path"/*; do
    name="${bin:t}"
    [[ ! -x "$bin" ]] && continue
    [[ "$name" == *.* ]] && continue
    [[ -n "${already_seen[$name]}" ]] && continue
    
    result=$(categorize_security "$name")
    [[ $? -ne 0 ]] && continue  # Skip if not a security tool
    
    cat="${result%%:*}"
    desc="${result#*:}"
    found[$cat]+="${name}|${desc}"$'\n'
    ((total++))
    already_seen[$name]=1
  done
done

# --- PRINT OUTPUT ---
typeset -a order
order=(RECON SCAN EXPLOIT WIRELESS NETWORK FORENSICS DEFENSE AUTO)

for cat in $order; do
  if [[ -n "${found[$cat]}" ]]; then
    echo ""
    echo -e "${CYAN}--- ${labels[$cat]} ---${NC}"
    
    local items=("${(@f)${found[$cat]%$'\n'}}")
    local sorted=("${(@o)items}")
    
    for item in $sorted; do
      name="${item%%|*}"
      desc="${item#*|}"
      printf "${GRAY}%3d.${NC} ${GREEN}[+]${NC} ${YELLOW}%-20s${NC} %s\n" "$global_count" "$name" "$desc"
      ((global_count++))
    done
  fi
done

echo ""
echo -e "${BLUE}===================================================${NC}"
echo -e "${GREEN}  Total Security Tools Installed: ${total}${NC}"
echo -e "${BLUE}===================================================${NC}"
echo ""
