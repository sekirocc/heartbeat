# Heartbeat Server

Pure Perl HTTP server implementation for receiving heartbeat messages.

## Features

- **Pure Perl**: Uses only core modules (IO::Socket::INET, POSIX)
- **Zero Dependencies**: No CPAN packages required
- **Lightweight**: Simple and efficient HTTP server implementation
- **Logging**: Automatically logs all heartbeat messages

## Quick Start

### Using Default Port (7777)

```bash
./heartbeat_server.pl
```

### Specify Port

```bash
./heartbeat_server.pl 8080
```

### Run in Background

```bash
nohup ./heartbeat_server.pl 7777 > /tmp/server.out 2>&1 &
```

## Functionality

### Supported HTTP Methods

#### POST - Receive Heartbeat Messages
Receives JSON format heartbeat data:

```bash
curl -X POST http://localhost:7777 \
  -H "Content-Type: application/json" \
  -d '{"ip": "192.168.1.100"}'
```

The server will:
- Parse JSON data
- Log client IP and reported IP
- Return 200 OK response

#### GET - Health Check
```bash
curl http://localhost:7777
```

Returns HTML page showing server status.

#### HEAD - Server Alive Check
```bash
curl -I http://localhost:7777
```

Returns response headers without response body.

## Logging

### Log Location
```
/tmp/heartbeat_server.log
```

### View Logs

```bash
# View recent logs
tail -20 /tmp/heartbeat_server.log

# View real-time logs
tail -f /tmp/heartbeat_server.log
```

### Log Format

```
2026-02-08 11:30:15 - Server started, listening on port 7777
2026-02-08 11:30:20 - Received heartbeat - From: 192.168.1.53, Reported IP: 192.168.1.53
2026-02-08 11:31:20 - Received heartbeat - From: 192.168.1.53, Reported IP: 192.168.1.53
```

## Management

### Find Server Process

```bash
ps aux | grep heartbeat_server.pl
```

### Stop Server

```bash
# Find process ID
ps aux | grep heartbeat_server.pl

# Stop process
kill <PID>

# Or force stop
pkill -f heartbeat_server.pl
```

### Restart Server

```bash
# Stop
pkill -f heartbeat_server.pl

# Start
nohup ./heartbeat_server.pl 7777 > /tmp/server.out 2>&1 &
```

## Testing

### Test POST Request

```bash
# Send heartbeat message
curl -X POST http://localhost:7777 \
  -H "Content-Type: application/json" \
  -d '{"ip": "192.168.1.100"}'

# Check logs to confirm receipt
tail -5 /tmp/heartbeat_server.log
```

### Test GET Request

```bash
curl http://localhost:7777
```

### Test with Heartbeat Client

If heartbeat client is installed:

```bash
# Point to localhost
cd heartbeat
./install.sh localhost:7777
```

## Production Deployment

### Using systemd (Linux)

Create service file `/etc/systemd/system/heartbeat-server.service`:

```ini
[Unit]
Description=Heartbeat Server
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/bin/perl /opt/heartbeat/heartbeat_server.pl 7777
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Start service:
```bash
sudo systemctl enable heartbeat-server
sudo systemctl start heartbeat-server
sudo systemctl status heartbeat-server
```

### Using launchd (macOS)

Create plist file `~/Library/LaunchAgents/com.user.heartbeat.server.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.heartbeat.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/perl</string>
        <string>/opt/heartbeat/heartbeat_server.pl</string>
        <string>7777</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/heartbeat_server.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/heartbeat_server.stderr.log</string>
</dict>
</plist>
```

Load service:
```bash
launchctl load ~/Library/LaunchAgents/com.user.heartbeat.server.plist
```

## Firewall Configuration

### macOS
```bash
# Allow port 7777
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/bin/perl
```

### Linux (iptables)
```bash
sudo iptables -A INPUT -p tcp --dport 7777 -j ACCEPT
```

### Linux (firewalld)
```bash
sudo firewall-cmd --permanent --add-port=7777/tcp
sudo firewall-cmd --reload
```

## Troubleshooting

### Port Already in Use

```bash
# Check port usage
lsof -i :7777

# Or use netstat
netstat -an | grep 7777
```

### Permission Issues

If using ports below 1024 (e.g., 80), root permission is required:

```bash
sudo ./heartbeat_server.pl 80
```

### View Error Logs

```bash
# If running in background
cat /tmp/server.out

# Or view server logs
tail -50 /tmp/heartbeat_server.log
```

## System Requirements

- Perl 5.10 or higher
- Core modules: IO::Socket::INET, POSIX (comes with system)
- Unix-like system (Linux, macOS, BSD, etc.)

## Performance

- **Concurrency**: Single-threaded processing, suitable for lightweight heartbeat scenarios
- **Memory**: Approximately 5-10 MB
- **CPU**: Very low usage
- **Recommendation**: Heartbeat monitoring for less than 100 clients

## Security Recommendations

1. **Restrict Access**: Use firewall to limit access to specific IPs only
2. **Internal Use**: Recommended for internal network use only, do not expose to public internet
3. **Monitor Logs**: Regularly check log file size to prevent disk space issues
4. **Non-privileged Port**: Use ports above 1024 to avoid requiring root permission

## License

Free to use
