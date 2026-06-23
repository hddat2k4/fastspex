---
name: tasks
description: Break an approved design into a granular, traceable task checklist (tasks.md) — two-level decimal checkboxes, per-sub-task granular requirement IDs, kept parallel-safe with [P]. Requires approval before /implement.
---
# Fastspex: Tasks

## Overview
Convert the design into small, test-driven coding steps. **Core principle: each sub-task is independent, ends wired-in (no orphaned code), and traces to granular requirement criterion IDs.**

## When to use
- After design.md is `approved`.

## Flow
0. **Locate & gate.** If `spex/scripts/` exists and a shell is available, run
   `bash spex/scripts/bash/check.sh --json --phase tasks` (POSIX) or
   `powershell -File spex/scripts/powershell/check.ps1 --json --phase tasks` (Windows); if it
   exits non-zero, STOP and report `blocking`. Use its `feature_dir` + `available_docs`.
   Otherwise resolve the active feature inline (active-feature file → git branch `NNN-*` →
   single specs dir → newest) and confirm `design.md` is `status: approved`; if not, stop.
1. **Read** spec + design (+ details/ + tech-docs/).
2. **Decompose** into the tasks.md template:
   - Two-level decimal checkboxes ONLY: `- [ ] N` (group) then `- [ ] N.M` (sub-task). Max two levels; further detail = plain bullets.
   - Each sub-task `N.M` ends with its OWN `_Requirements: a.b, c.d_` citing **GRANULAR criterion IDs** from the spec (e.g. `1.1`, `7.6`) — never whole requirements (`1`), never one shared line per group.
   - Order: schema → services → APIs → UI → integration → tests.
   - File paths in backticks. States `[ ]`/`[x]`/`[/]`; deviation/result notes in `>` blockquotes.
   - Coding tasks only (write/modify/test code). EXCLUDE deploy, UAT, performance-metrics gathering, manual e2e, training, marketing. An optional terminal `## N. Out of scope (capture only)` group MAY list excluded items as plain bullets.
3. **Independence + parallelism:** make each sub-task self-contained; never let two tasks edit the same file at once; group files-that-change-together. Mark `[P]` on each parallel-safe sub-task; add `(after N.M)` only when a dependency is unavoidable.
4. **TDD** per constitution test policy. Right-size for small features.
5. **Save** tasks.md (status: draft).
6. **HARD-GATE.** Prefer `AskUserQuestion`; a typed token (`approved`/`looks good`/`yes`/`lgtm`/`ok proceed`) is also accepted:
   ```json
   {
     "questions": [
       {
         "question": "Approve these tasks and proceed to /implement?",
         "header": "Tasks approval",
         "multiSelect": false,
         "options": [
           { "label": "Approve", "description": "Set status: approved; I'll then suggest /implement without running it" },
           { "label": "Request changes", "description": "Describe what to change, then I revise and re-gate" }
         ]
       }
     ]
   }
   ```
   - On **Approve** (button or token): set tasks.md status to `approved`, stop, and state **→ Next: `/implement`** — suggest it **without running it**.
   - On **Request changes**: edit tasks.md, re-save as draft, then re-run the gate.

## Self-review
If enabled: every requirement criterion maps to ≥1 sub-task; each `N.M` has its OWN granular `_Requirements:_`; no orphan task beyond spec/design; no two parallel tasks touch the same file; dependencies minimal and correct. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "One giant task is simpler" | Split into N.M sub-tasks by responsibility so they stay independent. |
| "Cite the whole requirement (R1) is fine" | Cite granular IDs (1.1, 1.6). That's the locked rule. |
| "Add a task to clean things up" | Not in the design → don't. |
| "These two tasks can share edits to file X" | Merge them or sequence them — never parallel-edit one file. |
| "Implement it now while I'm here" | Tasks phase only writes tasks.md. Implementation is /implement. |
