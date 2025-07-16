# Netty

A network utilities toolkit for macOS that brings essential networking tools to your terminal. Get WiFi info, test speeds, manage DNS, monitor traffic, and more—all with simple commands.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)  
[![macOS](https://img.shields.io/badge/macOS-Monterey%2B-blue.svg)](https://www.apple.com/macos/)  
[![Homebrew](https://img.shields.io/badge/Homebrew-Compatible-orange.svg)](https://brew.sh/)  
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

## Quick Start

### Homebrew Installation

```bash
brew tap jmeiracorbal/tools
brew install netty
netty wifi
```

### Manual Installation
```bash
curl -O https://raw.githubusercontent.com/jmeiracorbal/netty/main/netty.sh
chmod +x netty.sh
./netty.sh wifi
```

## Features

- WiFi information: View current connection, saved networks, and interface details
- Speed test: Download, latency, and DNS resolution
- DNS management: Flush cache, test resolution, and view DNS servers
- Network monitoring: Real-time traffic monitoring
- IP & geolocation: Public/private IP info and location
- Advanced ping: Ping tests with detailed statistics
- Export results: Save reports in JSON, CSV, or plain text
- Session logging: Automatic logging of network operations
- Clear interface: Output in tables and with progress indicators

## Core Commands

### WiFi & Wireless
```bash
netty wifi
netty info
```

### Speed & Performance
```bash
netty speed
netty ping google.com
netty ping 8.8.8.8
```

### DNS Management
```bash
netty dns flush
netty dns test
netty dns servers
```

### Monitoring & Analysis
```bash
netty monitor
netty ip
netty export json
```

## Example Output

### WiFi Information
```
=== WiFi Network Scanner ===

Analyzing WiFi information...
┌────────────────────────────────┬─────────┬─────────┬──────────┬──────────┐
│ Network Name (SSID)            │ Channel │ Signal  │ Security │ Status   │
├────────────────────────────────┼─────────┼─────────┼──────────┼──────────┤
│ MyNetwork-5G                   │ 36      │ ████    │ WPA2     │ Connected│
│ HomeOffice                     │ ?       │ ░░░░    │ Known    │ Saved    │
│ CoffeeShop_WiFi                │ ?       │ ░░░░    │ Known    │ Saved    │
└────────────────────────────────┴─────────┴─────────┴──────────┴──────────┘

WiFi Interface Information:
Interface: active
MAC Address: aa:bb:cc:dd:ee:ff
Supports: 2.4GHz & 5GHz bands

Currently connected to: MyNetwork-5G
IP Address: 192.168.1.105
```

### Speed Test Results
```
=== Internet Speed Test ===

Testing connection speed...

Testing download...
Download Speed: 85.42 Mbps
Testing latency...
Average Ping: 12.3 ms
Testing DNS resolution...
DNS Resolution: 28 ms

Speed test completed
```

### Network Monitoring
```
=== Network Traffic Monitor ===
Interface: en0
Thu Jun 26 14:30:22 2025

Received: 2.45 GB (1,234,567 packets)
Transmitted: 892.1 MB (567,890 packets)

Active connections:
  tcp4  192.168.1.105.52847  151.101.1.140.443   ESTABLISHED
  tcp4  192.168.1.105.52848  140.82.112.25.443   ESTABLISHED
```

## Detailed Command Guide

### WiFi Commands
```bash
netty wifi
netty info
```

- Current WiFi connection with signal strength and channel
- List of known/saved networks
- Interface status, MAC, and capabilities
- Useful commands for diagnostics

### Speed Test
```bash
netty speed
```

- Download: Real file from CDN (1MB)
- Latency: Ping to several servers
- DNS resolution: Resolution time

### DNS Tools
```bash
netty dns flush
netty dns test
netty dns servers
```

Recommended servers:
- Google: 8.8.8.8, 8.8.4.4
- Cloudflare: 1.1.1.1, 1.0.0.1
- OpenDNS: 208.67.222.222, 208.67.220.220
- Quad9: 9.9.9.9, 149.112.112.112

### Advanced Ping
```bash
netty ping example.com
netty ping 8.8.8.8 10
```

- Host to IP resolution
- Packet loss statistics
- RTT (min/avg/max)
- Automatic result logging

### Network Monitoring
```bash
netty monitor
```

Interactive controls:
- q, Q: Quit
- r, R: Refresh
- s, S: Save snapshot

Shows:
- RX/TX and packets
- Active connections
- Interface statistics

### IP & Geolocation
```bash
netty ip
```

- Local interface details (IPv4, IPv6, MAC)
- Gateway and DNS
- Public IP and geolocation
- ISP and city/region/country

## Data & Configuration

### File Locations
```bash
~/.netty/
├── netty.log
├── config
└── results/
    ├── netty_report_20250626_143022.json
    └── netty_report_20250626_144512.csv
```

### Export Formats
```bash
netty export json
netty export csv
netty export txt
```

JSON Example:

```json
{
  "timestamp": "2025-06-26T14:30:22Z",
  "network_info": {
    "interface": "en0",
    "ipv4": "192.168.1.105",
    "gateway": "192.168.1.1",
    "dns_servers": ["8.8.8.8", "1.1.1.1"]
  },
  "generated_by": "netty v1.1.0"
}
```

## Command Line Options

```bash
netty [OPTIONS] [COMMAND]

OPTIONS:
  -h, --help              Show help
  -v, --version           Show version
  -q, --quiet             Quiet mode
  -f, --format FORMAT     Output format: table, json, csv
  -c, --continuous        Continuous monitoring
  --log-file FILE         Custom log file path

COMMANDS:
  wifi                    WiFi information
  speed                   Speed test
  dns [action]            DNS management
  monitor                 Network monitoring
  ip                      IP and geolocation information
  ping HOST [count]       Advanced ping
  export [format]         Export report
  info                    Interface information
```

## Customization & Tips

### Quiet mode for scripts
```bash
netty -q speed > speed_results.txt
netty --quiet dns flush
```

### Continuous monitoring
```bash
netty --continuous monitor
netty -c monitor | tee network_activity.log
```

### Integration examples
```bash
if netty ping github.com >/dev/null 2>&1; then
    echo "Connectivity confirmed"
    ./deploy.sh
fi

netty speed | grep "Download Speed" | awk '{print $3}'

netty dns flush && netty dns test
```

## Homebrew Installation

### Add the tap
```bash
brew tap jmeiracorbal/tools
```

### Install Netty
```bash
brew install netty
```

### Update to the latest version
```bash
brew update
brew upgrade netty
```

### Uninstall
```bash
brew uninstall netty
```

```
brew untap jmeiracorbal/tools
```

## Use Cases

### For developers
- API testing
- Performance monitoring
- DNS troubleshooting
- Remote work network validation

### For system administrators
- Quick network diagnostics
- Periodic performance tests
- Configuration documentation
- Incident analysis

### For remote workers
- Connection validation
- Speed testing
- WiFi optimization
- Stability monitoring

### For students & researchers
- Protocol learning
- Metric export
- Connectivity research
- Technical documentation

## Privacy & Security

### Data handling
- No data collection: Everything is local
- No external dependencies
- No tracking or analytics
- Local storage only

### Security
- Read-only operations
- Safe DNS flushing
- No sudo required for most features
- Transparent operations

## Technical Details

### Requirements
- macOS Monterey (12.0) or later
- Intel and Apple Silicon
- WiFi or Ethernet interface
- Only standard macOS utilities

### Performance impact
- CPU usage: Minimal (< 1%)
- Memory: ~2-5MB
- Network: Only during tests
- Storage: < 1MB

### Compatibility
- Terminal.app, iTerm2, etc.
- Bash (macOS)
- WiFi, Ethernet, USB, VPN
- macOS 12.0+

## Contributing

Contributions are welcome! The goal is to be a reference tool for macOS users.

### Areas for contribution
- New network utilities
- Improved reports
- Integrations
- UI improvements
- Documentation

### Development
```bash
git clone https://github.com/jmeiracorbal/netty.git

cd netty
chmod +x netty.sh
./netty.sh --help
```

### Testing
```bash
./netty.sh wifi
./netty.sh speed  
./netty.sh dns test
./netty.sh export json
```

## License

This project is under the MIT license - see the [LICENSE](LICENSE) file for details.

## FAQ

**Why create another network tool if macOS already has utilities?**  
Netty offers a unified, easy-to-use interface that combines several tools with better output formatting and additional features like geolocation and speed testing.

**Does it require administrator permissions?**  
Most features do not require sudo. Only DNS cache flushing does, and the tool will indicate it.

**Can I use it on corporate networks?**  
Yes. Netty only performs read-only operations and does not modify settings without explicit action.

**How accurate are the speed test results?**  
Tests use real downloads and ping to several servers. Results should be within 10-15% of dedicated tools.

**Can I automate it in scripts?**  
Yes. Use the --quiet option for minimal output and check exit codes.

**How is it different from other tools?**  
Netty focuses on ease of use, clear output, complete logging, and macOS optimizations.

## Related Projects

- [Mac Optimizer](https://github.com/jmeiracorbal/mac-optimizer)
- [Cloud Storage Symlinks](https://github.com/jmeiracorbal/cloud-storage-symlinks)
- [Pomodoro Timer](https://github.com/jmeiracorbal/pomodoro-timer)
