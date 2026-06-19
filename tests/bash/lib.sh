# Plain-shell test helpers. No framework. Source from each test file.
PASS=0; FAIL=0

assert_eq() { # actual expected msg
  if [ "$1" = "$2" ]; then PASS=$((PASS+1));
  else FAIL=$((FAIL+1)); echo "FAIL: $3 — expected [$2] got [$1]"; fi
}

assert_exit() { # expected_code "command…"  (command run via eval)
  eval "$2" >/dev/null 2>&1; local rc=$?
  if [ "$rc" -eq "$1" ]; then PASS=$((PASS+1));
  else FAIL=$((FAIL+1)); echo "FAIL: exit — expected $1 got $rc for: $2"; fi
}

summary() { echo "----"; echo "pass=$PASS fail=$FAIL"; [ "$FAIL" -eq 0 ]; }

make_fixture() { # echoes a temp project root with a minimal spex/
  local tmp; tmp="$(mktemp -d)"
  mkdir -p "$tmp/spex/specs" "$tmp/spex/memory/tech-docs"
  cat > "$tmp/spex/config.yml" <<EOF
fastspex: 1
mode: brownfield
self_review: true
scripts: true
EOF
  printf '%s\n' "$tmp"
}

make_spec() { # root feature status
  local d="$1/spex/specs/$2"; mkdir -p "$d"
  printf -- '---\nfeature: %s\nstatus: %s\n---\n' "$2" "$3" > "$d/spec.md"
}

frontmatter_only_status() { # file → status without sourcing common
  awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f&&/^status:/{sub(/^status:[[:space:]]*/,"");print;exit}' "$1"
}
