#!/bin/sh
# Safe history purge helper for this repo
# Usage: sh scripts/purge_history.sh

set -eu

ROOT_DIR="$(pwd)"

timestamp() {
  date +%Y%m%dT%H%M%S
}

backup="repo-backup-$(timestamp).bundle"

echo "[purge] Ensuring we're in a git repository..."
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repository. Run this from the repository root." >&2
  exit 2
fi

echo "[purge] Creating backup bundle: $backup"
git bundle create "$backup" --all || {
  echo "Failed to create backup bundle." >&2
  exit 3
}

paths_file="scripts/paths-to-remove.txt"
if [ ! -f "$paths_file" ]; then
  echo "Missing $paths_file" >&2
  exit 4
fi

echo "[purge] Checking for git-filter-repo..."
if command -v git-filter-repo >/dev/null 2>&1; then
  echo "[purge] Using git-filter-repo (executable)."
  git-filter-repo --force --invert-paths --paths-from-file "$paths_file"
elif python3 -c 'import git_filter_repo' >/dev/null 2>&1; then
  echo "[purge] Using python module git_filter_repo."
  python3 -m git_filter_repo --force --invert-paths --paths-from-file "$paths_file"
else
  echo "git-filter-repo is not available. Install it with: pip3 install git-filter-repo" >&2
  echo "Alternatively, run this script where git-filter-repo is available." >&2
  exit 5
fi

echo "[purge] Expiring reflogs and running aggressive gc..."
git reflog expire --expire=now --all || true
git gc --prune=now --aggressive || true

echo "[purge] Fetching origin to ensure remote refs are known..."
git fetch origin || true

echo "[purge] Attempting safe force-push to origin main (with lease)."
if git rev-parse --verify origin/main >/dev/null 2>&1; then
  git push --force-with-lease origin main
else
  echo "origin/main not found; pushing new main branch upstream." 
  git push -u origin main
fi

echo "[purge] Done. Keep the backup bundle ($backup) until you're satisfied." 
