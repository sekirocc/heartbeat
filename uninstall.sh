#!/bin/bash

# Heartbeat service uninstallation script

set -e

# Path configuration
INSTALL_DIR="/opt/heartbeat"
PLIST_FILE="$HOME/Library/LaunchAgents/com.user.heartbeat.plist"
SERVICE_NAME="com.user.heartbeat"
STATE_FILE="/tmp/heartbeat.state"
LOG_FILE="/tmp/heartbeat.log"

echo "========================================="
echo "Heartbeat Service Uninstaller"
echo "========================================="
echo ""

# Stop and unload service
if launchctl list | grep -q "$SERVICE_NAME"; then
    echo "Stopping service..."
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    echo "✓ Service stopped"
else
    echo "Service not running"
fi

# Delete plist file
if [ -f "$PLIST_FILE" ]; then
    echo "Removing LaunchAgent configuration..."
    rm -f "$PLIST_FILE"
    echo "✓ LaunchAgent configuration removed"
fi

# Ask to delete install directory
echo ""
read -p "Delete install directory $INSTALL_DIR? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$INSTALL_DIR" ]; then
        echo "Removing install directory (may require password)..."
        sudo rm -rf "$INSTALL_DIR"
        echo "✓ Install directory removed"
    fi
else
    echo "Install directory kept"
fi

# Ask to delete logs and state files
echo ""
read -p "Delete logs and state files? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f "$STATE_FILE" "$LOG_FILE" /tmp/heartbeat.stdout.log /tmp/heartbeat.stderr.log
    echo "✓ Logs and state files removed"
else
    echo "Logs and state files kept"
fi

echo ""
echo "========================================="
echo "Uninstallation Complete!"
echo "========================================="
echo ""
