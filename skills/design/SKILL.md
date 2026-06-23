---
name: design
description: Turn an approved spec into a technical design (HOW) — core sections inline, heavy detail summarized and offloaded to details/ via links; pulls docs via Context7/WebSearch; requires approval before /tasks.
---
# Fastspex: Design

## Overview
Decide HOW to build the approved spec. **Keep core sections inline; offload heavy detail to `details/` and map to it with links. Core principle: the design never exceeds the spec.**

## When to use
- After a spec is `approved`. If spec.md status ≠ approved → stop.

## Flow
0. **Locate & gate.** If `spex/scripts/` exists and a shell is available, run
   `bash spex/scripts/bash/check.sh --json --phase design` (POSIX) or
   `powershell -File spex/scripts/powershell/check.ps1 --json --phase design` (Windows); if it
   exits non-zero, STOP and report `blocking`. Use its `feature_dir` + `available_docs`.
   Otherwise resolve the active feature inline (active-feature file → git branch `NNN-*` →
   single specs dir → newest) and confirm `spec.md` is `status: approved`; if not, stop.
1. **Read** spec.md + memory/ (product, tech, structure, constitution).
2. **Distill docs** for libs this feature touches (lazy): if a digest is missing → resolve the doc source (see block below) → save digest to `tech-docs/<lib>.md`.

   **Doc-source resolution** (run for each digest to distill):
   1. If the **Context7** MCP is available → use Context7.
   2. Else if **ContextHub** is installed (`contexthub_install: installed` in `spex/config.yml` and `chub-mcp` reachable) → use ContextHub.
   3. Else if `contexthub_install` is `unknown` → ask the user ONCE with a binary `AskUserQuestion` ("Install ContextHub for better API docs?", recommended option first): on **Yes** run `spex/scripts/bash/install-contexthub.sh` (POSIX) or `spex/scripts/powershell/install-contexthub.ps1` (Windows), then on success set `contexthub_install: installed` and use ContextHub; on **No** set `contexthub_install: declined`.
   4. Else → use **WebSearch / WebFetch**.
   If a chosen source fails at query time, fall to the next tier; if every tier fails, save a name+version pointer noting "docs not distilled". Never block.
3. **Draft design.md** (template). Sections that stay **inline** (always): Overview + Technology Decisions, Out of scope, Architecture / Components and Interfaces (one line each: purpose + file path), Error Handling, and **Testing Strategy (MANDATORY — never push all testing to tasks)**.
4. **Offload heavy detail.** Data Model, API/Contracts, long component signatures, Request Flow diagrams (Mermaid), and key decisions/ADRs each get a **2–3 line summary inline + a link** to `details/<file>.md`. **Anti-drift rule: the `details/` file is the SINGLE source of truth — never duplicate its full content inline.** Create a detail file ONLY when the topic is heavy enough to bloat design.md; link only files that exist.
5. **Map tech-docs (2 tiers):** keep a `## Docs used` index (`<lib> → tech-docs/<lib>.md`, Context7 id), AND annotate each Component that relies on a library with `(docs: tech-docs/<lib>.md)` so the implementer knows which digest to open.
6. **Scope-check + Constitution Check**: the design adds nothing beyond the spec and violates no constitution rule. Flag and ask on conflict.
7. **Save** design.md (status: draft).
8. **HARD-GATE.** Prefer `AskUserQuestion`; a typed token (`approved`/`looks good`/`yes`/`lgtm`/`ok proceed`) is also accepted. Present for approval or targeted changes:
   ```json
   {
     "questions": [
       {
         "question": "Approve this design and proceed to /tasks?",
         "header": "Design approval",
         "multiSelect": false,
         "options": [
           { "label": "Approve", "description": "Set status: approved; I'll then suggest /tasks without running it" },
           { "label": "Request changes", "description": "Describe what to change, then I revise and re-gate" }
         ]
       }
     ]
   }
   ```
   - On **Approve** (button or token): set design.md status to `approved`, stop, and state **→ Next: `/tasks`** — suggest it **without running it**.
   - On **Request changes**: collect the feedback, edit design.md (and any `details/` file), re-save as draft, then re-run the gate.
   - If requirement gaps surface, offer to return to /spec.

## Self-review
If enabled: every requirement is addressed by some component/change; **Testing Strategy present**; no placeholders; no design beyond spec; every `details/` link resolves; no full-detail duplicated inline. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "Paste the whole schema inline too" | Detail file is the source of truth. Inline = summary + link only. |
| "Add an abstraction for flexibility" | Not unless the spec needs it. YAGNI. |
| "Refactor this while I'm here" | Out of spec → note it and ask, don't do it. |
| "Skip Testing Strategy, tasks will cover it" | Testing Strategy is mandatory in the design. |
| "Put all the docs in the design" | Digest only what's used; link `tech-docs/` and `details/`. |
