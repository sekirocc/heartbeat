#!/bin/bash

# Heartbeat service installation script
# Usage: ./install.sh [target-IP:port]

set -e

# Default configuration
DEFAULT_TARGET="192.168.1.52:7777"
TARGET="${1:-$DEFAULT_TARGET}"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path configuration
INSTALL_DIR="/opt/heartbeat"
SCRIPT_FILE="$INSTALL_DIR/heartbeat.pl"
PLIST_FILE="$HOME/Library/LaunchAgents/com.user.heartbeat.plist"
SERVICE_NAME="com.user.heartbeat"

echo "========================================="
echo "Heartbeat Service Installer"
echo "========================================="
echo ""
echo "Target server: $TARGET"
echo "Install directory: $INSTALL_DIR"
echo ""

# Check if source file exists
if [ ! -f "$SCRIPT_DIR/heartbeat.pl" ]; then
    echo "Error: heartbeat.pl not found"
    echo "Please ensure heartbeat.pl is in the same directory as install.sh"
    exit 1
fi

# Check if already installed
if launchctl list | grep -q "$SERVICE_NAME"; then
    echo "Service is already running, stopping..."
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    echo "Old service stopped"
fi

# Create install directory (requires sudo)
echo "Creating install directory (may require password)..."
sudo mkdir -p "$INSTALL_DIR"

# Copy and replace heartbeat script
echo "Installing heartbeat script..."
sudo cp "$SCRIPT_DIR/heartbeat.pl" "$SCRIPT_FILE"
sudo sed -i '' "s|TARGET_SERVER_PLACEHOLDER|$TARGET|g" "$SCRIPT_FILE"
sudo chmod +x "$SCRIPT_FILE"
echo "✓ Heartbeat script installed"

# Create LaunchAgent plist file
echo "Creating LaunchAgent configuration..."
cat > "$PLIST_FILE" << EOFPLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>

    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_FILE</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/heartbeat.stdout.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/heartbeat.stderr.log</string>
</dict>
</plist>
EOFPLIST

echo "✓ LaunchAgent configuration created"

# Load LaunchAgent
echo "Loading and starting service..."
launchctl load "$PLIST_FILE"

# Wait for service to start
sleep 2

# Verify installation
echo ""
echo "========================================="
echo "Verifying Installation"
echo "========================================="

if launchctl list | grep -q "$SERVICE_NAME"; then
    PID=$(launchctl list | grep "$SERVICE_NAME" | awk '{print $1}')
    echo "✓ Service running (PID: $PID)"
else
    echo "✗ Service not running"
    exit 1
fi

# Check local IP
LOCAL_IP=$(ifconfig en0 | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}')
if [ -z "$LOCAL_IP" ]; then
    LOCAL_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | head -1 | awk '{print $2}')
fi
echo "✓ Local IP: $LOCAL_IP"

# Wait for log generation
sleep 3

if [ -f "/tmp/heartbeat.log" ]; then
    echo ""
    echo "Recent logs:"
    tail -5 /tmp/heartbeat.log
fi

echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Configuration:"
echo "  - Target server: $TARGET"
echo "  - Install directory: $INSTALL_DIR"
echo "  - Service name: $SERVICE_NAME"
echo "  - Log file: /tmp/heartbeat.log"
echo ""
echo "Common commands:"
echo "  View logs: tail -f /tmp/heartbeat.log"
echo "  Check status: launchctl list | grep heartbeat"
echo "  Stop service: launchctl unload $PLIST_FILE"
echo "  Start service: launchctl load $PLIST_FILE"
echo "  Uninstall: cd $SCRIPT_DIR && ./uninstall.sh"
echo ""
