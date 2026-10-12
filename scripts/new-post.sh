#!/usr/bin/env bash
# Create a new Hugo post, then commit and push it (push -> Vercel deploy).
#
# Usage:
#   scripts/new-post.sh --title "My Post" [--slug my-post] [--date 2026-10-12] \
#     [--tags "security,ai"] [--description "..."] [--body-file FILE] \
#     [--draft] [--no-push] [-m "commit message"]
#
# If --body-file is omitted the body is read from stdin.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTENT_DIR="$ROOT/content/posts"

TITLE=""
SLUG=""
DATE="$(date +%Y-%m-%d)"
TAGS=""
DESC=""
BODY_FILE=""
DRAFT=0
PUSH=1
COMMIT_MSG=""

usage() {
  sed -n '2,9p' "$0"
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --title) TITLE="${2:-}"; shift 2 ;;
    --slug) SLUG="${2:-}"; shift 2 ;;
    --date) DATE="${2:-}"; shift 2 ;;
    --tags) TAGS="${2:-}"; shift 2 ;;
    --description|--desc) DESC="${2:-}"; shift 2 ;;
    --body-file) BODY_FILE="${2:-}"; shift 2 ;;
    --draft) DRAFT=1; shift ;;
    --no-push) PUSH=0; shift ;;
    -m|--message) COMMIT_MSG="${2:-}"; shift 2 ;;
    -h|--help) usage 0 ;;
    *) echo "error: unknown option: $1" >&2; usage 2 ;;
  esac
done

if [ -z "$TITLE" ]; then
  echo "error: --title is required" >&2
  usage 2
fi

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

if [ -z "$SLUG" ]; then
  SLUG="$(slugify "$TITLE")"
fi
[ -n "$SLUG" ] || { echo "error: could not derive a slug; pass --slug" >&2; exit 2; }

if [ -n "$BODY_FILE" ]; then
  [ -f "$BODY_FILE" ] || { echo "error: body file not found: $BODY_FILE" >&2; exit 2; }
  BODY="$(cat "$BODY_FILE")"
else
  echo "reading post body from stdin (finish with Ctrl-D)..." >&2
  BODY="$(cat)"
fi

escape_dq() { printf '%s' "$1" | sed 's/"/'"'"'/g'; }

OUT="$CONTENT_DIR/$SLUG.md"
if [ -e "$OUT" ]; then
  echo "error: already exists: $OUT" >&2
  exit 1
fi
mkdir -p "$CONTENT_DIR"

{
  printf -- '---\n'
  printf 'title: "%s"\n' "$(escape_dq "$TITLE")"
  printf 'date: %s\n' "$DATE"
  printf 'description: "%s"\n' "$(escape_dq "$DESC")"
  if [ -n "$TAGS" ]; then
    printf 'tags:\n'
    old_ifs="$IFS"; IFS=','
    for t in $TAGS; do
      t="$(printf '%s' "$t" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
      [ -n "$t" ] && printf '  - "%s"\n' "$(escape_dq "$t")"
    done
    IFS="$old_ifs"
  else
    printf 'tags: []\n'
  fi
  [ "$DRAFT" = 1 ] && printf 'draft: true\n'
  printf -- '---\n\n'
  printf '%s\n' "$BODY"
} > "$OUT"

echo "created  ${OUT#"$ROOT"/}"

# Best-effort build check.
if command -v hugo >/dev/null 2>&1; then
  if (cd "$ROOT" && hugo --quiet --gc --minify >/dev/null 2>&1); then
    echo "hugo build ok"
  else
    echo "warning: hugo build failed; run 'hugo' in $ROOT to see why" >&2
  fi
fi

if [ "$DRAFT" = 1 ]; then
  echo "draft saved; not committing (drop --draft to publish)"
  exit 0
fi

cd "$ROOT"
git add "content/posts/$SLUG.md"
git commit -m "${COMMIT_MSG:-Publish: $TITLE}" >/dev/null
echo "committed"

if [ "$PUSH" = 1 ]; then
  if git remote get-url origin >/dev/null 2>&1; then
    git push
    echo "pushed"
  else
    echo "note: no 'origin' remote yet; skipping push"
  fi
fi
