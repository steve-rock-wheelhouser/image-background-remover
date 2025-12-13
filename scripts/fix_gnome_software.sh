#!/bin/bash
# Quick fix script for GNOME Software metadata display
# This handles the most common issues

set -e

if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root."
    echo "Usage: sudo bash scripts/fix_gnome_software.sh"
    exit 1
fi

echo "=== GNOME Software Metadata Fix ==="
echo ""

# Find the RPM
RPM_PATH=$(find ~user/projects/Remove-Background/rpmbuild/RPMS -name "remove-background-*.rpm" 2>/dev/null | sort -V | tail -1)
if [ -z "$RPM_PATH" ]; then
    RPM_PATH=$(find /home/*/projects/Remove-Background/rpmbuild/RPMS -name "remove-background-*.rpm" 2>/dev/null | sort -V | tail -1)
fi

if [ -z "$RPM_PATH" ]; then
    echo "ERROR: No RPM found. Please build first:"
    echo "  bash build-rpm.sh"
    exit 1
fi

echo "Found RPM: $RPM_PATH"
echo ""

# Check what's in the RPM
echo "Checking RPM contents..."
if rpm -qlp "$RPM_PATH" | grep -q "com.wheelhouser.image-remove-background.appdata.xml"; then
    echo "✓ RPM has correct .appdata.xml file"
else
    echo "✗ RPM missing AppData file or has wrong name!"
    echo "Ensure spec installs com.wheelhouser.image-remove-background.appdata.xml and rebuild: bash build-rpm.sh"
    exit 1
fi
echo ""

# Reinstall package
echo "Step 1: Reinstalling package..."
if rpm -q remove-background &>/dev/null; then
    echo "Removing old version..."
    dnf remove -y remove-background
fi
echo "Installing new version..."
dnf install -y "$RPM_PATH"
echo "✓ Package installed"
echo ""

# Clear caches
echo "Step 2: Clearing old caches..."
rm -rf /var/cache/app-info/*
rm -rf ~/.cache/gnome-software/*
rm -rf ~user/.cache/gnome-software/* 2>/dev/null || true
echo "✓ Caches cleared"
echo ""

# Rebuild AppStream cache
echo "Step 3: Rebuilding AppStream cache..."
appstreamcli refresh-cache --force --verbose 2>&1 | tail -20
echo ""

# Update other caches
echo "Step 4: Updating desktop and icon caches..."
update-desktop-database /usr/share/applications
gtk-update-icon-cache -f /usr/share/icons/hicolor
echo "✓ Caches updated"
echo ""

# Restart services
echo "Step 5: Restarting services..."
systemctl restart packagekit
pkill -f gnome-software || true
echo "✓ Services restarted"
echo ""

# Verify
echo "=== Verification ==="
echo ""
sleep 2

if appstreamcli dump com.wheelhouser.image-remove-background > /dev/null 2>&1; then
    echo "✓✓✓ SUCCESS!"
    echo ""
    echo "AppStream knows about your app:"
    appstreamcli dump com.wheelhouser.image-remove-background | grep -E '(<name>|<summary>|<image>)' | head -10
    echo ""
    echo "Next steps:"
    echo "1. Open GNOME Software (it will auto-restart)"
    echo "2. Search for 'Image Background Remover'"
    echo "3. Or double-click: $RPM_PATH"
    echo ""
    echo "You should now see the full description, screenshots, and metadata!"
else
    echo "✗ Component still not in AppStream index"
    echo ""
    echo "Check the installed AppData file:"
    echo "  cat /usr/share/metainfo/com.wheelhouser.image-remove-background.appdata.xml"
    echo ""
    echo "Validate it:"
    echo "  appstreamcli validate /usr/share/metainfo/com.wheelhouser.image-remove-background.appdata.xml"
    echo ""
    echo "Check AppStream logs:"
    echo "  journalctl -xe | grep -i appstream"
fi
