#!/usr/bin/env bash
# Commit and push pending changes in the Hugo site (push -> Vercel deploy).
#
# Usage:
#   scripts/publish.sh [-m "message"] [--no-push]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MSG="Update content"
PUSH=1
while [ $# -gt 0 ]; do
  case "$1" in
    -m|--message) MSG="${2:-}"; shift 2 ;;
    --no-push) PUSH=0; shift ;;
    -h|--help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "error: unknown option: $1" >&2; exit 2 ;;
  esac
done

cd "$ROOT"

if [ -z "$(git status --porcelain)" ]; then
  echo "nothing to publish (working tree clean)"
  exit 0
fi

if command -v hugo >/dev/null 2>&1; then
  hugo --quiet --gc --minify >/dev/null 2>&1 || echo "warning: hugo build failed" >&2
fi

git add -A
git commit -m "$MSG" >/dev/null
echo "committed: $MSG"

if [ "$PUSH" = 1 ]; then
  if git remote get-url origin >/dev/null 2>&1; then
    git push
    echo "pushed"
  else
    echo "note: no 'origin' remote yet; skipping push"
  fi
fi
