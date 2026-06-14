---
name: spex-tasks
description: Break an approved plan into an independent, traceable task checklist (tasks.md). No approval gate.
---
# Fastspex: Tasks

## Overview
Decompose the plan into a checklist. **Core principle: tasks are independent and each traces to a requirement.**

## When to use
- After plan.md is `approved`.

## Flow
1. **Read** spec + plan (+ details/).
2. **Decompose** into ordered tasks in tasks.md; each tagged `_Req: Rx_` and tied to a plan "Change".
3. **Granularity (hybrid):** default coarse (1 task = 1 logical unit, ~≤30 min, TDD implied); split into 2-level sub-tasks (T1.1) only when complex.
4. **Independence:** make each task self-contained; never let two tasks edit the same file; group files-that-change-together. Mark `[P]` for parallel-safe tasks; add a dependency ("after T1") only when unavoidable.
5. **TDD** per constitution test policy. Right-size for small features.
6. **Save** tasks.md (status: draft) → ready for /spex:implement.

## Self-review
If enabled: every requirement maps to ≥1 task; no orphan task beyond spec/plan; dependencies minimal and correct. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "One giant task is simpler" | Split by responsibility so tasks stay independent. |
| "Add a task to clean things up" | Not in the plan → don't. |
| "These two tasks can share edits to file X" | Merge them or sequence them — never parallel-edit one file. |
