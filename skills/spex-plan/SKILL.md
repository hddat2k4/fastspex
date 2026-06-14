---
name: spex-plan
description: Turn an approved spec into a lean technical plan (HOW) with optional detail files; pulls docs via Context7/ContextHub/WebSearch; requires approval before /spex:tasks.
---
# Fastspex: Plan

## Overview
Decide HOW to build the approved spec — lean overview, depth in linked detail files. **Core principle: the plan never exceeds the spec.**

## When to use
- After a spec is `approved`. If spec.md status ≠ approved → stop.

## Flow
1. **Read** spec.md + memory/ (project, tech, constitution).
2. **Distill docs** for libs this feature touches (lazy): ensure tech-docs/ exists; if missing → Context7 → ContextHub → WebSearch → save digest.
3. **Draft plan.md** (template, 2-tier): Approach · Changes (create/modify/delete) · Error handling · Testing · Docs used · Details(links). Heavy topics (data model, contracts, decisions, architecture+Mermaid) → `details/<file>.md`, linked only. Create a detail file ONLY when it would bloat plan.md.
4. **Scope-check + Constitution Check**: the plan adds nothing beyond the spec and violates no constitution rule. Flag and ask on conflict.
5. **Save** plan.md (status: draft).
6. **HARD-GATE.**

## Self-review
If enabled: every requirement is addressed by some change; no placeholders; no design beyond spec; detail links resolve. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "Add an abstraction for flexibility" | Not unless the spec needs it. YAGNI. |
| "Refactor this while I'm here" | Out of spec → note it and ask, don't do it. |
| "Put all the docs in the plan" | Digest only what's used; link details/. |

<HARD-GATE>
Do NOT proceed to /spex:tasks until the user approves. On approval set status: approved.
</HARD-GATE>
