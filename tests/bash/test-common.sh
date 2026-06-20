#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
. "$HERE/../../skills/spex-init/scripts/bash/common.sh"

root="$(make_fixture)"

# find_spex_root from a nested dir
mkdir -p "$root/spex/specs/deep"
assert_eq "$(cd "$root/spex/specs/deep" && find_spex_root)" "$root" "find_spex_root walks up"

# read_config
assert_eq "$(read_config mode "$root")" "brownfield" "read_config mode"
assert_eq "$(read_config scripts "$root")" "true" "read_config scripts"

# frontmatter_status
make_spec "$root" "001-alpha" "approved"
assert_eq "$(frontmatter_status "$root/spex/specs/001-alpha/spec.md")" "approved" "frontmatter_status"

# resolve_feature: single dir → that dir
rm -rf "$root/spex/specs/deep"
assert_eq "$(resolve_feature "$root")" "001-alpha" "resolve single dir"

# resolve_feature: active-feature pointer wins
make_spec "$root" "002-beta" "draft"
printf '002-beta\n' > "$root/spex/active-feature"
assert_eq "$(resolve_feature "$root")" "002-beta" "resolve active pointer"

# feature_paths
fp="$(feature_paths "002-beta" "$root")"
assert_eq "$(printf '%s\n' "$fp" | sed -n 's/^SPEC=//p')" "$root/spex/specs/002-beta/spec.md" "feature_paths SPEC"

summary
