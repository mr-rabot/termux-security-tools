#!/bin/bash

# Termux-Anonsurf - Privacy Tool with MAC Changer

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Please run as root${NC}"
    exit 1
fi

# Detect interface
get_interface() {
    # Try common interface names
    for iface in wlan0 eth0 wifi0; do
        if ip link show "$iface" 2>/dev/null | grep -q "state"; then
            echo "$iface"
            return 0
        fi
    done
    # Fallback: first non-lo interface
    ip -o link show | awk -F': ' '{print $2}' | grep -v "lo" | head -1
}

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "  ==========================================="
    echo "  |       TERMUX-ANONSURF v2.0              |"
    echo "  |   Tor + MAC Changer + IP Hiding         |"
    echo "  ==========================================="
    echo -e "${NC}"
}

# Show current MAC
show_mac() {
    local iface=$(get_interface)
    if [ -n "$iface" ]; then
        local mac=$(cat /sys/class/net/$iface/address 2>/dev/null)
        echo -e "${BLUE}[*] Interface: ${YELLOW}${iface}${NC}"
        echo -e "${BLUE}[*] Current MAC: ${YELLOW}${mac}${NC}"
    else
        echo -e "${RED}[!] No network interface found${NC}"
    fi
}

# Change MAC address
change_mac() {
    local iface=$(get_interface)
    
    if [ -z "$iface" ]; then
        echo -e "${RED}[!] No network interface found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[*] Changing MAC address on ${YELLOW}${iface}${NC}"
    
    # Check if macchanger is installed
    if ! command -v macchanger &> /dev/null; then
        echo -e "${RED}[!] macchanger not installed. Run: apt install macchanger${NC}"
        return 1
    fi
    
    # Bring interface down
    ip link set "$iface" down 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}[!] Cannot bring interface down (proot limitation)${NC}"
        echo -e "${YELLOW}[*] To change MAC, run from HOST Termux (not proot):${NC}"
        echo -e "${YELLOW}    su -c 'ip link set wlan0 down && macchanger -r wlan0 && ip link set wlan0 up'${NC}"
        return 1
    fi
    
    # Change MAC to random
    macchanger -r "$iface"
    
    # Bring interface up
    ip link set "$iface" up 2>/dev/null
    
    echo -e "${GREEN}[+] MAC address changed successfully${NC}"
    show_mac
}

# Reset MAC to original
reset_mac() {
    local iface=$(get_interface)
    
    if [ -z "$iface" ]; then
        echo -e "${RED}[!] No network interface found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}[*] Resetting MAC to permanent address...${NC}"
    
    ip link set "$iface" down 2>/dev/null
    macchanger -p "$iface"
    ip link set "$iface" up 2>/dev/null
    
    echo -e "${GREEN}[+] MAC address reset to original${NC}"
    show_mac
}

# Start Anonsurf
start_anonsurf() {
    echo -e "${BLUE}[*] Starting anonymous mode...${NC}"
    echo ""
    
    # Step 1: Change MAC (optional)
    echo -e "${CYAN}[Step 1/3] MAC Address Spoofing${NC}"
    change_mac
    echo ""
    
    # Step 2: Start Tor
    echo -e "${CYAN}[Step 2/3] Starting Tor${NC}"
    service tor start 2>/dev/null || tor &
    sleep 2
    
    if pgrep -x "tor" > /dev/null; then
        echo -e "${GREEN}[+] Tor service started${NC}"
    else
        echo -e "${RED}[!] Failed to start Tor${NC}"
        return 1
    fi
    echo ""
    
    # Step 3: Configure proxy
    echo -e "${CYAN}[Step 3/3] Configuring Proxy${NC}"
    cat > /etc/proxychains.conf << 'EOF'
[ProxyList]
socks5 127.0.0.1 9050
EOF
    
    export http_proxy="socks5://127.0.0.1:9050"
    export https_proxy="socks5://127.0.0.1:9050"
    export all_proxy="socks5://127.0.0.1:9050"
    
    echo -e "${GREEN}[+] Proxy configured${NC}"
    echo ""
    
    # Show status
    echo -e "${CYAN}[Status]${NC}"
    show_mac
    myip
    
    echo ""
    echo -e "${GREEN}[+] Anonymous mode ACTIVE${NC}"
    echo -e "${YELLOW}[*] Use 'proxychains <command>' to route apps through Tor${NC}"
}

# Stop Anonsurf
stop_anonsurf() {
    echo -e "${BLUE}[*] Stopping anonymous mode...${NC}"
    
    # Stop Tor
    pkill -x tor 2>/dev/null
    service tor stop 2>/dev/null
    echo -e "${GREEN}[+] Tor stopped${NC}"
    
    # Reset MAC
    echo -e "${BLUE}[*] Resetting MAC address...${NC}"
    reset_mac
    
    # Clear proxy
    unset http_proxy
    unset https_proxy
    unset all_proxy
    echo -e "${GREEN}[+] Proxy settings cleared${NC}"
    
    echo ""
    echo -e "${GREEN}[+] Anonymous mode DISABLED${NC}"
}

# Restart
restart_anonsurf() {
    stop_anonsurf
    sleep 2
    start_anonsurf
}

# Change identity
change_identity() {
    echo -e "${BLUE}[*] Requesting new Tor circuit...${NC}"
    
    kill -HUP $(pgrep -x tor) 2>/dev/null
    sleep 3
    
    echo -e "${GREEN}[+] New Tor circuit established${NC}"
    
    # Also change MAC for extra anonymity
    echo -e "${BLUE}[*] Changing MAC address...${NC}"
    change_mac
    
    myip
}

# Show IP
myip() {
    echo -e "${BLUE}[*] Checking current IP...${NC}"
    
    if command -v curl &> /dev/null; then
        ip=$(curl -s --socks5-hostname 127.0.0.1:9050 https://api.ipify.org 2>/dev/null)
        if [ -n "$ip" ]; then
            echo -e "${GREEN}[+] Current IP: ${YELLOW}${ip}${NC}"
            echo -e "${GREEN}[+] Traffic routed through Tor${NC}"
        else
            echo -e "${RED}[!] Could not determine IP${NC}"
        fi
    fi
}

# Status
status() {
    echo -e "${BLUE}[*] Anonsurf Status:${NC}"
    echo ""
    
    # Tor status
    if pgrep -x "tor" > /dev/null; then
        echo -e "${GREEN}[+] Tor: RUNNING${NC}"
    else
        echo -e "${RED}[-] Tor: STOPPED${NC}"
    fi
    
    # MAC status
    show_mac
    echo ""
    
    # IP status
    myip
}

# Help
show_help() {
    echo -e "${CYAN}Usage: anonsurf {start|stop|restart|change|myip|status|mac|reset-mac|help}${NC}"
    echo ""
    echo -e "${YELLOW}Commands:${NC}"
    echo "  start      - Start Tor + change MAC + configure proxy"
    echo "  stop       - Stop Tor + reset MAC + clear proxy"
    echo "  restart    - Restart everything"
    echo "  change     - Get new Tor circuit + new MAC"
    echo "  myip       - Show current IP through Tor"
    echo "  status     - Show full status"
    echo "  mac        - Change MAC address only"
    echo "  reset-mac  - Reset MAC to original"
    echo "  help       - Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  anonsurf start"
    echo "  proxychains nmap target"
    echo "  anonsurf change"
    echo "  anonsurf stop"
}

# Main
show_banner

case "$1" in
    start)      start_anonsurf ;;
    stop)       stop_anonsurf ;;
    restart)    restart_anonsurf ;;
    change)     change_identity ;;
    myip)       myip ;;
    status)     status ;;
    mac)        change_mac ;;
    reset-mac)  reset_mac ;;
    help|--help|-h|"")  show_help ;;
    *)
        echo -e "${RED}[!] Unknown command: $1${NC}"
        show_help
        exit 1
        ;;
esac
