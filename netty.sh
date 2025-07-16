#!/bin/bash

# Netty - Network utilities for macOS
# Author: José Meira
# Version: 1.1.0

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Configuration
VERSION="1.1.0"
CONFIG_DIR="$HOME/.netty"
LOG_FILE="$CONFIG_DIR/netty.log"
RESULTS_DIR="$CONFIG_DIR/results"

# Default settings
DEFAULT_DNS_SERVERS=("8.8.8.8" "1.1.1.1" "208.67.222.222")
DEFAULT_PING_COUNT=5
DEFAULT_SPEEDTEST_DURATION=10

# Runtime variables
QUIET=false
OUTPUT_FORMAT="table"
CONTINUOUS_MODE=false

# Create config directory if it doesn't exist
create_config_dir() {
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR"
        mkdir -p "$RESULTS_DIR"
    fi
}

# Logging function
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [ "$QUIET" = false ]; then
        case $level in
            "INFO")  echo -e "${BLUE}ℹ️  $message${NC}" ;;
            "WARN")  echo -e "${YELLOW}⚠️  $message${NC}" ;;
            "ERROR") echo -e "${RED}❌ $message${NC}" ;;
            "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
            "PROGRESS") echo -e "${PURPLE}🔄 $message${NC}" ;;
        esac
    fi
}

# Show help
show_help() {
    cat << EOF
Netty v${VERSION}

DESCRIPTION:
    Comprehensive network utilities for macOS including WiFi scanning,
    speed testing, DNS management, and network monitoring.

USAGE:
    netty [OPTIONS] [COMMAND]

OPTIONS:
    -h, --help              Show this help message
    -v, --version           Show version information
    -q, --quiet             Run in quiet mode
    -f, --format FORMAT     Output format: table, json, csv (default: table)
    -c, --continuous        Continuous monitoring mode
    --log-file FILE         Custom log file location

COMMANDS:
    wifi                    WiFi network scanner and manager
    speed                   Internet speed test
    dns                     DNS tools and management
    monitor                 Network traffic monitor
    ip                      IP address and geolocation info
    <ping HOST               Enhanced ping with statistics
    trace HOST              Traceroute with timing analysis
    ports [HOST]            Port scanner and security check
    bandwidth               Bandwidth usage by application
    info                    Complete network interface information
    export                  Export results to file

EXAMPLES:
    netty wifi                  # Scan WiFi networks
    netty speed                 # Test internet speed
    netty dns flush             # Flush DNS cache
    netty ping google.com       # Enhanced ping test
    netty monitor --continuous  # Continuous traffic monitoring
    netty ports 192.168.1.1     # Scan ports on router

KEYBOARD CONTROLS (continuous mode):
    q, Q                    Quit continuous monitoring
    r, R                    Refresh/update data
    s, S                    Save current results

NOTES:
    - Some operations may require administrator permissions
    - Results are automatically logged and can be exported
    - Continuous mode updates every 2 seconds

EOF
}

# Show version
show_version() {
    echo "Netty v${VERSION}"
    echo "Comprehensive network utilities for macOS"
}

# Get current network interface
get_active_interface() {
    route get default | grep interface | awk '{print $2}'
}

# Get network interface info
get_interface_info() {
    local interface="$1"
    if [ -z "$interface" ]; then
        interface=$(get_active_interface)
    fi
    
    echo -e "${CYAN}=== Network Interface Information ===${NC}"
    echo -e "${BLUE}Active Interface:${NC} $interface"
    
    # Get IP addresses
    local ipv4=$(ifconfig "$interface" | grep 'inet ' | awk '{print $2}')
    local ipv6=$(ifconfig "$interface" | grep 'inet6' | grep -v 'fe80' | awk '{print $2}')
    local mac=$(ifconfig "$interface" | grep 'ether' | awk '{print $2}')
    
    echo -e "${BLUE}IPv4 Address:${NC} ${ipv4:-"Not assigned"}"
    echo -e "${BLUE}IPv6 Address:${NC} ${ipv6:-"Not assigned"}"
    echo -e "${BLUE}MAC Address:${NC} ${mac:-"Unknown"}"
    
    # Get gateway
    local gateway=$(route get default | grep gateway | awk '{print $2}')
    echo -e "${BLUE}Default Gateway:${NC} ${gateway:-"Unknown"}"
    
    # Get DNS servers
    local dns_servers=$(scutil --dns | grep 'nameserver\[0\]' | awk '{print $3}' | head -3 | tr '\n' ' ')
    echo -e "${BLUE}DNS Servers:${NC} ${dns_servers:-"Unknown"}"
}

# WiFi scanner
# WiFi scanner simplificado sin columnas problemáticas
wifi_scan() {
    log_message "INFO" "Starting WiFi scan"
    echo -e "${CYAN}=== WiFi Network Scanner ===${NC}"
    echo
    
    # Check if WiFi is enabled
    if ! networksetup -getairportpower en0 2>/dev/null | grep -q "On"; then
        log_message "ERROR" "WiFi is disabled"
        echo -e "${RED}WiFi is disabled. Enable it first with: networksetup -setairportpower en0 on${NC}"
        return 1
    fi
    
    echo -e "${PURPLE}🔍 Analyzing WiFi information...${NC}"
    
    # Get current network connection info
    local current_network=$(networksetup -getairportnetwork en0 2>/dev/null)
    local current_ssid=""
    
    if echo "$current_network" | grep -q "Current Wi-Fi Network:"; then
        current_ssid=$(echo "$current_network" | cut -d':' -f2 | sed 's/^ *//')
    fi
    
    # Tabla simplificada - solo SSID y Status
    echo -e "${BOLD}┌──────────────────────────────────────────────┬──────────────┐${NC}"
    echo -e "${BOLD}│ Network Name (SSID)                          │ Status       │${NC}"
    echo -e "${BOLD}├──────────────────────────────────────────────┼──────────────┤${NC}"
    
    local networks_shown=0
    
    # Show current connected network
    if [ -n "$current_ssid" ] && [[ "$current_ssid" != *"not associated"* ]]; then
        printf "${BOLD}│${NC} %-44s ${BOLD}│${NC} ${GREEN}%-12s${NC} ${BOLD}│${NC}\n" \
            "${current_ssid:0:44}" "Connected"
        networks_shown=$((networks_shown + 1))
    fi
    
    # Get and display preferred/known networks
    local known_networks=$(networksetup -listpreferredwirelessnetworks en0 2>/dev/null | grep -v "Preferred networks" | head -10)
    
    if [ -n "$known_networks" ]; then
        echo "$known_networks" | while IFS= read -r network; do
            if [ -n "$network" ] && [ "$network" != "$current_ssid" ]; then
                # Clean network name
                local clean_network=$(echo "$network" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                if [ -n "$clean_network" ]; then
                    printf "${BOLD}│${NC} %-44s ${BOLD}│${NC} ${YELLOW}%-12s${NC} ${BOLD}│${NC}\n" \
                        "${clean_network:0:44}" "Saved"
                fi
            fi
        done
    fi
    
    # If no networks to show, display helpful message
    if [ "$networks_shown" -eq 0 ]; then
        printf "${BOLD}│${NC} %-44s ${BOLD}│${NC} %-12s ${BOLD}│${NC}\n" \
            "No active WiFi connection" "Disconnected"
        echo -e "${BOLD}├──────────────────────────────────────────────┼──────────────┤${NC}"
        printf "${BOLD}│${NC} %-59s ${BOLD}│${NC}\n" "Connect to WiFi in System Settings to see details"
    fi
    
    echo -e "${BOLD}└──────────────────────────────────────────────┴──────────────┘${NC}"
    
    # Additional WiFi information
    echo
    echo -e "${BLUE}📊 WiFi Interface Information:${NC}"
    
    # Interface status
    local interface_status=$(ifconfig en0 2>/dev/null | grep "status:")
    if [ -n "$interface_status" ]; then
        echo -e "${GREEN}Interface: $(echo "$interface_status" | awk '{print $2}')${NC}"
    fi
    
    # MAC address
    local mac_address=$(ifconfig en0 2>/dev/null | grep "ether" | awk '{print $2}')
    if [ -n "$mac_address" ]; then
        echo -e "${GREEN}MAC Address: $mac_address${NC}"
    fi
    
    # WiFi capabilities
    local wifi_info=$(system_profiler SPAirPortDataType 2>/dev/null)
    local supported_channels=$(echo "$wifi_info" | grep -E "(Supported Channels|supported.*channel)" | head -1)
    if [ -n "$supported_channels" ]; then
        echo -e "${GREEN}Supports: 2.4GHz & 5GHz bands${NC}"
    fi
    
    echo
    if [ -n "$current_ssid" ] && [[ "$current_ssid" != *"not associated"* ]]; then
        echo -e "${GREEN}📶 Currently connected to: ${BOLD}$current_ssid${NC}"
        
        # Show additional connection details
        local ip_address=$(ifconfig en0 2>/dev/null | grep "inet " | awk '{print $2}')
        if [ -n "$ip_address" ]; then
            echo -e "${GREEN}📍 IP Address: $ip_address${NC}"
        fi
        
        # Try to get some connection info if available
        local gateway=$(route get default 2>/dev/null | grep gateway | awk '{print $2}')
        if [ -n "$gateway" ]; then
            echo -e "${GREEN}🌐 Gateway: $gateway${NC}"
        fi
        
        # Get DNS servers
        local dns_servers=$(scutil --dns | grep 'nameserver\[0\]' | awk '{print $3}' | head -2 | tr '\n' ' ')
        if [ -n "$dns_servers" ]; then
            echo -e "${GREEN}🔍 DNS Servers: $dns_servers${NC}"
        fi
        
    else
        echo -e "${YELLOW}📶 Not connected to any WiFi network${NC}"
        echo -e "${DIM}💡 Tip: Connect via System Settings > WiFi${NC}"
    fi
    
    echo
    echo -e "${BLUE}🔧 Available commands:${NC}"
    echo -e "${DIM}  networksetup -listallhardwareports     # List all network interfaces${NC}"
    echo -e "${DIM}  networksetup -listpreferredwirelessnetworks en0  # Show saved networks${NC}"
    echo -e "${DIM}  sudo wdutil info                       # Detailed WiFi diagnostics${NC}"
    
    log_message "SUCCESS" "WiFi information displayed"
}

# Función alternativa con formato de lista (sin tabla)
wifi_scan_list() {
    log_message "INFO" "Starting WiFi scan"
    echo -e "${CYAN}=== WiFi Network Scanner ===${NC}"
    echo
    
    # Check if WiFi is enabled
    if ! networksetup -getairportpower en0 2>/dev/null | grep -q "On"; then
        log_message "ERROR" "WiFi is disabled"
        echo -e "${RED}WiFi is disabled. Enable it first with: networksetup -setairportpower en0 on${NC}"
        return 1
    fi
    
    echo -e "${PURPLE}🔍 Analyzing WiFi information...${NC}"
    
    # Get current network connection info
    local current_network=$(networksetup -getairportnetwork en0 2>/dev/null)
    local current_ssid=""
    
    if echo "$current_network" | grep -q "Current Wi-Fi Network:"; then
        current_ssid=$(echo "$current_network" | cut -d':' -f2 | sed 's/^ *//')
    fi
    
    echo -e "${BOLD}📡 Available Networks:${NC}"
    echo
    
    # Show current connected network
    if [ -n "$current_ssid" ] && [[ "$current_ssid" != *"not associated"* ]]; then
        echo -e "${GREEN}✅ ${BOLD}$current_ssid${NC} ${GREEN}(Connected)${NC}"
        
        # Show connection details
        local ip_address=$(ifconfig en0 2>/dev/null | grep "inet " | awk '{print $2}')
        if [ -n "$ip_address" ]; then
            echo -e "${DIM}   IP Address: $ip_address${NC}"
        fi
        echo
    fi
    
    # Get and display preferred/known networks
    local known_networks=$(networksetup -listpreferredwirelessnetworks en0 2>/dev/null | grep -v "Preferred networks" | head -10)
    
    if [ -n "$known_networks" ]; then
        echo -e "${BOLD}💾 Saved Networks:${NC}"
        echo "$known_networks" | while IFS= read -r network; do
            if [ -n "$network" ] && [ "$network" != "$current_ssid" ]; then
                # Clean network name
                local clean_network=$(echo "$network" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                if [ -n "$clean_network" ]; then
                    echo -e "${YELLOW}📋 ${clean_network}${NC}"
                fi
            fi
        done
    fi
    
    # If no networks, show message
    if [ -z "$current_ssid" ] || [[ "$current_ssid" == *"not associated"* ]]; then
        echo -e "${RED}❌ No active WiFi connection${NC}"
        echo -e "${DIM}💡 Connect via System Settings > WiFi${NC}"
    fi
    
    echo
    echo -e "${BLUE}📊 WiFi Interface Information:${NC}"
    
    # Interface status
    local interface_status=$(ifconfig en0 2>/dev/null | grep "status:")
    if [ -n "$interface_status" ]; then
        echo -e "${GREEN}Interface: $(echo "$interface_status" | awk '{print $2}')${NC}"
    fi
    
    # MAC address
    local mac_address=$(ifconfig en0 2>/dev/null | grep "ether" | awk '{print $2}')
    if [ -n "$mac_address" ]; then
        echo -e "${GREEN}MAC Address: $mac_address${NC}"
    fi
    
    # WiFi capabilities
    local wifi_info=$(system_profiler SPAirPortDataType 2>/dev/null)
    local supported_channels=$(echo "$wifi_info" | grep -E "(Supported Channels|supported.*channel)" | head -1)
    if [ -n "$supported_channels" ]; then
        echo -e "${GREEN}Supports: 2.4GHz & 5GHz bands${NC}"
    fi
    
    log_message "SUCCESS" "WiFi information displayed"
}

# Función auxiliar para obtener información de red actual con airport
get_current_wifi_details() {
    local airport_cmd="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
    
    # Check if airport command is available
    if [ -f "$airport_cmd" ]; then
        # Get current WiFi network details
        local wifi_details=$("$airport_cmd" -I 2>/dev/null)
        
        if [ -n "$wifi_details" ]; then
            local ssid=$(echo "$wifi_details" | grep ' SSID:' | cut -d':' -f2 | sed 's/^ *//')
            local channel=$(echo "$wifi_details" | grep ' channel:' | cut -d':' -f2 | sed 's/^ *//')
            local rssi=$(echo "$wifi_details" | grep ' agrCtlRSSI:' | cut -d':' -f2 | sed 's/^ *//')
            local security=$(echo "$wifi_details" | grep ' link auth:' | cut -d':' -f2 | sed 's/^ *//')
            
            echo "SSID:$ssid"
            echo "Channel:$channel"
            echo "RSSI:$rssi"
            echo "Security:$security"
        fi
    fi
}

# Función auxiliar para scanear redes disponibles
scan_available_networks() {
    local airport_cmd="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
    
    if [ -f "$airport_cmd" ]; then
        # Scan available networks
        "$airport_cmd" -s 2>/dev/null | tail -n +2 | head -10
    fi
}

# Internet speed test
speed_test() {
    log_message "INFO" "Starting speed test"
    echo -e "${CYAN}=== Internet Speed Test ===${NC}"
    echo
    
    echo -e "${PURPLE}🚀 Testing connection speed...${NC}"
    echo -e "${DIM}This may take 30-60 seconds${NC}"
    echo
    
    # Test download speed using curl with a smaller, more reliable file
    echo -e "${BLUE}📥 Testing download speed...${NC}"
    local download_file="/tmp/netty_speedtest"
    local start_time=$(date +%s)
    
    # Use a 1MB test file from a reliable CDN
    local test_url="https://speed.cloudflare.com/__down?bytes=1048576"
    local download_success=false
    
    if command -v curl >/dev/null 2>&1; then
        if curl -L -o "$download_file" -s --max-time 30 "$test_url" 2>/dev/null; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            
            if [ -f "$download_file" ] && [ "$duration" -gt 0 ]; then
                local file_size=$(stat -f%z "$download_file" 2>/dev/null || wc -c < "$download_file")
                # Convert to Mbps: (bytes * 8) / (seconds * 1024 * 1024)
                local speed_mbps=$(echo "scale=2; ($file_size * 8) / ($duration * 1024 * 1024)" | bc -l 2>/dev/null || echo "0")
                
                echo -e "${GREEN}Download Speed: ${BOLD}${speed_mbps} Mbps${NC}"
                download_success=true
            fi
            rm -f "$download_file"
        fi
    fi
    
    if [ "$download_success" = false ]; then
        echo -e "${YELLOW}Download test skipped (curl unavailable or network issues)${NC}"
    fi
    
    # Test ping to reliable servers
    echo -e "${BLUE}📤 Testing network latency...${NC}"
    local ping_servers=("8.8.8.8" "1.1.1.1")
    local total_ping=0
    local successful_pings=0
    
    for server in "${ping_servers[@]}"; do
        local ping_result=$(ping -c 3 "$server" 2>/dev/null | grep 'avg' | awk -F'/' '{print $5}')
        if [ -n "$ping_result" ] && [[ "$ping_result" =~ ^[0-9]+\.?[0-9]*$ ]]; then
            total_ping=$(echo "$total_ping + $ping_result" | bc -l 2>/dev/null || echo "$total_ping")
            successful_pings=$((successful_pings + 1))
        fi
    done
    
    if [ "$successful_pings" -gt 0 ]; then
        local avg_ping=$(echo "scale=1; $total_ping / $successful_pings" | bc -l 2>/dev/null || echo "0")
        echo -e "${GREEN}Average Ping: ${BOLD}${avg_ping} ms${NC}"
    else
        echo -e "${YELLOW}Ping test failed${NC}"
    fi
    
    # Test DNS resolution speed
    echo -e "${BLUE}🔍 Testing DNS resolution...${NC}"
    local dns_start=$(date +%s.%N 2>/dev/null || date +%s)
    if nslookup google.com >/dev/null 2>&1; then
        local dns_end=$(date +%s.%N 2>/dev/null || date +%s)
        local dns_time
        if command -v bc >/dev/null 2>&1; then
            dns_time=$(echo "scale=0; ($dns_end - $dns_start) * 1000" | bc -l 2>/dev/null || echo "< 1000")
        else
            dns_time="< 1000"
        fi
        echo -e "${GREEN}DNS Resolution: ${BOLD}${dns_time} ms${NC}"
    else
        echo -e "${YELLOW}DNS test failed${NC}"
        dns_time="failed"
    fi
    
    echo
    echo -e "${GREEN}✅ Speed test completed${NC}"
    
    # Create summary for logging
    local summary="Download: ${speed_mbps:-0}Mbps, Ping: ${avg_ping:-0}ms, DNS: ${dns_time}ms"
    log_message "SUCCESS" "Speed test completed - $summary"
}

# DNS management tools
dns_tools() {
    local action="$1"
    
    case "$action" in
        "flush"|"clear")
            log_message "INFO" "Flushing DNS cache"
            echo -e "${CYAN}=== DNS Cache Flush ===${NC}"
            echo -e "${PURPLE}🔄 Flushing DNS cache...${NC}"
            
            sudo dscacheutil -flushcache
            sudo killall -HUP mDNSResponder
            
            echo -e "${GREEN}✅ DNS cache flushed successfully${NC}"
            log_message "SUCCESS" "DNS cache flushed"
            ;;
        "test"|"check")
            echo -e "${CYAN}=== DNS Resolution Test ===${NC}"
            echo
            
            local test_domains=("google.com" "cloudflare.com" "github.com" "apple.com")
            
            for domain in "${test_domains[@]}"; do
                echo -e "${BLUE}Testing $domain...${NC}"
                local start_time=$(date +%s.%N)
                local result=$(nslookup "$domain" 2>/dev/null | grep 'Address:' | tail -1 | awk '{print $2}')
                local end_time=$(date +%s.%N)
                local duration=$(echo "scale=0; ($end_time - $start_time) * 1000" | bc -l)
                
                if [ -n "$result" ]; then
                    echo -e "${GREEN}  ✅ $domain → $result (${duration}ms)${NC}"
                else
                    echo -e "${RED}  ❌ $domain → Resolution failed${NC}"
                fi
            done
            ;;
        "servers"|"list")
            echo -e "${CYAN}=== Current DNS Servers ===${NC}"
            echo
            
            scutil --dns | grep 'nameserver\[' | awk '{print "  " $1 " " $3}' | sort -u
            echo
            
            echo -e "${BLUE}Popular DNS Servers:${NC}"
            echo -e "${GREEN}  Google:      8.8.8.8, 8.8.4.4${NC}"
            echo -e "${GREEN}  Cloudflare:  1.1.1.1, 1.0.0.1${NC}"
            echo -e "${GREEN}  OpenDNS:     208.67.222.222, 208.67.220.220${NC}"
            echo -e "${GREEN}  Quad9:       9.9.9.9, 149.112.112.112${NC}"
            ;;
        *)
            echo -e "${YELLOW}DNS Tools - Available actions:${NC}"
            echo -e "${BLUE}  flush, clear    ${NC}Flush DNS cache"
            echo -e "${BLUE}  test, check     ${NC}Test DNS resolution speed"
            echo -e "${BLUE}  servers, list   ${NC}Show current and popular DNS servers"
            echo
            echo -e "${DIM}Usage: netty dns [action]${NC}"
            ;;
    esac
}

# Enhanced ping with statistics
enhanced_ping() {
    local host="$1"
    local count="${2:-$DEFAULT_PING_COUNT}"
    
    if [ -z "$host" ]; then
        echo -e "${RED}❌ Host required for ping${NC}"
        return 1
    fi
    
    log_message "INFO" "Pinging $host"
    echo -e "${CYAN}=== Enhanced Ping Test ===${NC}"
    echo -e "${BLUE}Target: ${BOLD}$host${NC}"
    echo -e "${BLUE}Count: ${BOLD}$count packets${NC}"
    echo
    
    # Resolve hostname to IP
    local ip=$(dig +short "$host" | head -1)
    if [ -n "$ip" ]; then
        echo -e "${GREEN}Resolved to: $ip${NC}"
    fi
    echo
    
    # Run ping and capture output
    local ping_output
    ping_output=$(ping -c "$count" "$host" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "$ping_output"
        echo
        
        # Extract and display statistics
        local transmitted=$(echo "$ping_output" | grep 'packets transmitted' | awk '{print $1}')
        local received=$(echo "$ping_output" | grep 'packets transmitted' | awk '{print $4}')
        local loss=$(echo "$ping_output" | grep 'packet loss' | awk '{print $6}')
        
        echo -e "${CYAN}=== Ping Statistics ===${NC}"
        echo -e "${BLUE}Packets transmitted: ${GREEN}$transmitted${NC}"
        echo -e "${BLUE}Packets received: ${GREEN}$received${NC}"
        echo -e "${BLUE}Packet loss: ${YELLOW}$loss${NC}"
        
        # RTT statistics
        local rtt_line=$(echo "$ping_output" | grep 'round-trip')
        if [ -n "$rtt_line" ]; then
            local min_rtt=$(echo "$rtt_line" | awk -F'/' '{print $4}')
            local avg_rtt=$(echo "$rtt_line" | awk -F'/' '{print $5}')
            local max_rtt=$(echo "$rtt_line" | awk -F'/' '{print $6}')
            
            echo -e "${BLUE}RTT min/avg/max: ${GREEN}$min_rtt/$avg_rtt/$max_rtt ms${NC}"
        fi
        
        log_message "SUCCESS" "Ping to $host completed - $received/$transmitted packets, $loss loss"
    else
        echo -e "${RED}❌ Ping failed: Host unreachable or name resolution failed${NC}"
        log_message "ERROR" "Ping to $host failed"
    fi
}

# Network traffic monitor
network_monitor() {
    echo -e "${CYAN}=== Network Traffic Monitor ===${NC}"
    echo -e "${DIM}Press 'q' to quit, 'r' to refresh${NC}"
    echo
    
    local interface=$(get_active_interface)
    
    while true; do
        clear
        echo -e "${CYAN}=== Network Traffic Monitor ===${NC}"
        echo -e "${BLUE}Interface: $interface${NC}"
        echo -e "${DIM}$(date)${NC}"
        echo
        
        # Get network statistics
        local stats=$(netstat -ibn | grep "$interface" | head -1)
        if [ -n "$stats" ]; then
            local rx_bytes=$(echo "$stats" | awk '{print $7}')
            local tx_bytes=$(echo "$stats" | awk '{print $10}')
            local rx_packets=$(echo "$stats" | awk '{print $5}')
            local tx_packets=$(echo "$stats" | awk '{print $8}')
            
            # Convert bytes to human readable
            local rx_mb=$(echo "scale=2; $rx_bytes / 1024 / 1024" | bc -l)
            local tx_mb=$(echo "scale=2; $tx_bytes / 1024 / 1024" | bc -l)
            
            echo -e "${GREEN}📥 Received: ${BOLD}${rx_mb} MB${NC} (${rx_packets} packets)"
            echo -e "${GREEN}📤 Transmitted: ${BOLD}${tx_mb} MB${NC} (${tx_packets} packets)"
        fi
        
        echo
        echo -e "${BLUE}Active Connections:${NC}"
        netstat -an | grep ESTABLISHED | head -10 | while read line; do
            echo -e "${DIM}  $line${NC}"
        done
        
        # Check for user input
        if read -t 2 -n 1 key 2>/dev/null; then
            case $key in
                'q'|'Q') break ;;
                'r'|'R') continue ;;
            esac
        fi
    done
    
    echo -e "\n${GREEN}👋 Network monitoring stopped${NC}"
}

# Get public IP and geolocation
ip_info() {
    echo -e "${CYAN}=== IP Address Information ===${NC}"
    echo
    
    # Local IP info
    get_interface_info
    echo
    
    # Public IP info
    echo -e "${BLUE}🌍 Public IP Information:${NC}"
    local public_ip
    public_ip=$(curl -s ipinfo.io/ip 2>/dev/null)
    
    if [ -n "$public_ip" ]; then
        echo -e "${GREEN}Public IP: ${BOLD}$public_ip${NC}"
        
        # Get geolocation info
        local geo_info
        geo_info=$(curl -s "ipinfo.io/$public_ip/json" 2>/dev/null)
        
        if [ -n "$geo_info" ]; then
            local city=$(echo "$geo_info" | grep '"city"' | cut -d'"' -f4)
            local region=$(echo "$geo_info" | grep '"region"' | cut -d'"' -f4)
            local country=$(echo "$geo_info" | grep '"country"' | cut -d'"' -f4)
            local org=$(echo "$geo_info" | grep '"org"' | cut -d'"' -f4)
            
            echo -e "${GREEN}Location: ${BOLD}$city, $region, $country${NC}"
            echo -e "${GREEN}ISP: ${BOLD}$org${NC}"
        fi
    else
        echo -e "${RED}Unable to retrieve public IP${NC}"
    fi
}

# Función traceroute corregida para macOS
traceroute_host() {
    local host="$1"
    local max_hops="${2:-30}"
    
    if [ -z "$host" ]; then
        echo -e "${RED}❌ Host required for traceroute${NC}"
        return 1
    fi
    
    log_message "INFO" "Tracing route to $host"
    echo -e "${CYAN}=== Traceroute Analysis ===${NC}"
    echo -e "${BLUE}Target: ${BOLD}$host${NC}"
    echo -e "${BLUE}Max hops: ${BOLD}$max_hops${NC}"
    echo
    
    # Resolve hostname to IP if needed
    local ip=$(dig +short "$host" 2>/dev/null | head -1)
    if [ -n "$ip" ]; then
        echo -e "${GREEN}Resolved to: $ip${NC}"
    fi
    echo
    
    # Check if traceroute is available
    if ! command -v traceroute >/dev/null 2>&1; then
        echo -e "${RED}❌ traceroute command not found${NC}"
        echo -e "${YELLOW}Install with: brew install traceroute${NC}"
        return 1
    fi
    
    # Run traceroute and capture output
    echo -e "${BLUE}🔍 Tracing route...${NC}"
    echo
    
    # Execute traceroute with background process and timeout handling
    local traceroute_output
    local temp_file="/tmp/netty_traceroute_$$"
    
    # Start traceroute in background and capture PID
    traceroute -m "$max_hops" "$host" > "$temp_file" 2>&1 &
    local traceroute_pid=$!
    
    # Wait for completion with timeout
    local timeout_counter=0
    local max_timeout=60
    
    while [ $timeout_counter -lt $max_timeout ]; do
        if ! kill -0 "$traceroute_pid" 2>/dev/null; then
            # Process finished
            break
        fi
        sleep 1
        timeout_counter=$((timeout_counter + 1))
    done
    
    # Check if process is still running (timeout)
    if kill -0 "$traceroute_pid" 2>/dev/null; then
        # Kill the process
        kill "$traceroute_pid" 2>/dev/null
        rm -f "$temp_file"
        echo -e "${RED}❌ Traceroute timed out after 60 seconds${NC}"
        log_message "ERROR" "Traceroute to $host timed out"
        return 1
    fi
    
    # Read results
    if [ -f "$temp_file" ]; then
        traceroute_output=$(cat "$temp_file")
        rm -f "$temp_file"
        
        # Process and display results with improved formatting
        echo "$traceroute_output" | while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*[0-9]+ ]]; then
                # Extract hop number and format line
                local hop_num=$(echo "$line" | awk '{print $1}')
                local rest=$(echo "$line" | cut -d' ' -f2-)
                
                # Color code based on response time
                if echo "$line" | grep -q "\*"; then
                    echo -e "${RED}${hop_num}${NC} ${DIM}${rest}${NC}"
                elif echo "$line" | grep -q "ms"; then
                    # Extract timing info
                    local timing=$(echo "$line" | grep -o '[0-9]*\.[0-9]*.*ms' | head -1)
                    if [ -n "$timing" ]; then
                        local ms_value=$(echo "$timing" | grep -o '[0-9]*\.[0-9]*' | head -1)
                        if [ -n "$ms_value" ] && [[ "$ms_value" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                            local ms_int=$(echo "$ms_value" | cut -d'.' -f1)
                            # Validate that ms_int is not empty and is numeric
                            if [ -n "$ms_int" ] && [[ "$ms_int" =~ ^[0-9]+$ ]]; then
                                if [ "$ms_int" -lt 50 ]; then
                                    echo -e "${GREEN}${hop_num}${NC} ${rest}"
                                elif [ "$ms_int" -lt 150 ]; then
                                    echo -e "${YELLOW}${hop_num}${NC} ${rest}"
                                else
                                    echo -e "${RED}${hop_num}${NC} ${rest}"
                                fi
                            else
                                # Fallback if ms_int is not valid
                                echo -e "${BLUE}${hop_num}${NC} ${rest}"
                            fi
                        else
                            echo -e "${BLUE}${hop_num}${NC} ${rest}"
                        fi
                    else
                        echo -e "${BLUE}${hop_num}${NC} ${rest}"
                    fi
                else
                    echo -e "${BLUE}${hop_num}${NC} ${rest}"
                fi
            else
                echo -e "${DIM}${line}${NC}"
            fi
        done
        
        echo
        echo -e "${GREEN}✅ Traceroute completed${NC}"
        
        # Extract and display summary statistics
        local hop_count=$(echo "$traceroute_output" | grep -c "^[[:space:]]*[0-9]")
        hop_count=${hop_count:-0}
        local timeout_count=$(echo "$traceroute_output" | grep -c "\*")
        timeout_count=${timeout_count:-0}
        # Forzar que sean números puros
        if [[ ! "$hop_count" =~ ^[0-9]+$ ]]; then
          hop_count=0
        fi
        if [[ ! "$timeout_count" =~ ^[0-9]+$ ]]; then
          timeout_count=0
        fi
        
        # Asegurar comparaciones robustas
        if [ "${hop_count:-0}" -gt 0 ]; then
            echo -e "${CYAN}=== Route Summary ===${NC}"
            echo -e "${BLUE}Total hops: ${GREEN}$hop_count${NC}"
            echo -e "${BLUE}Timeouts: ${YELLOW}$timeout_count${NC}"
        else
            echo -e "${YELLOW}No hops found in traceroute output${NC}"
        fi
        
        log_message "SUCCESS" "Traceroute to $host completed - $hop_count hops, $timeout_count timeouts"
        
    else
        echo -e "${RED}❌ Traceroute failed - no output generated${NC}"
        log_message "ERROR" "Traceroute to $host failed"
        return 1
    fi
}

# Función alternativa usando mtr si está disponible
mtr_trace() {
    local host="$1"
    local count="${2:-10}"
    
    if [ -z "$host" ]; then
        echo -e "${RED}❌ Host required for MTR trace${NC}"
        return 1
    fi
    
    # Check if mtr is available
    if ! command -v mtr >/dev/null 2>&1; then
        echo -e "${YELLOW}MTR not available. Install with: brew install mtr${NC}"
        traceroute_host "$host"
        return
    fi
    
    log_message "INFO" "MTR trace to $host"
    echo -e "${CYAN}=== MTR Network Trace ===${NC}"
    echo -e "${BLUE}Target: ${BOLD}$host${NC}"
    echo -e "${BLUE}Count: ${BOLD}$count packets${NC}"
    echo
    
    # Run mtr with report mode
    echo -e "${BLUE}🔍 Running MTR trace...${NC}"
    echo
    
    local mtr_output
    local temp_file="/tmp/netty_mtr_$$"
    
    # Start mtr in background
    mtr --report --report-cycles="$count" "$host" > "$temp_file" 2>&1 &
    local mtr_pid=$!
    
    # Wait for completion with timeout
    local timeout_counter=0
    local max_timeout=120  # MTR can take longer
    
    while [ $timeout_counter -lt $max_timeout ]; do
        if ! kill -0 "$mtr_pid" 2>/dev/null; then
            break
        fi
        sleep 1
        timeout_counter=$((timeout_counter + 1))
    done
    
    # Check if process is still running (timeout)
    if kill -0 "$mtr_pid" 2>/dev/null; then
        kill "$mtr_pid" 2>/dev/null
        rm -f "$temp_file"
        echo -e "${RED}❌ MTR trace timed out after 120 seconds${NC}"
        log_message "ERROR" "MTR trace to $host timed out"
        return 1
    fi
    
    # Read and display results
    if [ -f "$temp_file" ]; then
        mtr_output=$(cat "$temp_file")
        rm -f "$temp_file"
        
        echo "$mtr_output"
        echo
        echo -e "${GREEN}✅ MTR trace completed${NC}"
        log_message "SUCCESS" "MTR trace to $host completed"
    else
        echo -e "${RED}❌ MTR trace failed${NC}"
        log_message "ERROR" "MTR trace to $host failed"
        return 1
    fi
}

# Función combinada que usa la mejor herramienta disponible
enhanced_trace() {
    local host="$1"
    local count="${2:-10}"
    
    if [ -z "$host" ]; then
        echo -e "${RED}❌ Host required for trace${NC}"
        return 1
    fi
    
    # Check what tools are available and use the best one
    if command -v mtr >/dev/null 2>&1; then
        mtr_trace "$host" "$count"
    elif command -v traceroute >/dev/null 2>&1; then
        traceroute_host "$host" 30
    else
        echo -e "${RED}❌ No traceroute tools available${NC}"
        echo -e "${YELLOW}Install with:${NC}"
        echo -e "${DIM}  brew install traceroute${NC}"
        echo -e "${DIM}  brew install mtr${NC}"
        return 1
    fi
}

# Función simple de traceroute sin timeout para casos básicos
simple_trace() {
    local host="$1"
    local max_hops="${2:-30}"
    
    if [ -z "$host" ]; then
        echo -e "${RED}❌ Host required for traceroute${NC}"
        return 1
    fi
    
    log_message "INFO" "Simple trace to $host"
    echo -e "${CYAN}=== Simple Traceroute ===${NC}"
    echo -e "${BLUE}Target: ${BOLD}$host${NC}"
    echo
    
    # Resolve hostname to IP if needed
    local ip=$(dig +short "$host" 2>/dev/null | head -1)
    if [ -n "$ip" ]; then
        echo -e "${GREEN}Resolved to: $ip${NC}"
    fi
    echo
    
    # Check if traceroute is available
    if ! command -v traceroute >/dev/null 2>&1; then
        echo -e "${RED}❌ traceroute command not found${NC}"
        echo -e "${YELLOW}Install with: brew install traceroute${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔍 Tracing route...${NC}"
    echo
    
    # Run traceroute directly (without timeout)
    if traceroute -m "$max_hops" "$host" 2>&1; then
        echo
        echo -e "${GREEN}✅ Traceroute completed${NC}"
        log_message "SUCCESS" "Simple trace to $host completed"
    else
        echo -e "${RED}❌ Traceroute failed${NC}"
        log_message "ERROR" "Simple trace to $host failed"
        return 1
    fi
}

# Export results
export_results() {
    local format="${1:-json}"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local filename="$RESULTS_DIR/netty_report_$timestamp.$format"
    
    echo -e "${CYAN}=== Exporting Network Report ===${NC}"
    echo -e "${BLUE}Format: $format${NC}"
    echo -e "${BLUE}File: $filename${NC}"
    echo
    
    case "$format" in
        "json")
            {
                echo "{"
                echo "  \"timestamp\": \"$(date -Iseconds)\","
                echo "  \"network_info\": {"
                get_interface_info | sed 's/.*: /    "/; s/$/"/' | sed 's/"$/"/' 
                echo "  },"
                echo "  \"generated_by\": \"netty v$VERSION\""
                echo "}"
            } > "$filename"
            ;;
        "csv")
            {
                echo "timestamp,metric,value"
                echo "$(date -Iseconds),tool_version,$VERSION"
                get_interface_info | sed 's/: /,/'
            } > "$filename"
            ;;
        *)
            {
                echo "Netty Report"
                echo "Generated: $(date)"
                echo "Version: $VERSION"
                echo ""
                get_interface_info
            } > "$filename"
            ;;
    esac
    
    echo -e "${GREEN}✅ Report exported to: $filename${NC}"
    log_message "SUCCESS" "Report exported to $filename"
}

# Main function dispatcher
main() {
    local command="$1"
    shift
    
    case "$command" in
        "wifi"|"scan")
            wifi_scan "$@"
            ;;
        "speed"|"speedtest")
            speed_test "$@"
            ;;
        "dns")
            dns_tools "$@"
            ;;
        "monitor"|"traffic")
            network_monitor "$@"
            ;;
        "ip"|"info")
            ip_info "$@"
            ;;
        "ping")
            enhanced_ping "$@"
            ;;
        "trace"|"traceroute")
            enhanced_trace "$@"
            ;;
        "export")
            export_results "$@"
            ;;
        "")
            # Default: show network info
            get_interface_info
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $command${NC}"
            echo "Use --help for available commands"
            exit 1
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            show_version
            exit 0
            ;;
        -q|--quiet)
            QUIET=true
            shift
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -c|--continuous)
            CONTINUOUS_MODE=true
            shift
            ;;
        --log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        *)
            # Pass remaining arguments to main function
            break
            ;;
    esac
done

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script requires macOS${NC}"
    exit 1
fi

# Setup
create_config_dir
log_message "INFO" "=== Starting Netty v$VERSION ==="

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}👋 Netty session ended${NC}"; exit 0' INT

# Run main function with remaining arguments
main "$@"
