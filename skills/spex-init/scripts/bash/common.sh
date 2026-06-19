#!/usr/bin/env bash
# Fastspex shared helpers. Source this file; do not execute directly.

find_spex_root() {
  local dir="${1:-$PWD}"
  while [ "$dir" != "/" ] && [ -n "$dir" ]; do
    [ -f "$dir/spex/config.yml" ] && { printf '%s\n' "$dir"; return 0; }
    dir="$(dirname "$dir")"
  done
  return 1
}

read_config() {
  local key="$1" root="${2:-$(find_spex_root)}"
  [ -n "$root" ] || return 1
  sed -n "s/^${key}:[[:space:]]*//p" "$root/spex/config.yml" | head -n1 | tr -d '\r'
}

frontmatter_status() {
  local file="$1"
  [ -f "$file" ] || return 1
  awk '
    NR==1 && /^---[[:space:]]*$/ { infm=1; next }
    infm && /^---[[:space:]]*$/  { exit }
    infm && /^status:/ { sub(/^status:[[:space:]]*/,""); gsub(/\r/,""); print; exit }
  ' "$file"
}

resolve_feature() {
  local root="${1:-$(find_spex_root)}"
  [ -n "$root" ] || return 1
  local specs="$root/spex/specs"
  # 1) active-feature pointer
  if [ -f "$root/spex/active-feature" ]; then
    local f; f="$(tr -d '\r\n' < "$root/spex/active-feature")"
    [ -n "$f" ] && [ -d "$specs/$f" ] && { printf '%s\n' "$f"; return 0; }
  fi
  # 2) git branch NNN-*
  if command -v git >/dev/null 2>&1; then
    local br; br="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    if printf '%s' "$br" | grep -Eq '^[0-9]{3}-' && [ -d "$specs/$br" ]; then
      printf '%s\n' "$br"; return 0
    fi
  fi
  # 3) exactly one specs dir
  local dirs=() d
  for d in "$specs"/*/; do [ -d "$d" ] && dirs+=("$(basename "$d")"); done
  [ "${#dirs[@]}" -eq 1 ] && { printf '%s\n' "${dirs[0]}"; return 0; }
  [ "${#dirs[@]}" -eq 0 ] && return 2
  # 4) newest by mtime
  local newest; newest="$(ls -1dt "$specs"/*/ 2>/dev/null | head -n1)"
  [ -n "$newest" ] && { printf '%s\n' "$(basename "$newest")"; return 0; }
  return 2
}

feature_paths() {
  local feat="$1" root="${2:-$(find_spex_root)}" dir
  dir="$root/spex/specs/$feat"
  printf 'FEATURE_DIR=%s\n' "$dir"
  printf 'SPEC=%s\n'        "$dir/spec.md"
  printf 'DESIGN=%s\n'      "$dir/design.md"
  printf 'TASKS=%s\n'       "$dir/tasks.md"
}
