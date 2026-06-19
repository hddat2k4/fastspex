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

summary
