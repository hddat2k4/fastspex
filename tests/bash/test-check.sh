#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
SCRIPT="$HERE/../../skills/spex-init/scripts/bash/check.sh"

root="$(make_fixture)"; cd "$root"
make_spec "$root" "001-x" "draft"
printf '001-x\n' > "$root/spex/active-feature"

# design gate fails when spec is draft
assert_exit 1 "bash '$SCRIPT' --phase design"

# design gate passes when spec approved
sed -i 's/status: draft/status: approved/' "$root/spex/specs/001-x/spec.md"
assert_exit 0 "bash '$SCRIPT' --phase design"

# JSON reports ok=true + feature
out="$(bash "$SCRIPT" --json --phase design)"
assert_eq "$(printf '%s' "$out" | sed -n 's/.*"ok":\([a-z]*\).*/\1/p')" "true" "json ok true"

# tasks gate fails (no design.md yet)
assert_exit 1 "bash '$SCRIPT' --phase tasks"

# bad phase → exit 2
assert_exit 2 "bash '$SCRIPT' --phase bogus"

# available_docs lists tech-docs
printf '# next\n' > "$root/spex/memory/tech-docs/next.md"
out="$(bash "$SCRIPT" --json --phase design)"
assert_eq "$(printf '%s' "$out" | grep -c 'tech-docs/next.md')" "1" "available_docs lists tech-docs"

summary
