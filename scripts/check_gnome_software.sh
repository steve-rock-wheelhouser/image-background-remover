#!/bin/sh
# Check GNOME Software / AppStream installation and caches for this project
# Usage: sh scripts/check_gnome_software.sh

set -eu

COMPONENT_ID="com.wheelhouser.image-remove-background"
APPDATA="${COMPONENT_ID}.appdata.xml"
SYSTEM_APPDATA_DIR="/usr/share/metainfo"
SYSTEM_DESKTOP_DIR="/usr/share/applications"
SYSTEM_ICON_DIR="/usr/share/icons/hicolor/256x256/apps"
DESKTOP_FILE="remove-background.desktop"
ICON_NAME="remove-background.png"

echo "=== GNOME Software Auto-check ==="
echo "Component ID: $COMPONENT_ID"

check_path() {
  echo "\nChecking: $1"
  if [ -e "$1" ]; then
    ls -l "$1"
  else
    echo " MISSING: $1"
  fi
}

echo "\n-- System paths --"
check_path "$SYSTEM_APPDATA_DIR/$APPDATA"
check_path "$SYSTEM_DESKTOP_DIR/$DESKTOP_FILE"
check_path "$SYSTEM_ICON_DIR/$ICON_NAME"
check_path "/usr/bin/remove-background"

echo "\n-- User XDG paths --"
check_path "$HOME/.local/share/metainfo/$COMPONENT_ID.appdata.xml"
check_path "$HOME/.local/share/applications/$DESKTOP_FILE"
check_path "$HOME/.local/share/icons/hicolor/256x256/apps/$ICON_NAME"

echo "\n-- AppStream / GNOME Software checks --"

if command -v appstreamcli >/dev/null 2>&1; then
  echo "appstreamcli available: version:`appstreamcli --version 2>/dev/null || true`"
  echo "Attempting to dump component from AppStream index..."
  if appstreamcli dump "$COMPONENT_ID" >/dev/null 2>&1; then
    echo "OK: component found in AppStream index (user or system cache)."
    echo "Showing summary (short):"
    appstreamcli dump "$COMPONENT_ID" | sed -n '1,120p'
  else
    echo "WARN: component not found in AppStream index.";
    echo "You may need to install the package system-wide and refresh the system cache.";
  fi
else
  echo "appstreamcli not installed. Install 'appstream' package to run validation and queries.";
fi

echo "\n-- System cache inspection (requires root for full checks) --"
if [ "$(id -u)" -eq 0 ]; then
  echo "Running system cache refresh (as root)..."
  appstreamcli refresh-cache --system --verbose || true
  echo "Listing system app-info cache dir contents:";
  ls -l /var/cache/app-info || true
else
  echo "Not running as root. To refresh system caches run as root:";
  echo "  sudo appstreamcli refresh-cache --system --verbose";
  echo "  sudo update-desktop-database /usr/share/applications";
  echo "  sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor";
fi

echo "\n-- Package installation check --"
if command -v rpm >/dev/null 2>&1; then
  if rpm -q remove-background >/dev/null 2>&1; then
    echo "Package 'remove-background' is installed:";
    rpm -qip /usr/bin/remove-background >/dev/null 2>&1 || true
    rpm -qi remove-background || true
  else
    echo "Package 'remove-background' not installed (or different package name).";
  fi
else
  echo "rpm not available to check package installation.";
fi

echo "\n-- Desktop/icon database status (user) --"
if command -v update-desktop-database >/dev/null 2>&1; then
  echo "update-desktop-database exists; showing its output (may require root for /usr/share):";
  update-desktop-database $HOME/.local/share/applications 2>/dev/null || true
else
  echo "update-desktop-database not available.";
fi

echo "\n-- Icon cache check (user) --"
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  echo "gtk-update-icon-cache exists; run as root to update system icon cache:";
  echo "  sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor";
else
  echo "gtk-update-icon-cache not available.";
fi

echo "\n== End of checks =="

exit 0
