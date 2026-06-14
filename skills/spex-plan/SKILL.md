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
2. **Distill docs** for libs this feature touches (lazy): if a digest is missing → resolve via `docs_source` (Context7 · ContextHub=**spex-contexthub** · WebSearch; fall back through the rest if it fails, else save a pointer) → save digest.
3. **Draft plan.md** (template, 2-tier): Approach · Changes (create/modify/delete) · Error handling · Testing · Docs used · Details(links). Heavy topics (data model, contracts, decisions, architecture+Mermaid) → `details/<file>.md`, linked only. Create a detail file ONLY when it would bloat plan.md.
4. **Scope-check + Constitution Check**: the plan adds nothing beyond the spec and violates no constitution rule. Flag and ask on conflict.
5. **Save** plan.md (status: draft).
6. **HARD-GATE via AskUserQuestion.** Present the plan for approval or targeted changes:
   ```json
   {
     "questions": [
       {
         "question": "Approve this plan and proceed to /spex:tasks?",
         "header": "Plan approval",
         "multiSelect": false,
         "options": [
           { "label": "Approve", "description": "Set status: approved and continue" },
           { "label": "Request changes", "description": "Describe what to change, then revise" },
           { "label": "Reject and stop", "description": "Keep as draft, do not generate tasks" }
         ]
       }
     ]
   }
   ```
   - On **Approve**: set plan.md status to `approved` and stop. The next command is `/spex:tasks`.
   - On **Request changes**: collect the feedback, edit plan.md, re-save as draft, then re-run the gate.
   - On **Reject**: keep status as `draft` and stop.

## Self-review
If enabled: every requirement is addressed by some change; no placeholders; no design beyond spec; detail links resolve. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "Add an abstraction for flexibility" | Not unless the spec needs it. YAGNI. |
| "Refactor this while I'm here" | Out of spec → note it and ask, don't do it. |
| "Put all the docs in the plan" | Digest only what's used; link details/. |
