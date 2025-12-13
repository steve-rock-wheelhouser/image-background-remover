#!/bin/sh
# Refresh system AppStream, desktop and icon caches and collect diagnostics for GNOME Software
# Usage:
#   sh scripts/refresh_and_check_gnome_software.sh    # runs checks as non-root and shows commands
#   sudo sh scripts/refresh_and_check_gnome_software.sh  # runs system refreshes and collects logs

set -eu

# If not running as root, re-exec via sudo to perform system-level refreshes.
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    echo "This script requires root for full refresh actions. Re-running with sudo..."
    exec sudo sh "$0" "$@"
  else
    echo "Run this script as root or install sudo to allow automatic elevation." >&2
  fi
fi

COMPONENT_ID="com.wheelhouser.image-remove-background"
SCREENSHOT_URL="https://raw.githubusercontent.com/steve-rock-wheelhouser/image-background-remover/main/assets/screenshots/screenshot-01.png"

echo "== Refresh & Diagnostic for GNOME Software (Image Background Remover) =="
echo "Component: $COMPONENT_ID"
echo

echo "-- System refresh (running as root) --"
echo "Running: appstreamcli refresh-cache --system --verbose"
appstreamcli refresh-cache --system --verbose || echo "appstreamcli refresh-cache returned non-zero" >&2

echo "Running: update-desktop-database /usr/share/applications"
update-desktop-database /usr/share/applications || echo "update-desktop-database returned non-zero" >&2

echo "Running: gtk-update-icon-cache -f -t /usr/share/icons/hicolor"
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || echo "gtk-update-icon-cache returned non-zero" >&2

echo "Restarting PackageKit: systemctl restart packagekit"
systemctl restart packagekit || echo "systemctl restart packagekit returned non-zero" >&2

echo "Killing gnome-software processes so UI reloads (if running)"
pkill -f gnome-software || true

echo
echo "-- Short delay to allow caches to update --"
sleep 2

echo
echo "-- AppStream index (user/system) --"
if command -v appstreamcli >/dev/null 2>&1; then
  echo "appstreamcli version: $(appstreamcli --version 2>/dev/null || true)"
  echo "Attempting to dump component metadata (first 200 lines):"
  appstreamcli dump "$COMPONENT_ID" 2>/dev/null | sed -n '1,200p' || echo "Component not found in current index (user or system)."
else
  echo "appstreamcli not installed; install 'appstream' package to query index."
fi

echo
echo "-- System app-info cache files --"
if [ -d /var/cache/app-info ]; then
  ls -l /var/cache/app-info || true
  echo
  echo "Looking for cached screenshot files (may be in other cache locations):"
  $SUDO find /var/cache/app-info -type f -iname '*screenshot*' -print 2>/dev/null || true
else
  echo "/var/cache/app-info not present on this system or not indexed by this user.";
fi

echo
echo "-- Check if GNOME Software is installed as RPM and/or Flatpak --"
if command -v rpm >/dev/null 2>&1; then
  echo "rpm package info (gnome-software):"
  rpm -q gnome-software || echo "gnome-software rpm not installed"
fi
if command -v flatpak >/dev/null 2>&1; then
  echo "flatpak info for org.gnome.Software (if present):"
  flatpak info org.gnome.Software 2>/dev/null || echo "gnome-software not installed as flatpak"
fi

echo
echo "-- Recent logs (PackageKit + GNOME Software) --"
if [ -n "$SUDO" ]; then
  echo "Showing last 200 lines from packagekit service logs:"
  $SUDO journalctl -u packagekit -n 200 --no-pager || true
  echo "\nShowing last 200 lines from gnome-software service (if present):"
  $SUDO journalctl -u gnome-software -n 200 --no-pager || true
else
  echo "Run with sudo to show system logs (journalctl) for packagekit/gnome-software."
fi

echo
echo "-- SELinux check (AVC) --"
if [ -n "$SUDO" ]; then
  if command -v ausearch >/dev/null 2>&1; then
    echo "Recent AVC denials (last 1 hour):"
    $SUDO ausearch -m avc -ts recent -i || echo "No AVC denials found via ausearch or ausearch not present.";
  else
    echo "ausearch not available; check 'journalctl -k' for AVC messages or install 'audit' package.";
  fi
else
  echo "Run with sudo to check SELinux AVC denials."
fi

echo
echo "-- Package verification --"
if command -v rpm >/dev/null 2>&1; then
  echo "Installed package info for remove-background (if installed):"
  rpm -qi remove-background || echo "Package 'remove-background' not installed or different name."
fi

echo
echo "-- Screenshot URL test --"
if command -v curl >/dev/null 2>&1; then
  echo "Checking screenshot URL reachability: $SCREENSHOT_URL"
  curl -I -fsS -L "$SCREENSHOT_URL" | sed -n '1,20p' || echo "Screenshot URL not reachable from this host."
else
  echo "curl not available to test screenshot URL.";
fi

echo
echo "-- Final suggestions --"
echo "If the UI still shows stale or missing metadata after this script, try:";
echo "  - Ensure GNOME Software is the RPM (not Flatpak), or adjust Flatpak sandbox permissions to allow network access to raw.githubusercontent.com";
echo "  - Reboot the system (forces all caches to reload)";
echo "  - If using Flatpak GNOME Software, run the equivalent cache refresh inside the Flatpak or use the distro package for testing.";

echo "\nDone."

exit 0
