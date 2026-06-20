# Fastspex Hybrid Script Layer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an optional, deterministic script layer (bash + PowerShell) for Claude Code that handles feature numbering, spec-dir scaffolding, and hard prerequisite gates — while every skill keeps its existing prompt behavior as a fallback for non-Claude agents.

**Architecture:** Three small scripts per platform (`common`, `new-feature`, `check`) ship inside `skills/spex-init/scripts/`. `/spex:init` copies them into the user project at `spex/scripts/` (the only place `${CLAUDE_SKILL_DIR}` is touched). Skills detect `spex/scripts/` and prefer it; absent → inline prompt behavior. Active feature is resolved by a 4-step order shared by script and prompt, persisted in `spex/active-feature`.

**Tech Stack:** Bash (Git Bash / POSIX-friendly, arrays allowed via `#!/usr/bin/env bash`), Windows PowerShell 5.1, Markdown skills. No test framework — plain-shell and plain-PowerShell assertion harnesses (zero dependencies, matching Fastspex's zero-runtime ethos).

## Global Constraints

- Scripts target **bash** (shebang `#!/usr/bin/env bash`) and **Windows PowerShell 5.1**. No `jq`, no Python dependency — emit JSON with `printf` / string formatting.
- Behavior of the script path and the prompt fallback MUST match (same numbering, same resolution order, same gate semantics).
- Feature dir name format: `NNN-slug`, `NNN` zero-padded to 3 digits; slug lowercase, `[^a-z0-9]+` → `-`, trimmed, ≤5 words, ≤50 chars.
- Gate semantics: `design` needs `spec.md` `status: approved`; `tasks` needs `design.md` approved; `implement` needs `tasks.md` approved.
- `new-feature` MUST NOT overwrite an existing dir; git branch creation is **off** unless `--branch`.
- Active feature pointer file: `spex/active-feature` (one line, e.g. `001-login`).
- `config.yml` gains `scripts: true|false`. Bash never edits YAML beyond appending/reading a scalar line.
- All artifacts/comments in English (Fastspex convention).

## File Structure

```
skills/spex-init/scripts/bash/common.sh         # sourced lib: root, config, status, resolve, paths
skills/spex-init/scripts/bash/new-feature.sh    # numbering + scaffold + active-feature + JSON
skills/spex-init/scripts/bash/check.sh          # entry gate by phase; exit≠0 on fail
skills/spex-init/scripts/powershell/common.ps1  # PS 5.1 port of common.sh
skills/spex-init/scripts/powershell/new-feature.ps1
skills/spex-init/scripts/powershell/check.ps1
tests/bash/lib.sh                               # assertion + fixture helpers (no framework)
tests/bash/test-common.sh
tests/bash/test-new-feature.sh
tests/bash/test-check.sh
tests/powershell/test-scripts.ps1               # PS parity tests (no Pester)
```

Modified:
```
skills/spex-init/SKILL.md         # + "materialize script layer" step + scripts flag
skills/spex-spec/SKILL.md         # + Step 0; wire Save → new-feature
skills/spex-design/SKILL.md       # + Step 0
skills/spex-tasks/SKILL.md        # + Step 0
skills/spex-implement/SKILL.md    # + Step 0
README.md                         # + "Optional script layer (Claude Code)" note
CLAUDE.md                         # + one line under Key rules
IMPLEMENTATION_PLAN.md            # refresh: plan→design, project→product/structure, drop update
```

---

## Amendments (post-review)

Two additions agreed after comparing with spec-kit's routing model. Apply them while
implementing the referenced tasks; they change no other task.

**A. `spex-spec` loads steering context (Task 6).** Before drafting requirements, the spec
Flow must read `spex/memory/product.md` and `spex/memory/tech.md` when present, so user
stories trace to Purpose/Users and don't assume the wrong stack. Spec currently reads no
memory — this closes that gap.

**B. Explicit handoff line in every skill (Tasks 6–8).** Standardize the "next step" as one
literal line — `→ Next: /spex:<phase>` — at the end of each skill (spec→design, design→tasks,
tasks→implement, implement→done; init→spec). Mirrors spec-kit's `handoffs` frontmatter so the
agent/user always sees where to go next.

---

### Task 1: Bash test harness + `common.sh`

**Files:**
- Create: `tests/bash/lib.sh`
- Create: `tests/bash/test-common.sh`
- Create: `skills/spex-init/scripts/bash/common.sh`

**Interfaces:**
- Produces (sourced functions): `find_spex_root [startdir]` → echoes project root containing `spex/config.yml`; `read_config <key> [root]` → echoes scalar; `frontmatter_status <file>` → echoes `status:` from leading `---` block; `resolve_feature [root]` → echoes active `NNN-slug` (exit 2 if none); `feature_paths <feature> [root]` → echoes `FEATURE_DIR=…`, `SPEC=…`, `DESIGN=…`, `TASKS=…`.
- Consumes: nothing (foundation task).

- [ ] **Step 1: Write the test harness library**

Create `tests/bash/lib.sh`:

```bash
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
```

- [ ] **Step 2: Write the failing tests for `common.sh`**

Create `tests/bash/test-common.sh`:

```bash
#!/usr/bin/env bash
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
. "$HERE/../../skills/spex-init/scripts/bash/common.sh"

root="$(make_fixture)"
( cd "$root/spex/specs" && : )

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
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `bash tests/bash/test-common.sh`
Expected: FAIL — `common.sh` does not exist yet (source error / functions undefined).

- [ ] **Step 4: Write `skills/spex-init/scripts/bash/common.sh`**

```bash
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
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `bash tests/bash/test-common.sh`
Expected: PASS — `pass=7 fail=0`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add tests/bash/lib.sh tests/bash/test-common.sh skills/spex-init/scripts/bash/common.sh
git commit -m "feat(scripts): add bash common helpers + test harness"
```

---

### Task 2: `new-feature.sh`

**Files:**
- Create: `skills/spex-init/scripts/bash/new-feature.sh`
- Create: `tests/bash/test-new-feature.sh`

**Interfaces:**
- Consumes: `common.sh` (`find_spex_root`).
- Produces: CLI `new-feature.sh [--json] [--branch] <description>`. Side effects: creates `spex/specs/NNN-slug/spec.md` (frontmatter stub), writes `spex/active-feature`. Output JSON `{"feature","feature_dir","spec_file"}` or `KEY=VAL` text. Exit 1 on missing description / existing dir / no spex root.

- [ ] **Step 1: Write the failing tests**

Create `tests/bash/test-new-feature.sh`:

```bash
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

# duplicate description → existing dir error (exit 1)
assert_exit 1 "bash '$SCRIPT' 'second thing'"

# missing description → exit 1
assert_exit 1 "bash '$SCRIPT' --json"

summary
```

Add this helper to `tests/bash/lib.sh` (used above):

```bash
frontmatter_only_status() { # file → status without sourcing common
  awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f&&/^status:/{sub(/^status:[[:space:]]*/,"");print;exit}' "$1"
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/bash/test-new-feature.sh`
Expected: FAIL — script missing.

- [ ] **Step 3: Write `skills/spex-init/scripts/bash/new-feature.sh`**

```bash
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/bash/test-new-feature.sh`
Expected: PASS — `pass=6 fail=0`.

- [ ] **Step 5: Commit**

```bash
git add skills/spex-init/scripts/bash/new-feature.sh tests/bash/test-new-feature.sh tests/bash/lib.sh
git commit -m "feat(scripts): add new-feature.sh (numbering + scaffold)"
```

---

### Task 3: `check.sh`

**Files:**
- Create: `skills/spex-init/scripts/bash/check.sh`
- Create: `tests/bash/test-check.sh`

**Interfaces:**
- Consumes: `common.sh` (`find_spex_root`, `resolve_feature`, `frontmatter_status`).
- Produces: CLI `check.sh [--json] --phase <design|tasks|implement>`. Output JSON `{"feature","feature_dir","phase","ok","blocking","available_docs"}`. **Exit 0 when gate passes, non-zero when it fails** (1 = gate fail, 2 = bad phase / no feature).

- [ ] **Step 1: Write the failing tests**

Create `tests/bash/test-check.sh`:

```bash
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/bash/test-check.sh`
Expected: FAIL — script missing.

- [ ] **Step 3: Write `skills/spex-init/scripts/bash/check.sh`**

```bash
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/bash/test-check.sh`
Expected: PASS — `pass=6 fail=0`.

- [ ] **Step 5: Run the whole bash suite**

Run: `for t in tests/bash/test-*.sh; do bash "$t" || exit 1; done`
Expected: all suites print `fail=0`.

- [ ] **Step 6: Commit**

```bash
git add skills/spex-init/scripts/bash/check.sh tests/bash/test-check.sh
git commit -m "feat(scripts): add check.sh entry gate"
```

---

### Task 4: PowerShell port + parity tests

**Files:**
- Create: `skills/spex-init/scripts/powershell/common.ps1`
- Create: `skills/spex-init/scripts/powershell/new-feature.ps1`
- Create: `skills/spex-init/scripts/powershell/check.ps1`
- Create: `tests/powershell/test-scripts.ps1`

**Interfaces:**
- Mirror the bash contracts exactly. `common.ps1` exposes functions `Find-SpexRoot`, `Read-Config`, `Get-FrontmatterStatus`, `Resolve-Feature`. `new-feature.ps1` and `check.ps1` are entry scripts with the same flags/output as their `.sh` peers (JSON shape identical; same exit codes).

- [ ] **Step 1: Write the failing parity tests**

Create `tests/powershell/test-scripts.ps1`:

```powershell
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$ps   = Join-Path $here '..\..\skills\spex-init\scripts\powershell'
$pass = 0; $fail = 0
function Assert-Eq($a,$b,$m){ if($a -eq $b){$script:pass++} else {$script:fail++; Write-Host "FAIL: $m — expected [$b] got [$a]"} }

# fixture
$root = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path "$root\spex\specs" | Out-Null
New-Item -ItemType Directory -Force -Path "$root\spex\memory\tech-docs" | Out-Null
"fastspex: 1`nmode: brownfield`nself_review: true`nscripts: true" |
  Out-File -Encoding utf8 "$root\spex\config.yml"
Push-Location $root

# new-feature → 001 slug, active-feature, JSON
$out = & "$ps\new-feature.ps1" --json "Add User Login!" | Out-String
Assert-Eq ([bool]($out -match '"feature":"001-add-user-login"')) $true "new-feature numbered slug"
Assert-Eq (Test-Path "$root\spex\specs\001-add-user-login\spec.md") $true "spec.md created"
Assert-Eq ((Get-Content "$root\spex\active-feature" -Raw).Trim()) "001-add-user-login" "active-feature written"

# check design fails (draft) then passes (approved)
& "$ps\check.ps1" --phase design *> $null; Assert-Eq $LASTEXITCODE 1 "design gate fails on draft"
(Get-Content "$root\spex\specs\001-add-user-login\spec.md") -replace 'status: draft','status: approved' |
  Set-Content "$root\spex\specs\001-add-user-login\spec.md"
& "$ps\check.ps1" --phase design *> $null; Assert-Eq $LASTEXITCODE 0 "design gate passes on approved"
& "$ps\check.ps1" --phase bogus  *> $null; Assert-Eq $LASTEXITCODE 2 "bad phase → exit 2"

Pop-Location
Write-Host "----"; Write-Host "pass=$pass fail=$fail"
if ($fail -gt 0) { exit 1 }
```

- [ ] **Step 2: Run to verify it fails**

Run: `powershell -NoProfile -File tests/powershell/test-scripts.ps1`
Expected: FAIL — PowerShell scripts missing.

- [ ] **Step 3: Write `common.ps1`**

```powershell
# Fastspex shared helpers (PowerShell). Dot-source: . common.ps1
function Find-SpexRoot([string]$Start = (Get-Location).Path) {
  $dir = $Start
  while ($dir -and (Test-Path $dir)) {
    if (Test-Path (Join-Path $dir 'spex\config.yml')) { return $dir }
    $parent = Split-Path -Parent $dir
    if ($parent -eq $dir) { break }
    $dir = $parent
  }
  return $null
}
function Read-Config([string]$Key,[string]$Root){
  if (-not $Root) { $Root = Find-SpexRoot }
  if (-not $Root) { return $null }
  $line = Select-String -Path (Join-Path $Root 'spex\config.yml') -Pattern "^$Key\s*:\s*(.*)$" |
          Select-Object -First 1
  if ($line) { return $line.Matches[0].Groups[1].Value.Trim() } else { return $null }
}
function Get-FrontmatterStatus([string]$File){
  if (-not (Test-Path $File)) { return $null }
  $lines = Get-Content $File
  if ($lines.Count -eq 0 -or $lines[0].Trim() -ne '---') { return $null }
  for ($i=1; $i -lt $lines.Count; $i++) {
    if ($lines[$i].Trim() -eq '---') { break }
    if ($lines[$i] -match '^status:\s*(.*)$') { return $Matches[1].Trim() }
  }
  return $null
}
function Resolve-Feature([string]$Root){
  if (-not $Root) { $Root = Find-SpexRoot }
  if (-not $Root) { return $null }
  $specs = Join-Path $Root 'spex\specs'
  $ptr = Join-Path $Root 'spex\active-feature'
  if (Test-Path $ptr) {
    $f = (Get-Content $ptr -Raw).Trim()
    if ($f -and (Test-Path (Join-Path $specs $f))) { return $f }
  }
  $br = (& git -C $Root rev-parse --abbrev-ref HEAD 2>$null)
  if ($br -and ($br -match '^[0-9]{3}-') -and (Test-Path (Join-Path $specs $br))) { return $br }
  $dirs = @(Get-ChildItem -Directory $specs -ErrorAction SilentlyContinue)
  if ($dirs.Count -eq 1) { return $dirs[0].Name }
  if ($dirs.Count -eq 0) { return $null }
  return ($dirs | Sort-Object LastWriteTime -Descending | Select-Object -First 1).Name
}
```

- [ ] **Step 4: Write `new-feature.ps1`**

```powershell
. "$PSScriptRoot\common.ps1"
$json = $false; $branch = $false; $descParts = @()
for ($i=0; $i -lt $args.Count; $i++) {
  switch ($args[$i]) {
    '--json'   { $json = $true }
    '--branch' { $branch = $true }
    default    { $descParts += $args[$i] }
  }
}
$desc = ($descParts -join ' ').Trim()
if (-not $desc) { [Console]::Error.WriteLine('error: feature description required'); exit 1 }
$root = Find-SpexRoot
if (-not $root) { [Console]::Error.WriteLine('error: spex/ not found (run /spex:init)'); exit 1 }
$specs = Join-Path $root 'spex\specs'; New-Item -ItemType Directory -Force -Path $specs | Out-Null

$max = 0
Get-ChildItem -Directory $specs -ErrorAction SilentlyContinue | ForEach-Object {
  if ($_.Name -match '^(\d{3})-') { $n = [int]$Matches[1]; if ($n -gt $max) { $max = $n } }
}
$num = '{0:000}' -f ($max + 1)
$slug = ($desc.ToLower() -replace '[^a-z0-9]+','-').Trim('-')
$slug = ($slug -split '-' | Select-Object -First 5) -join '-'
if ($slug.Length -gt 50) { $slug = $slug.Substring(0,50).Trim('-') }
if (-not $slug) { $slug = 'feature' }

$feat = "$num-$slug"; $dir = Join-Path $specs $feat
if (Test-Path $dir) { [Console]::Error.WriteLine("error: $feat already exists"); exit 1 }
New-Item -ItemType Directory -Force -Path $dir | Out-Null
"---`nfeature: $feat`nstatus: draft`n---" | Out-File -Encoding utf8 (Join-Path $dir 'spec.md')
$feat | Out-File -Encoding utf8 (Join-Path $root 'spex\active-feature')

if ($branch) { & git -C $root checkout -b $feat 2>$null | Out-Null }

$specFile = Join-Path $dir 'spec.md'
if ($json) {
  '{"feature":"' + $feat + '","feature_dir":"' + $dir + '","spec_file":"' + $specFile + '"}'
} else {
  "FEATURE=$feat`nFEATURE_DIR=$dir`nSPEC_FILE=$specFile"
}
```

- [ ] **Step 5: Write `check.ps1`**

```powershell
. "$PSScriptRoot\common.ps1"
$json = $false; $phase = ''
for ($i=0; $i -lt $args.Count; $i++) {
  switch ($args[$i]) {
    '--json'  { $json = $true }
    '--phase' { $i++; $phase = $args[$i] }
  }
}
$root = Find-SpexRoot
if (-not $root) { [Console]::Error.WriteLine('error: spex/ not found'); exit 2 }
$feat = Resolve-Feature $root
if (-not $feat) { [Console]::Error.WriteLine('error: no active feature'); exit 2 }
$dir = Join-Path $root "spex\specs\$feat"

switch ($phase) {
  'design'    { $prior = Join-Path $dir 'spec.md';   $label = 'spec' }
  'tasks'     { $prior = Join-Path $dir 'design.md'; $label = 'design' }
  'implement' { $prior = Join-Path $dir 'tasks.md';  $label = 'tasks' }
  default     { [Console]::Error.WriteLine('error: --phase must be design|tasks|implement'); exit 2 }
}

$ok = $true; $blocking = ''
if (-not (Test-Path $prior)) { $ok = $false; $blocking = "$label.md missing" }
else {
  $st = Get-FrontmatterStatus $prior
  if ($st -ne 'approved') { $ok = $false; $blocking = "$label.md not approved (status: $(if($st){$st}else{'none'}))" }
}

$docs = @()
$det = Join-Path $dir 'details'
if (Test-Path $det) { Get-ChildItem "$det\*.md" -ErrorAction SilentlyContinue | ForEach-Object { $docs += "details/$($_.Name)" } }
$td = Join-Path $root 'spex\memory\tech-docs'
if (Test-Path $td) { Get-ChildItem "$td\*.md" -ErrorAction SilentlyContinue | ForEach-Object { $docs += "tech-docs/$($_.Name)" } }
$docsStr = ($docs -join ',')

if ($json) {
  '{"feature":"' + $feat + '","feature_dir":"' + $dir + '","phase":"' + $phase +
  '","ok":' + ($ok.ToString().ToLower()) + ',"blocking":"' + $blocking +
  '","available_docs":"' + $docsStr + '"}'
} else {
  "FEATURE=$feat`nPHASE=$phase`nOK=$(if($ok){1}else{0})`nDOCS=$docsStr"
  if ($blocking) { "BLOCKING=$blocking" }
}
if ($ok) { exit 0 } else { exit 1 }
```

- [ ] **Step 6: Run parity tests to verify they pass**

Run: `powershell -NoProfile -File tests/powershell/test-scripts.ps1`
Expected: PASS — `pass=6 fail=0`, exit 0.

- [ ] **Step 7: Commit**

```bash
git add skills/spex-init/scripts/powershell tests/powershell/test-scripts.ps1
git commit -m "feat(scripts): add PowerShell port + parity tests"
```

---

### Task 5: Update `spex-init` — materialize the script layer

**Files:**
- Modify: `skills/spex-init/SKILL.md`

**Interfaces:**
- Consumes: bundled scripts at `${CLAUDE_SKILL_DIR}/scripts/`.
- Produces: project `spex/scripts/` (copied) + `scripts: true|false` in `config.yml` + a one-line `spex/active-feature` is NOT created here (created by `new-feature`).

- [ ] **Step 1: Add the scaffold detail to step 2**

In `skills/spex-init/SKILL.md`, edit the Flow step 2 (Scaffold) to add `scripts:` to the `config.yml` keys list: change the parenthetical to `(`fastspex:1`, `mode`, `created`, `self_review: true`, `scripts`, `docs_source`)`.

- [ ] **Step 2: Add a new Flow step "Materialize script layer (Claude Code only)"**

Insert after the current step 2 (Scaffold), before "Gather inputs":

```markdown
2b. **Materialize the optional script layer (Claude Code + shell only).** If running under
   Claude Code AND a shell is available AND `${CLAUDE_SKILL_DIR}/scripts/` exists, copy it to
   `spex/scripts/` (both `bash/` and `powershell/`) and set `scripts: true` in `config.yml`.
   Otherwise set `scripts: false`. Never fail init if the copy can't happen — fall back to
   `scripts: false`. These scripts are an optimization; all skills still work without them.
```

- [ ] **Step 3: Add a Red-flags row**

Add to the Red-flags table:

```markdown
| "Call scripts from the plugin cache directly" | Cache is ephemeral. Copy to `spex/scripts/` once; reference that. |
```

- [ ] **Step 4: Verify the skill still reads cleanly**

Run: `grep -n "scripts" skills/spex-init/SKILL.md`
Expected: shows the new step 2b, the `config.yml` key, and the red-flag row.

- [ ] **Step 5: Commit**

```bash
git add skills/spex-init/SKILL.md
git commit -m "feat(init): materialize optional script layer into spex/scripts"
```

---

### Task 6: `spex-spec` — Step 0 + wire Save to `new-feature`

**Files:**
- Modify: `skills/spex-spec/SKILL.md`

**Interfaces:**
- Consumes: `spex/scripts/{bash,powershell}/new-feature.{sh,ps1}` when present.
- Produces: same `spex/specs/<feature>/spec.md` as before (numbered when scripts present).

- [ ] **Step 1: Add Step 0 to Flow (before "Frame")**

```markdown
0. **Locate feature (optional script).** If `spex/scripts/` exists and a shell is available,
   create the numbered feature dir with the helper:
   `bash spex/scripts/bash/new-feature.sh --json "<short description>"` (POSIX) or
   `powershell -File spex/scripts/powershell/new-feature.ps1 --json "<short description>"` (Windows),
   then write the spec body into the `spec_file` it returns. Otherwise (no scripts) create
   `spex/specs/<NNN-slug>/spec.md` inline using the numbering rule: `NNN` = highest existing
   `spex/specs/NNN-*` + 1 (zero-padded 3); slug = lowercase, non-alnum→`-`, ≤5 words.
```

- [ ] **Step 2: Adjust the Save step**

Change step 5 ("Save `spex/specs/<feature>/spec.md`") to: "Save the spec body into the feature dir from Step 0 (status: draft)."

- [ ] **Step 3: Verify**

Run: `grep -n "new-feature\|Locate feature\|numbering rule" skills/spex-spec/SKILL.md`
Expected: shows the new Step 0 text.

- [ ] **Step 4: Commit**

```bash
git add skills/spex-spec/SKILL.md
git commit -m "feat(spec): add Step 0 locate-feature with new-feature fallback"
```

---

### Task 7: Step 0 for `spex-design`, `spex-tasks`, `spex-implement`

**Files:**
- Modify: `skills/spex-design/SKILL.md`
- Modify: `skills/spex-tasks/SKILL.md`
- Modify: `skills/spex-implement/SKILL.md`

**Interfaces:**
- Consumes: `spex/scripts/{bash,powershell}/check.{sh,ps1}` when present.
- Produces: enforced entry gate (prior artifact `approved`) — same as the existing prompt checks, now script-backed when available.

- [ ] **Step 1: Add Step 0 to `spex-design` (phase=design)**

Insert as the new first Flow step (renumber the rest):

```markdown
0. **Locate & gate (optional script).** If `spex/scripts/` exists and a shell is available, run
   `bash spex/scripts/bash/check.sh --json --phase design` (POSIX) or
   `powershell -File spex/scripts/powershell/check.ps1 --json --phase design` (Windows); if it
   exits non-zero, STOP and report `blocking`. Use its `feature_dir`/`available_docs`. Otherwise
   do it inline: resolve the active feature (active-feature file → git branch `NNN-*` → single
   specs dir → newest) and confirm `spec.md` is `status: approved`; if not, stop.
```

- [ ] **Step 2: Add Step 0 to `spex-tasks` (phase=tasks)**

Same block, with `--phase tasks` and "confirm `design.md` is `status: approved`".

- [ ] **Step 3: Add Step 0 to `spex-implement` (phase=implement)**

Same block, with `--phase implement` and "confirm `tasks.md` is `status: approved`".

- [ ] **Step 4: Verify all three**

Run: `grep -l "Locate & gate" skills/spex-design/SKILL.md skills/spex-tasks/SKILL.md skills/spex-implement/SKILL.md`
Expected: all three paths listed.

- [ ] **Step 5: Commit**

```bash
git add skills/spex-design/SKILL.md skills/spex-tasks/SKILL.md skills/spex-implement/SKILL.md
git commit -m "feat(skills): add script-backed entry gate (Step 0) to design/tasks/implement"
```

---

### Task 8: Docs refresh (README, CLAUDE.md, IMPLEMENTATION_PLAN.md)

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`
- Modify: `IMPLEMENTATION_PLAN.md`

**Interfaces:** none (documentation only).

- [ ] **Step 1: README — add an "Optional script layer" subsection**

Under `## Use`, add:

```markdown
### Optional script layer (Claude Code)
On Claude Code, `/spex:init` copies tiny helper scripts to `spex/scripts/` that make feature
numbering and the spec→design→tasks→implement gates deterministic (exit-code based). On any
other agent the scripts are simply absent and every command runs the same logic inline — no
behavior change, no runtime required.
```

- [ ] **Step 2: CLAUDE.md — add one Key-rules line**

Add under `## Key rules`:

```markdown
- On Claude Code, an optional `spex/scripts/` layer (bash + PowerShell) does numbering + hard gates; skills fall back to prompt logic when it's absent.
```

- [ ] **Step 3: Refresh IMPLEMENTATION_PLAN.md to match the current toolkit**

The plan is stale. Update these facts to reflect the shipped repo:
- Skill set is `init · spec · design · tasks · implement` (no `plan`, no `update`).
- Memory files are `product.md · tech.md · structure.md · constitution.md` (not `project.md`).
- Artifacts are `spec.md · design.md · tasks.md` (not `plan.md`).
- Add a short "Optional script layer (Claude Code)" bullet to the design-decisions section referencing `docs/designs/2026-06-20-hybrid-script-layer-design.md`.

Apply minimal edits — do not rewrite the whole file; fix the divergent names and add the one bullet.

- [ ] **Step 4: Verify no stale names remain in the touched sections**

Run: `grep -n "spex-update\|plan.md\|project.md" IMPLEMENTATION_PLAN.md`
Expected: only historical/contextual mentions remain (decisions log), not current-structure claims. Confirm the file layout block now lists `design.md`, `product.md`, `structure.md`.

- [ ] **Step 5: Commit**

```bash
git add README.md CLAUDE.md IMPLEMENTATION_PLAN.md
git commit -m "docs: document optional script layer; refresh stale implementation plan"
```

---

### Task 9: End-to-end verification

**Files:** none (verification only).

**Interfaces:** exercises the full toolkit both with and without scripts.

- [ ] **Step 1: Script-mode dry run (bash)**

In a scratch dir:
```bash
mkdir -p /tmp/spxtest && cd /tmp/spxtest
mkdir -p spex/specs spex/memory/tech-docs
printf 'fastspex: 1\nmode: brownfield\nself_review: true\nscripts: true\n' > spex/config.yml
cp -r "$OLDPWD/skills/spex-init/scripts" spex/scripts
bash spex/scripts/bash/new-feature.sh --json "demo feature"
bash spex/scripts/bash/check.sh --json --phase design   # expect ok=false (draft)
sed -i 's/status: draft/status: approved/' spex/specs/001-demo-feature/spec.md
bash spex/scripts/bash/check.sh --json --phase design   # expect ok=true, exit 0
```
Expected: numbering `001-demo-feature`; gate flips false→true.

- [ ] **Step 2: Run the full bash test suite once more**

Run: `for t in tests/bash/test-*.sh; do echo "== $t"; bash "$t" || exit 1; done`
Expected: every suite `fail=0`.

- [ ] **Step 3: Run the PowerShell parity suite**

Run: `powershell -NoProfile -File tests/powershell/test-scripts.ps1`
Expected: `fail=0`, exit 0.

- [ ] **Step 4: Fallback simulation**

Remove `spex/scripts/` from the scratch dir and confirm the skills' Step 0 inline rule is self-sufficient: numbering and gate descriptions in the SKILL.md files reference only files/dirs that exist without scripts. (Manual read-through — no runtime.)
Expected: each Step 0 has a complete "Otherwise (no scripts) …" branch.

- [ ] **Step 5: Final commit (if any cleanup)**

```bash
git add -A
git commit -m "test: verify hybrid script layer end-to-end (script + fallback)"
```
