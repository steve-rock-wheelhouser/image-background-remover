#!/bin/bash
# Comprehensive diagnostic and fix script for GNOME Software metadata display
# Run this on your Fedora host after building and installing the RPM

echo "=== RPM Content Verification ==="
echo ""

# Find the latest RPM
RPM_PATH=$(find ~/projects/Remove-Background/rpmbuild/RPMS -name "remove-background-*.rpm" 2>/dev/null | sort -V | tail -1)

if [ -z "$RPM_PATH" ]; then
    echo "No RPM found in ~/projects/Remove-Background/rpmbuild/RPMS/"
    echo "Please build the RPM first with: bash build-rpm.sh"
    exit 1
fi

echo "Found RPM: $RPM_PATH"
echo ""
echo "--- RPM Contents (metadata and desktop files) ---"
rpm -qlp "$RPM_PATH" | grep -E '(metainfo|applications|icons)'
echo ""
echo "--- Checking AppData filename in RPM ---"
if rpm -qlp "$RPM_PATH" | grep -q "com.wheelhouser.image-remove-background.appdata.xml"; then
    echo "✓ Correct: AppData file has .appdata.xml extension"
else
    echo "✗ ERROR: AppData file not found or has wrong name!"
    echo "Ensure your spec installs com.wheelhouser.image-remove-background.appdata.xml to /usr/share/metainfo and rebuild the RPM."
    echo "Run: bash build-rpm.sh"
    exit 1
fi
echo ""

echo "--- Extracting and validating metadata from RPM ---"
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
rpm2cpio "$RPM_PATH" | cpio -idm 2>/dev/null
if [ -f "usr/share/metainfo/com.wheelhouser.image-remove-background.appdata.xml" ]; then
    echo "✓ AppData file extracted successfully"
    appstreamcli validate usr/share/metainfo/com.wheelhouser.image-remove-background.appdata.xml
    if [ $? -eq 0 ]; then
        echo "✓ AppData validates successfully"
    else
        echo "✗ AppData validation failed!"
        exit 1
    fi
else
    echo "✗ ERROR: AppData file not found in RPM!"
    exit 1
fi
cd - > /dev/null
rm -rf "$TEMP_DIR"
echo ""

echo "=== System State Check ==="
echo ""
echo "--- Checking if package is installed ---"
if rpm -q remove-background &>/dev/null; then
    INSTALLED_VERSION=$(rpm -q remove-background)
    echo "✓ Package is installed: $INSTALLED_VERSION"
    
    # Check if installed version matches RPM
    RPM_VERSION=$(rpm -qp "$RPM_PATH" 2>/dev/null)
    if [ "$INSTALLED_VERSION" != "$RPM_VERSION" ]; then
        echo "⚠ WARNING: Installed version ($INSTALLED_VERSION) differs from RPM ($RPM_VERSION)"
        echo "You need to upgrade: sudo dnf install $RPM_PATH"
        echo ""
    fi
    
    echo ""
    echo "--- Installed files ---"
    rpm -ql remove-background | grep -E '(metainfo|applications|icons|bin/remove-background$)'
    echo ""
    
    echo "--- Checking installed AppData filename ---"
    if rpm -ql remove-background | grep -q "com.wheelhouser.image-remove-background.appdata.xml"; then
        echo "✓ Installed package has correct .appdata.xml file"
    elif rpm -ql remove-background | grep -q "com.wheelhouser.image-remove-background.metainfo.xml"; then
        echo "✗ ERROR: Installed package has OLD .metainfo.xml file!"
        echo "You must reinstall with the new RPM:"
        echo "  sudo dnf remove remove-background"
        echo "  sudo dnf install $RPM_PATH"
        exit 1
    else
        echo "✗ ERROR: No AppData file found in installed package!"
        exit 1
    fi
else
    echo "✗ Package is NOT installed"
    echo "Install with: sudo dnf install $RPM_PATH"
    exit 0
fi
echo ""

echo "=== AppStream Index Check ==="
echo ""
echo "--- Checking system AppStream cache ---"
if [ -d "/var/cache/app-info" ]; then
    echo "Cache directory exists: /var/cache/app-info"
    echo "Last modified: $(stat -c %y /var/cache/app-info 2>/dev/null | cut -d. -f1)"
    echo ""
fi

appstreamcli dump com.wheelhouser.image-remove-background > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✓ Component is in AppStream index"
    echo ""
    echo "--- Component metadata from index ---"
    echo "Name: $(appstreamcli dump com.wheelhouser.image-remove-background | grep -m1 '<name>' | sed 's/<[^>]*>//g' | xargs)"
    echo "Summary: $(appstreamcli dump com.wheelhouser.image-remove-background | grep -m1 '<summary>' | sed 's/<[^>]*>//g' | xargs)"
    echo ""
    echo "--- Screenshots in index ---"
    SCREENSHOT_COUNT=$(appstreamcli dump com.wheelhouser.image-remove-background | grep -c '<image>' || echo "0")
    echo "Screenshot count: $SCREENSHOT_COUNT"
    if [ "$SCREENSHOT_COUNT" -gt 0 ]; then
        appstreamcli dump com.wheelhouser.image-remove-background | grep '<image>' | head -5
    else
        echo "⚠ WARNING: No screenshots found in AppStream index!"
        echo "The metadata file may not have been indexed correctly."
    fi
else
    echo "✗ Component NOT in AppStream index"
    echo "⚠ This is the problem! AppStream doesn't know about your app."
    echo "See refresh commands below to fix this."
fi
echo ""

echo "=== GNOME Software Cache Refresh ==="
echo ""

if [ "$(id -u)" = "0" ]; then
    echo "Running as root - executing refresh commands now..."
    echo ""
    
    echo "1. Refreshing AppStream cache (this indexes metainfo files)..."
    appstreamcli refresh-cache --force --verbose 2>&1 | grep -E "(Processing|Found|Error|component)" | head -20
    echo ""
    
    echo "2. Updating desktop database..."
    update-desktop-database /usr/share/applications 2>&1
    echo "✓ Desktop database updated"
    echo ""
    
    echo "3. Updating icon cache..."
    gtk-update-icon-cache -f /usr/share/icons/hicolor 2>&1
    echo "✓ Icon cache updated"
    echo ""
    
    echo "4. Restarting PackageKit..."
    systemctl restart packagekit
    echo "✓ PackageKit restarted"
    echo ""
    
    echo "5. Killing GNOME Software (it will restart automatically)..."
    pkill -f gnome-software || true
    sleep 2
    echo "✓ GNOME Software killed"
    echo ""
    
    echo "=== Verification After Refresh ==="
    echo ""
    appstreamcli dump com.wheelhouser.image-remove-background > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Component NOW in AppStream index!"
        echo ""
        echo "Screenshot URLs:"
        appstreamcli dump com.wheelhouser.image-remove-background | grep '<image>' | head -5
        echo ""
        echo "✓✓✓ SUCCESS! Open GNOME Software and:"
        echo "  - Double-click the RPM file: $RPM_PATH"
        echo "  - Or search for 'Image Background Remover'"
        echo "  - You should now see the full description and screenshots"
    else
        echo "✗ Component STILL not in index after refresh"
        echo ""
        echo "Possible issues:"
        echo "1. The .appdata.xml file may have validation errors"
        echo "2. AppStream may not be scanning /usr/share/metainfo/"
        echo "3. SELinux may be blocking access"
        echo ""
        echo "Run this to check for SELinux denials:"
        echo "  sudo ausearch -m avc -ts recent | grep appstream"
        echo ""
        echo "Check AppStream paths being scanned:"
        echo "  appstreamcli --verbose get com.wheelhouser.image-remove-background"
    fi
else
    echo "⚠ Not running as root. To fix GNOME Software display, run:"
    echo ""
    echo "sudo bash scripts/verify_rpm_and_refresh.sh"
    echo ""
    echo "Or run these commands manually:"
    echo ""
    echo "# Refresh AppStream cache (indexes all metainfo files)"
    echo "sudo appstreamcli refresh-cache --force --verbose"
    echo ""
    echo "# Update desktop and icon caches"
    echo "sudo update-desktop-database /usr/share/applications"
    echo "sudo gtk-update-icon-cache -f /usr/share/icons/hicolor"
    echo ""
    echo "# Restart PackageKit and GNOME Software"
    echo "sudo systemctl restart packagekit"
    echo "pkill -f gnome-software"
    echo ""
    echo "# Wait a few seconds, then open GNOME Software"
fi
