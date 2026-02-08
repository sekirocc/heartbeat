# Heartbeat Service

Automatic heartbeat monitoring service for macOS that periodically sends local IP address to a specified server.

**Implementation**: Pure Perl script using only core modules (IO::Socket::INET), no CPAN packages required.

## Components

This project contains two parts:

1. **heartbeat.pl** - Heartbeat Client (this document)
   - Installed on client machines
   - Periodically sends local IP to server

2. **heartbeat_server.pl** - Heartbeat Server
   - Installed on server
   - Receives and logs heartbeat messages
   - See [SERVER_README.md](SERVER_README.md)

## Features

- **Auto-start**: Runs automatically on system startup
- **Intelligent frequency adjustment**: Adapts sending frequency based on network status
  - Normal: Every 1 minute
  - 10 minutes without success: Degrades to every 1 hour
  - 5 hours without success: Degrades to every 1 day
  - Immediately restores to 1 minute upon success
- **Auto-restart**: Automatically restarts if process exits abnormally
- **Logging**: Complete sending logs and state tracking

## Quick Installation

### Prerequisites

Ensure the `heartbeat` directory contains the following files:
- `heartbeat.pl` - Perl heartbeat script (with placeholder)
- `install.sh` - Installation script
- `uninstall.sh` - Uninstallation script

**System Requirements**:
- macOS 10.10 or higher
- Perl 5.10+ (comes with macOS, no additional installation needed)

### Method 1: Install with default configuration

```bash
cd heartbeat
./install.sh
```

Default target server: `192.168.1.52:7777`

### Method 2: Install with custom target server

```bash
cd heartbeat
./install.sh 192.168.1.100:8080
```

## How Installation Script Works

The installation script performs the following operations:

1. Checks if `heartbeat.pl` exists in the same directory
2. Stops running old service (if exists)
3. Creates install directory `/opt/heartbeat` (requires sudo, prompts for password)
4. Copies `heartbeat.pl` to install directory
5. Uses `sed` to replace `TARGET_SERVER_PLACEHOLDER` with actual target server
6. Creates LaunchAgent plist configuration file
7. Loads and starts service
8. Verifies installation

**Note**: Installation to `/opt` directory requires administrator password.

## Usage

### Check Service Status

```bash
# Check if service is running
launchctl list | grep heartbeat

# View real-time logs
tail -f /tmp/heartbeat.log

# View recent logs
tail -20 /tmp/heartbeat.log

# Check last success time
cat /tmp/heartbeat.state
```

### Manage Service

```bash
# Stop service
launchctl unload ~/Library/LaunchAgents/com.user.heartbeat.plist

# Start service
launchctl load ~/Library/LaunchAgents/com.user.heartbeat.plist

# Restart service
launchctl unload ~/Library/LaunchAgents/com.user.heartbeat.plist && \
launchctl load ~/Library/LaunchAgents/com.user.heartbeat.plist
```

### Uninstall Service

```bash
cd heartbeat
./uninstall.sh
```

The uninstall script will prompt whether to delete install directory and log files.

## File Structure

```
heartbeat/
├── heartbeat.pl        # Perl heartbeat service script (with placeholder)
├── heartbeat_server.pl # Perl heartbeat server
├── install.sh          # Installation script
├── uninstall.sh        # Uninstallation script
├── README.md          # Documentation (this file)
└── SERVER_README.md   # Server documentation
```

## Perl Implementation Advantages

- **Pure Perl**: Uses only Perl core modules, no CPAN packages required
- **Cross-platform**: Perl is standard on all Unix-like systems
- **Efficient**: Low memory footprint, excellent performance
- **Reliable**: Uses IO::Socket::INET to build HTTP requests directly, no external dependencies

## Log Files

- `/tmp/heartbeat.log` - Main log file
- `/tmp/heartbeat.state` - State file (records last success time)
- `/tmp/heartbeat.stdout.log` - Standard output log
- `/tmp/heartbeat.stderr.log` - Standard error log

## Message Format

The service sends HTTP POST requests to the target server:

```json
{
  "ip": "192.168.1.53"
}
```

Request header: `Content-Type: application/json`

## Frequency Adjustment Mechanism

The service automatically adjusts sending frequency based on success status:

| Status | Condition | Sending Frequency |
|--------|-----------|-------------------|
| Normal | Recently successful | Every 1 minute |
| Degraded 1 | Over 10 minutes without success | Every 1 hour |
| Degraded 2 | Over 5 hours without success | Every 1 day |

Upon successful send, immediately restores to 1 minute interval.

## Troubleshooting

### Service Not Running

```bash
# Check service status
launchctl list | grep heartbeat

# View error logs
cat /tmp/heartbeat.stderr.log

# Manual start test
sudo /opt/heartbeat/heartbeat.pl
```

### Cannot Get IP

The script attempts to get local IP in the following order:
1. en0 interface (WiFi)
2. en1 interface (Ethernet)
3. First IP of all active interfaces

If still unable to get IP, check network connection.

### Send Failed

Check:
1. Is target server accessible
2. Is port correct
3. Firewall settings
4. Network connection status

## System Requirements

- macOS 10.10 or higher
- Perl 5.10+ (comes with macOS)
- Core Perl modules: IO::Socket::INET, POSIX (comes with system, no installation needed)

## License

Free to use
