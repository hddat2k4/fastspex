#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/common.sh"

JSON=0; BRANCH=0; DESC=""
while [ $# -gt 0 ]; do
  case "$1" in
    --json)   JSON=1 ;;
    --branch) BRANCH=1 ;;
    -h|--help) echo "Usage: new-feature.sh [--json] [--branch] <description>"; exit 0 ;;
    *) DESC="${DESC:+$DESC }$1" ;;
  esac
  shift
done
[ -n "$DESC" ] || { echo "error: feature description required" >&2; exit 1; }

ROOT="$(find_spex_root)" || { echo "error: spex/ not found (run /spex:init)" >&2; exit 1; }
SPECS="$ROOT/spex/specs"; mkdir -p "$SPECS"

max=0
for d in "$SPECS"/*/; do
  [ -d "$d" ] || continue
  n="$(basename "$d" | sed -n 's/^\([0-9]\{3\}\)-.*/\1/p')"
  [ -n "$n" ] && [ "$((10#$n))" -gt "$max" ] && max="$((10#$n))"
done
num="$(printf '%03d' "$((max+1))")"

slug="$(printf '%s' "$DESC" | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]\{1,\}/-/g; s/^-//; s/-$//' | cut -c1-50)"
slug="$(printf '%s' "$slug" | awk -F- '{n=(NF>5?5:NF); for(i=1;i<=n;i++) printf "%s%s",(i>1?"-":""),$i}')"
[ -n "$slug" ] || slug="feature"

feat="${num}-${slug}"; dir="$SPECS/$feat"
[ -d "$dir" ] && { echo "error: $feat already exists" >&2; exit 1; }
mkdir -p "$dir"
printf -- '---\nfeature: %s\nstatus: draft\n---\n' "$feat" > "$dir/spec.md"
printf '%s\n' "$feat" > "$ROOT/spex/active-feature"

if [ "$BRANCH" -eq 1 ] && command -v git >/dev/null 2>&1; then
  git -C "$ROOT" checkout -b "$feat" >/dev/null 2>&1 || true
fi

if [ "$JSON" -eq 1 ]; then
  printf '{"feature":"%s","feature_dir":"%s","spec_file":"%s"}\n' "$feat" "$dir" "$dir/spec.md"
else
  printf 'FEATURE=%s\nFEATURE_DIR=%s\nSPEC_FILE=%s\n' "$feat" "$dir" "$dir/spec.md"
fi
