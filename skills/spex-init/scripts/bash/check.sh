#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/common.sh"

JSON=0; PHASE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --json)  JSON=1 ;;
    --phase) shift; PHASE="${1:-}" ;;
    -h|--help) echo "Usage: check.sh [--json] --phase <design|tasks|implement>"; exit 0 ;;
  esac
  shift
done

ROOT="$(find_spex_root)" || { echo "error: spex/ not found" >&2; exit 2; }
feat="$(resolve_feature "$ROOT")" || { echo "error: no active feature" >&2; exit 2; }
dir="$ROOT/spex/specs/$feat"

case "$PHASE" in
  design)    prior="$dir/spec.md";   label="spec" ;;
  tasks)     prior="$dir/design.md"; label="design" ;;
  implement) prior="$dir/tasks.md";  label="tasks" ;;
  *) echo "error: --phase must be design|tasks|implement" >&2; exit 2 ;;
esac

ok=1; blocking=""
if [ ! -f "$prior" ]; then
  ok=0; blocking="${label}.md missing"
else
  st="$(frontmatter_status "$prior")"
  [ "$st" != "approved" ] && { ok=0; blocking="${label}.md not approved (status: ${st:-none})"; }
fi

docs=""
if [ -d "$dir/details" ]; then
  for f in "$dir/details"/*.md; do [ -f "$f" ] && docs="${docs:+$docs,}details/$(basename "$f")"; done
fi
if [ -d "$ROOT/spex/memory/tech-docs" ]; then
  for f in "$ROOT/spex/memory/tech-docs"/*.md; do [ -f "$f" ] && docs="${docs:+$docs,}tech-docs/$(basename "$f")"; done
fi

if [ "$JSON" -eq 1 ]; then
  printf '{"feature":"%s","feature_dir":"%s","phase":"%s","ok":%s,"blocking":"%s","available_docs":"%s"}\n' \
    "$feat" "$dir" "$PHASE" "$([ $ok -eq 1 ] && echo true || echo false)" "$blocking" "$docs"
else
  printf 'FEATURE=%s\nPHASE=%s\nOK=%s\nDOCS=%s\n' "$feat" "$PHASE" "$ok" "$docs"
  [ -n "$blocking" ] && echo "BLOCKING=$blocking"
fi
[ "$ok" -eq 1 ]
