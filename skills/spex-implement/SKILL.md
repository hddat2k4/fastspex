---
name: spex-implement
description: Execute tasks.md — TDD per task, scope-guard, tick [x]. Sequential by default with an option to run independent [P] tasks in parallel. Verify tests before claiming done.
---
# Fastspex: Implement

## Overview
Build exactly what the tasks say. **Core principle (scope-guard): code only what the task/requirement asks — nothing extra.**

## When to use
- After tasks.md exists.

## Flow
1. **Read** spec + design + tasks + memory (product, tech, structure, constitution, tech-docs/). Always read all three spec/design/tasks before executing — executing without them leads to wrong implementations.
2. **Confirm execution mode with AskUserQuestion.** If tasks.md contains one or more `[P]` (parallel-safe) markers:
   ```json
   {
     "questions": [
       {
         "question": "This task list has {N} independent [P] task(s). Run them in parallel?",
         "header": "Execution mode",
         "multiSelect": false,
         "options": [
           { "label": "Yes, run [P] tasks in parallel", "description": "Faster; each [P] task gets its own agent" },
           { "label": "No, run everything sequentially", "description": "Slower, uses fewer agents, simpler to follow" }
         ]
       }
     ]
   }
   ```
   - If **yes**: dispatch each `[P]` task to a subagent concurrently; keep dependent tasks sequential. Subagents CANNOT ask the user; give them full context (spec, design, constitution, relevant tech-docs, task snippet).
   - If **no**: run all tasks sequentially.
   - If no `[P]` markers exist, default to sequential and skip the question.
3. **Per task (TDD):** write the failing test → run it (see it fail) → minimal implementation → run tests (pass) → tick `[x]`. Use the test command from `tech.md` `## Commands`.
4. **Scope-guard:** implement only the task and the granular criteria its `_Requirements: N.M_` cites (look them up in spec.md). No "while I'm here" refactors, no extra options.
5. **Docs:** use tech-docs/; if a needed digest is missing → resolve via `docs_source` (Context7 · WebSearch; fall back if it fails, else pointer) → save.
6. **Self-review + verify:** if enabled, confirm code matches task/spec with nothing extra; then RUN the tests and read output before claiming anything passes.
7. Feature done when all tasks are `[x]`.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "Refactor this to be cleaner" | Out of task. Don't. |
| "Add an option just in case" | YAGNI. Build the task only. |
| "This task is like the other, do it too" | Follow tasks.md exactly. |
| "Tests probably pass" | No completion claims without fresh test output. |
