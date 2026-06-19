#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
SCRIPT="$HERE/../../skills/spex-init/scripts/bash/new-feature.sh"

root="$(make_fixture)"; cd "$root"

# first feature → 001, slugified
out="$(bash "$SCRIPT" --json "Add User Login!")"
assert_eq "$(printf '%s' "$out" | sed -n 's/.*"feature":"\([^"]*\)".*/\1/p')" "001-add-user-login" "first feature numbered+slug"
assert_eq "$([ -f "$root/spex/specs/001-add-user-login/spec.md" ] && echo yes)" "yes" "spec.md created"
assert_eq "$(tr -d '\r\n' < "$root/spex/active-feature")" "001-add-user-login" "active-feature written"
assert_eq "$(frontmatter_only_status "$root/spex/specs/001-add-user-login/spec.md")" "draft" "stub status draft"

# second feature → 002
bash "$SCRIPT" "second thing" >/dev/null
assert_eq "$([ -d "$root/spex/specs/002-second-thing" ] && echo yes)" "yes" "second feature → 002"

# repeat description → next number (numbering increments; never clobbers)
bash "$SCRIPT" "second thing" >/dev/null
assert_eq "$([ -d "$root/spex/specs/003-second-thing" ] && echo yes)" "yes" "repeat description → next number"

# missing description → exit 1
assert_exit 1 "bash '$SCRIPT' --json"

# --- template path: new-feature copies spex/templates/spec.md when present ---
root2="$(make_fixture)"
mkdir -p "$root2/spex/templates"
printf -- '---\nfeature: <name>\nstatus: draft        # draft | approved\n---\n# Spec: [FEATURE_NAME]\n\n## Introduction\nTEMPLATE_BODY_MARKER\n' > "$root2/spex/templates/spec.md"
cd "$root2"
bash "$SCRIPT" "with template" >/dev/null
sp="$root2/spex/specs/001-with-template/spec.md"
assert_eq "$(grep -c 'TEMPLATE_BODY_MARKER' "$sp")" "1" "spec uses project template body"
assert_eq "$(frontmatter_only_status "$sp")" "draft" "templated spec status draft"
assert_eq "$(awk -F': ' '/^feature:/{print $2; exit}' "$sp" | tr -d '\r')" "001-with-template" "templated spec feature set"

summary
