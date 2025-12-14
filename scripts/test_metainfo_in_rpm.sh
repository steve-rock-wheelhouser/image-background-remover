#!/bin/sh
set -eu
# Test script: build RPM, extract the metainfo from the RPM, and compare it to the repo metainfo file.
# Usage: from project root: chmod +x scripts/test_metainfo_in_rpm.sh && ./scripts/test_metainfo_in_rpm.sh

PROJECT_DIR="$(pwd)"
REPO_META="$PROJECT_DIR/com.wheelhouser.image-remove-background.metainfo.xml"

if [ ! -f "$REPO_META" ]; then
  echo "ERROR: repo metainfo file not found: $REPO_META"
  exit 2
fi

echo "Building RPM via build-rpm.sh..."
chmod +x "$PROJECT_DIR/build-rpm.sh"
"$PROJECT_DIR/build-rpm.sh"

RPM="$(ls "$PROJECT_DIR"/rpmbuild/RPMS/*/remove-background-*.rpm 2>/dev/null | tail -n1 || true)"
if [ -z "$RPM" ]; then
  echo "ERROR: built RPM not found in rpmbuild/RPMS" >&2
  ls -l "$PROJECT_DIR"/rpmbuild/RPMS || true
  exit 3
fi

echo "Found RPM: $RPM"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Extracting RPM contents to $TMPDIR..."
rpm2cpio "$RPM" | (cd "$TMPDIR" && cpio -id --no-absolute-filenames >/dev/null 2>&1 || true)

EXTRACTED="$TMPDIR/usr/share/metainfo/com.wheelhouser.image-remove-background.metainfo.xml"
if [ ! -f "$EXTRACTED" ]; then
  echo "ERROR: metainfo not found inside RPM contents: expected $EXTRACTED" >&2
  echo "Listing extracted files for debugging:" >&2
  find "$TMPDIR" -type f | sed -n '1,200p' >&2
  exit 4
fi

echo "Comparing repo metainfo with extracted metainfo..."
if cmp -s "$REPO_META" "$EXTRACTED"; then
  echo "SUCCESS: metainfo in RPM matches repository file exactly (byte-for-byte)."
  exit 0
else
  echo "FAIL: metainfo differs. Showing unified diff:" >&2
  diff -u "$REPO_META" "$EXTRACTED" || true
  exit 5
fi
