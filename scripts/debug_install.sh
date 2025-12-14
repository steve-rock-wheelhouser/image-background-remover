#!/bin/bash
echo "=== INSTALLATION DEBUGGER ==="
echo "Checking what is actually installed on your system..."
echo ""

# 1. Check Metadata File
META="/usr/share/metainfo/com.wheelhouser.image-remove-background.metainfo.xml"
if [ -f "$META" ]; then
    echo "[OK] Metadata file found at $META"
    echo "     Checking ID inside file..."
    grep "<id>" "$META"
else
    echo "[FAIL] Metadata file NOT found at $META"
    echo "       Did you install the latest RPM?"
fi
echo ""

# 2. Check Desktop File
DESK="/usr/share/applications/com.wheelhouser.image-remove-background.desktop"
if [ -f "$DESK" ]; then
    echo "[OK] Desktop file found at $DESK"
    echo "     Checking Icon entry..."
    grep "Icon=" "$DESK"
else
    echo "[FAIL] Desktop file NOT found at $DESK"
fi
echo ""

# 3. Check Icon File
ICON="/usr/share/icons/hicolor/128x128/apps/com.wheelhouser.image-remove-background.png"
if [ -f "$ICON" ]; then
    echo "[OK] Icon file found at $ICON"
else
    echo "[FAIL] Icon file NOT found at $ICON"
    echo "       Checking for old icon name..."
    ls /usr/share/icons/hicolor/*/apps/remove-background.png 2>/dev/null && echo "       Found OLD icon name (remove-background.png) - RPM update failed?"
fi
echo ""

echo "=== DIAGNOSIS ==="
if [ -f "$META" ] && [ -f "$DESK" ] && [ -f "$ICON" ]; then
    echo "All files are present and correct on disk."
    echo "If Software Center is still wrong, the system database needs to be forced to read these new files."
    echo "Run this command to force the registration:"
    echo "sudo appstreamcli refresh --force && killall gnome-software"
else
    echo "Files are missing or incorrect. The RPM installation did not update the files."
    echo "Please reinstall the RPM."
fi
