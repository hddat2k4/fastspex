#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
SCRIPT="$HERE/../../skills/init/scripts/bash/install-contexthub.sh"

# SAFETY: every scenario runs with a fresh temp HOME and a temp bin/ holding
# ONLY fake npm/claude stubs. We build SYSPATH = system coreutils dirs (so cat,
# grep, mkdir, env, bash resolve) WITHOUT the dirs that hold the real npm/claude,
# then run the script with PATH="$bin:$SYSPATH". The stub npm/claude shadow any
# real ones, the real npm/claude/global config are never touched, and
# `npm install -g` is never executed for real. For Scenario C (no claude) the
# stub bin has no claude, so `command -v claude` finds nothing.
# NOTE: msys grep SIGABRTs on combined -i -F; never use grep -iF/-qiF here.

# Minimal system PATH: coreutils + bash, but exclude dirs holding real npm/claude.
SYSPATH="/usr/bin:/bin:/usr/local/bin"

# --- Scenario A: claude + npm present, idempotent register via `claude mcp` ---
sandbox="$(mktemp -d)"
bin="$sandbox/bin"; home="$sandbox/home"
mkdir -p "$bin" "$home"
npm_log="$sandbox/npm.log"
claude_log="$sandbox/claude.log"
state="$sandbox/state"   # mcp list output: empty first, "chub" after add
: > "$state"

cat > "$bin/npm" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$npm_log"
exit 0
EOF

cat > "$bin/claude" <<EOF
#!/usr/bin/env bash
if [ "\$1" = "mcp" ] && [ "\$2" = "list" ]; then
  cat "$state"
  exit 0
fi
if [ "\$1" = "mcp" ] && [ "\$2" = "add" ]; then
  printf '%s\n' "\$*" >> "$claude_log"
  printf 'chub\n' >> "$state"
  exit 0
fi
exit 0
EOF
chmod +x "$bin/npm" "$bin/claude"

assert_exit 0 "PATH='$bin:$SYSPATH' HOME='$home' bash '$SCRIPT'"
outA="$(PATH="$bin:$SYSPATH" HOME="$home" bash "$SCRIPT" 2>/dev/null)"

assert_eq "$(grep -q -- 'install -g @aisuite/chub' "$npm_log" && echo yes)" "yes" "npm install -g @aisuite/chub invoked"
assert_eq "$(grep 'mcp add' "$claude_log" | grep 'chub' | grep -c 'chub-mcp')" "1" "claude mcp add line has chub + chub-mcp"
assert_eq "$(printf '%s' "$outA" | grep -c '"installed":true')" "1" "stdout reports installed:true"

# second run: mcp list now shows chub → add is skipped, still exactly ONE add line
assert_exit 0 "PATH='$bin:$SYSPATH' HOME='$home' bash '$SCRIPT'"
assert_eq "$(grep -c 'mcp add' "$claude_log")" "1" "idempotent: exactly one mcp add line after re-run"

# --- Scenario B: npm fails → non-zero exit, no installed output ---
sandboxB="$(mktemp -d)"
binB="$sandboxB/bin"; homeB="$sandboxB/home"
mkdir -p "$binB" "$homeB"
cat > "$binB/npm" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$binB/npm"

assert_exit 1 "PATH='$binB:$SYSPATH' HOME='$homeB' bash '$SCRIPT'"
outB="$(PATH="$binB:$SYSPATH" HOME="$homeB" bash "$SCRIPT" 2>/dev/null)"
assert_eq "$(printf '%s' "$outB" | grep -c 'installed')" "0" "npm failure: stdout has no installed"

# --- Scenario C: no claude → mcp.json fallback, idempotent ---
sandboxC="$(mktemp -d)"
binC="$sandboxC/bin"; homeC="$sandboxC/home"
mkdir -p "$binC" "$homeC"
cat > "$binC/npm" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$binC/npm"

assert_exit 0 "PATH='$binC:$SYSPATH' HOME='$homeC' bash '$SCRIPT'"
cfg="$homeC/.claude/mcp.json"
assert_eq "$([ -f "$cfg" ] && echo yes)" "yes" "fallback wrote ~/.claude/mcp.json"
assert_eq "$(grep -q 'chub' "$cfg" && echo yes)" "yes" "mcp.json contains chub"

# second run: still exactly ONE occurrence of the "chub" key (idempotent)
assert_exit 0 "PATH='$binC:$SYSPATH' HOME='$homeC' bash '$SCRIPT'"
assert_eq "$(grep -o '"chub"' "$cfg" | grep -c '.')" "1" "idempotent: exactly one chub key in mcp.json after re-run"

summary
