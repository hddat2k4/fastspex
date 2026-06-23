#!/usr/bin/env bash
# Install the ContextHub MCP server (@aisuite/chub) and register it with Claude
# Code. Safe to re-run: npm -g is idempotent, and MCP registration is skipped
# when "chub" is already present. Run directly; do not source.
set -uo pipefail

usage() {
  cat <<'EOF'
Usage: install-contexthub.sh [--json] [-h|--help]

Installs the ContextHub MCP server:
  1. npm install -g @aisuite/chub   (provides `chub` CLI + `chub-mcp` binary)
  2. registers the `chub` MCP server with Claude Code (user scope)

On success prints {"installed":true} to stdout. --json is accepted and ignored
(output is JSON either way). Idempotent: re-running skips an existing server.
EOF
}

# Accept and ignore --json; support -h/--help.
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --json) ;;
    *) ;;
  esac
done

# Step 1: require npm.
if ! command -v npm >/dev/null 2>&1; then
  printf '%s\n' "ContextHub needs npm. Install Node.js (which includes npm) from https://nodejs.org and re-run." >&2
  exit 1
fi

# Step 2: install the package globally.
npm install -g @aisuite/chub
rc=$?
if [ "$rc" -ne 0 ]; then
  printf '%s\n' "npm install -g @aisuite/chub failed (exit $rc)." >&2
  exit "$rc"
fi

# Step 3: register the MCP server with Claude Code.
if command -v claude >/dev/null 2>&1; then
  if claude mcp list 2>/dev/null | grep -i 'chub' >/dev/null 2>&1; then
    : # already registered
  else
    claude mcp add --scope user chub -- chub-mcp || exit 1
  fi
else
  cfg="$HOME/.claude/mcp.json"
  mkdir -p "$HOME/.claude"
  if [ -f "$cfg" ] && grep '"chub"' "$cfg" >/dev/null 2>&1; then
    : # already registered
  elif [ ! -f "$cfg" ]; then
    printf '%s\n' '{ "mcpServers": { "chub": { "command": "chub-mcp" } } }' > "$cfg"
  else
    if command -v jq >/dev/null 2>&1; then
      tmp="$(mktemp)"
      if jq '.mcpServers["chub"] = {"command":"chub-mcp"}' "$cfg" > "$tmp" 2>/dev/null; then
        mv "$tmp" "$cfg"
      else
        rm -f "$tmp"
        printf '%s\n' "Could not merge into $cfg. Add manually: \"chub\": { \"command\": \"chub-mcp\" } under mcpServers." >&2
      fi
    else
      printf '%s\n' "Could not auto-edit $cfg (jq not found). Add manually: \"chub\": { \"command\": \"chub-mcp\" } under mcpServers." >&2
    fi
  fi
fi

# Step 4: report success.
printf '{"installed":true}\n'
exit 0
