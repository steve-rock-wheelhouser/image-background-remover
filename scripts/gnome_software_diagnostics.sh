#!/bin/bash
# gnome_software_diagnostics.sh
# Collects AppStream/GNOME Software diagnostics and optionally refreshes caches when run as root.
# Usage:
#   ./scripts/gnome_software_diagnostics.sh         # gather info (non-root)
#   sudo ./scripts/gnome_software_diagnostics.sh    # gather info + refresh caches (root)

set -euo pipefail

COMPONENT_ID="com.wheelhouser.image-remove-background"
SCREENSHOTS=( \
  "https://raw.githubusercontent.com/steve-rock-wheelhouser/image-background-remover/main/assets/screenshots/screenshot.png" \
  "https://raw.githubusercontent.com/steve-rock-wheelhouser/image-background-remover/main/assets/screenshots/screenshot-01.png" \
  "https://raw.githubusercontent.com/steve-rock-wheelhouser/image-background-remover/main/assets/screenshots/screenshot-02.png" \
)

OUTDIR="$HOME/gnome-software-diagnostics-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUTDIR"
LOG="$OUTDIR/diag.log"
exec > >(tee -a "$LOG") 2>&1

echo "Diagnostics started: $(date)"
echo "Output dir: $OUTDIR"

echo
echo "==== 1) AppStream index dump ===="
if command -v appstreamcli >/dev/null 2>&1; then
  echo "appstreamcli version: $(appstreamcli --version 2>/dev/null || true)"
  echo "--- appstreamcli dump (first 200 lines) ---"
  appstreamcli dump "$COMPONENT_ID" | sed -n '1,200p' || echo "(appstreamcli dump returned non-zero)"
  echo "--- image lines ---"
  appstreamcli dump "$COMPONENT_ID" | grep '<image>' || echo "(no <image> tags found)"
else
  echo "appstreamcli not installed"
fi

echo
echo "==== 2) GNOME Software installation & running binary ===="
echo "gnome-software --version:"
gnome-software --version 2>/dev/null || true

echo "rpm -q gnome-software:"
rpm -q gnome-software 2>/dev/null || true

echo "flatpak info org.gnome.Software:"
flatpak info org.gnome.Software 2>/dev/null || true

echo "running processes (pgrep -af):"
pgrep -af gnome-software || true

echo
echo "==== 3) AppStream / swcatalog cache locations ===="
ls -ld /var/cache/app-info /var/cache/swcatalog /var/cache/swcatalog/cache 2>/dev/null || true

echo "Searching cache files for component id (may take a moment)..."
grep -R --line-number "$COMPONENT_ID" /var/cache/app-info* /var/cache/swcatalog* 2>/dev/null || true

echo
echo "==== 4) Check cached user data ===="
ls -ld ~/.cache/gnome-software || true
ls -ld ~/.local/share/app-info || true

echo
echo "==== 5) Try fetching screenshot URLs (headers only) ===="
for url in "${SCREENSHOTS[@]}"; do
  echo "-- $url --"
  curl -I -L --max-time 15 "$url" || echo "(curl failed)"
done

if [ "$(id -u)" -eq 0 ]; then
  echo
  echo "==== 6) Running authoritative AppStream refresh (root) ===="
  echo "appstreamcli refresh-cache --force --verbose"
  appstreamcli refresh-cache --force --verbose | tee "$OUTDIR/appstream-refresh.log"
  echo "Refresh finished: $(date)"
  echo
  echo "Writing ls -l /var/cache/app-info and /var/cache/swcatalog"
  ls -l /var/cache/app-info || true
  ls -l /var/cache/swcatalog || true
else
  echo
  echo "(Not root) To force refresh run: sudo $0"
fi

echo
echo "==== 7) Desktop/icon DB updates (root recommended) ===="
if [ "$(id -u)" -eq 0 ]; then
  update-desktop-database /usr/share/applications 2>&1 || true
  gtk-update-icon-cache -f /usr/share/icons/hicolor 2>&1 || true
else
  echo "Not root: to update system caches run: sudo update-desktop-database /usr/share/applications && sudo gtk-update-icon-cache -f /usr/share/icons/hicolor"
fi

echo
echo "==== 8) Relevant logs (last 200 lines) ===="
if command -v journalctl >/dev/null 2>&1; then
  echo "-- packagekit --"
  journalctl -u packagekit -n 200 --no-pager | sed -n '1,200p' || true
  echo "-- gnome-software --"
  journalctl -u gnome-software -n 200 --no-pager | sed -n '1,200p' || true
else
  echo "journalctl not available"
fi

echo
echo "==== 9) SELinux status and AVCs ===="
getenforce 2>/dev/null || true
if command -v ausearch >/dev/null 2>&1; then
  echo "-- recent AVC denials --"
  ausearch -m avc -ts recent | tail -n 200 || true
else
  echo "ausearch not available"
fi

echo
echo "==== 10) Summary / next steps ===="
if appstreamcli dump "$COMPONENT_ID" >/dev/null 2>&1; then
  echo "AppStream index contains the component. If UI is stale, ensure you restarted GNOME Software and cleared user caches."
else
  echo "AppStream index DOES NOT contain the component. Ensure the package is installed system-wide and re-run as root: sudo $0"
fi

echo "Diagnostics complete: $(date)"
echo "Logs saved to: $OUTDIR (primary log: $LOG)"

# Exit with success
exit 0
