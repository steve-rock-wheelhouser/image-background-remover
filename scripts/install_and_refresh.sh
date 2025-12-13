#!/bin/bash
# Install the latest built RPM, refresh AppStream and GNOME caches, and open GNOME Software.
# Usage: ./scripts/install_and_refresh.sh

set -euo pipefail

RPM_DIR="$HOME/projects/Remove-Background/rpmbuild/RPMS/x86_64"
RPM_GLOB="$RPM_DIR/remove-background-*.rpm"

echo "Searching for RPM in: $RPM_DIR"
RPM_PATH=$(ls -1 $RPM_GLOB 2>/dev/null | sort -V | tail -n1 || true)

if [ -z "$RPM_PATH" ]; then
    echo "No RPM found in $RPM_DIR"
    echo "Build an RPM first: bash build-rpm.sh"
    exit 1
fi

echo "Found RPM: $RPM_PATH"

echo "Removing any existing package (if installed)..."
sudo dnf remove -y remove-background || true

echo "Installing RPM: $RPM_PATH"
sudo dnf install -y "$RPM_PATH"

echo "Clearing caches (system + user) ..."
sudo rm -rf /var/cache/app-info/* /var/cache/swcatalog/cache/* 2>/dev/null || true
rm -rf "$HOME/.cache/gnome-software" "$HOME/.local/share/app-info" 2>/dev/null || true

echo "Refreshing AppStream cache (system) ..."
sudo appstreamcli refresh-cache --force --verbose | tee "$HOME/appstream-refresh-$(date +%Y%m%d-%H%M%S).log"

echo "Updating desktop and icon caches..."
sudo update-desktop-database /usr/share/applications || true
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor || true

echo "Restarting PackageKit and restarting GNOME Software..."
sudo systemctl restart packagekit || true
pkill -f gnome-software || true
sleep 2

echo "Opening GNOME Software (installed app view)."
# Launch GNOME Software; user should search for the installed app.
nohup gnome-software >/dev/null 2>&1 &

echo "Done. If GNOME Software still shows stale data, run this script as root and paste the appstream refresh log file from your home directory."
echo "To re-run the authoritative refresh, run: sudo appstreamcli refresh-cache --force --verbose"

exit 0
