#!/usr/bin/env bash
# Regression guard for the prose (skill) edits of feature 001-reduce-prompt-friction.
# Greps the SKILL.md files + CLAUDE.md to lock the spec's intent (cheap, not behavioral).
HERE="$(cd "$(dirname "$0")" && pwd)"
. "$HERE/lib.sh"
SK="$HERE/../../skills"
ROOT="$HERE/../.."

init="$SK/init/SKILL.md"
spec="$SK/spec/SKILL.md"
design="$SK/design/SKILL.md"
tasks="$SK/tasks/SKILL.md"
implement="$SK/implement/SKILL.md"
claudemd="$ROOT/CLAUDE.md"

has(){ grep -qi -- "$2" "$1" && echo yes || echo no; }   # has FILE PATTERN -> yes/no (patterns are regex-safe)

# --- R1: init auto-detects mode, no confirmation prompt ---
assert_eq "$(has "$init" 'I detected this as a')" "no" "init: mode-confirm question removed"
assert_eq "$(has "$init" 'switch to greenfield')"  "no" "init: mode-confirm options removed"

# --- R2.7 / R2.5: doc-source question removed; config field swapped ---
assert_eq "$(has "$init" 'Choose the primary doc source')" "no"  "init: doc-source question removed"
assert_eq "$(has "$init" 'contexthub_install')"            "yes" "init: config writes contexthub_install"
assert_eq "$(has "$init" 'docs_source')"                   "no"  "init: docs_source removed"

# --- R2.1: resolution chain present at all three distillation sites; docs_source gone there too ---
for f in "$init" "$design" "$implement"; do
  name="$(basename "$(dirname "$f")")"
  assert_eq "$(has "$f" 'Context7')"          "yes" "$name: chain mentions Context7"
  assert_eq "$(has "$f" 'ContextHub')"        "yes" "$name: chain mentions ContextHub"
  assert_eq "$(has "$f" 'WebSearch')"         "yes" "$name: chain mentions WebSearch"
  assert_eq "$(has "$f" 'install-contexthub')" "yes" "$name: references install-contexthub script"
  assert_eq "$(has "$f" 'docs_source')"       "no"  "$name: docs_source replaced"
done

# --- R4: gates are binary + suggest-next, never auto-run ---
for f in "$spec" "$design" "$tasks"; do
  name="$(basename "$(dirname "$f")")"
  assert_eq "$(has "$f" 'Request changes')"   "yes" "$name gate: keeps Request changes option"
  assert_eq "$(has "$f" 'Reject and stop')"   "no"  "$name gate: dropped third option"
  assert_eq "$(has "$f" 'without running it')" "yes" "$name gate: suggests next step, no auto-run"
  assert_eq "$(has "$f" 'Next:')"             "yes" "$name gate: states the next step"
done

# --- R3: spec asks clarifications directly, recommended-first, no meta-prompt ---
assert_eq "$(has "$spec" 'What would you like to do')" "no"  "spec: clarification meta-prompt removed"
assert_eq "$(has "$spec" 'Approve anyway')"            "no"  "spec: 'approve anyway' option removed"
assert_eq "$(has "$spec" 'recommend')"                 "yes" "spec: recommended-first language present"

# --- R2.1: top-level CLAUDE.md doc line updated ---
assert_eq "$(has "$claudemd" 'ContextHub')" "yes" "CLAUDE.md: docs chain includes ContextHub"

summary
