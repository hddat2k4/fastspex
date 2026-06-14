---
name: spex-init
description: Initialize Fastspex in a project (greenfield or brownfield). Scaffolds spex/ and generates project.md, tech.md, constitution.md. Run once before /spex:spec.
---
# Fastspex: Init

## Overview
Set up the persistent context a spec-driven workflow needs. **Core principle: capture only what's binding; keep every file lean.**

## When to use
- Starting Fastspex in a repo. NOT for editing context later — use spex-update for that.

## Flow
1. **Auto-detect mode.** Inspect the repo before asking anything:
   - **brownfield** if any of: manifest files (`package.json`, `requirements.txt`, `go.mod`, `pom.xml`, `build.gradle`, `Cargo.toml`, `Gemfile`, `composer.json`, …), source folders (`src/`, `app/`, `lib/`, `packages/`, `tests/`, …), or a `.git/` directory with commits.
   - **greenfield** otherwise (empty repo, only README, no manifests/source).
   - Use `AskUserQuestion` to confirm one choice:
     ```json
     {
       "questions": [
         {
           "question": "I detected this as a {mode} project. Is that correct?",
           "header": "Project mode",
           "multiSelect": false,
           "options": [
             { "label": "Yes, proceed as detected", "description": "Continue with {mode}" },
             { "label": "No, switch to greenfield", "description": "Empty/new project" },
             { "label": "No, switch to brownfield", "description": "Existing codebase" }
           ]
         }
       ]
     }
     ```
   - Save final mode to `spex/config.yml` (`mode: greenfield | brownfield`).
2. **Scaffold (do not clobber).** If `spex/` exists → stop and offer update / re-init / abort. Else create:
   `spex/memory/`, `spex/memory/tech-docs/`, `spex/specs/`, and `spex/config.yml` (`fastspex:1`, `mode`, `created`, `self_review: true`, `docs_source`).
3. **Gather inputs, then offer parallel.** Subagents CANNOT ask the user, so collect everything the generators need first:
   - greenfield: ask the lean question sets up front — project (purpose+who · 3–5 MVP features · out of scope) · tech (intended stack) · constitution (language/style · test policy · non-negotiables).
   - brownfield: nothing to ask yet (generators read the repo), but parse manifests and **confirm the short CORE-libs set** here (the one human-in-loop step tech needs).
   - both modes: ask the **doc source** for distillation with `AskUserQuestion`:
     ```json
     {
       "questions": [
         {
           "question": "Choose the primary doc source for tech library digests.",
           "header": "Doc source",
           "multiSelect": false,
           "options": [
             { "label": "Context7 (MCP)", "description": "Most accurate; requires the Context7 MCP server" },
             { "label": "ContextHub (bundled)", "description": "No MCP required; runs spex-contexthub locally" },
             { "label": "WebSearch / WebFetch", "description": "Broadest reach, lower precision" }
           ]
         }
       ]
     }
     ```
     Save choice to `config.yml: docs_source`. Any choice still falls back if it fails.
   - Then ask ONE `AskUserQuestion` confirm for parallel generation:
     ```json
     {
       "questions": [
         {
           "question": "Launch 3 agents in parallel to write project.md, tech.md, and constitution.md?",
           "header": "Generate context files",
           "multiSelect": false,
           "options": [
             { "label": "Yes, run in parallel (recommended)", "description": "One agent per file, faster" },
             { "label": "No, run sequentially", "description": "Slower, uses fewer agents" }
           ]
         }
       ]
     }
     ```
4. **Generate (see File specs §A–§C).**
   - **Parallel = yes →** dispatch three subagents concurrently (one message, multiple Task calls): §A→project.md, §B→tech.md, §C→constitution.md. Give each the mode + gathered inputs + its file path + the template. Every agent: write ONLY its own file, NEVER ask the user, return a 2–3 bullet summary. Distinct files → safe in parallel.
   - **Parallel = no →** run §A, §B, §C yourself, sequentially. Same output.
5. **Brief & handoff (NO gate).** Print 2–3 bullets per file (what was captured), then:
   "Review here: `spex/memory/`. To change anything: `/spex:update`. When ready: `/spex:spec`." Do not block.

## File specs (each = one agent's job, or one sequential step)
- **§A project.md** (template). greenfield: gathered answers → propose an annotated tree from the stack. brownfield: shallow `tree` (depth 2, ignore node_modules/.git/dist) → annotated tree + naming + README, each marked "inferred from …".
- **§B tech.md** (template). Stack from stated input (greenfield) or parsed manifests (package.json/requirements.txt/go.mod/pom.xml…) (brownfield); record name+version (resolve the Context7 ID too when that source is available). **Eager-distill the CORE libs (step 3)** honoring `docs_source`: Context7 · **ContextHub = run spex-contexthub** · WebSearch — use the chosen source, fall back through the rest if it fails, and if none work save a **pointer (name+version) + note "docs not distilled"** (never block). Non-core stay pointers (lazy).
- **§C constitution.md** (template). greenfield: gathered answers → 2–5 principles, each name + verifiable rule + one-line rationale. brownfield: infer from lint config/CI/CONTRIBUTING/README, marked with sources. ALWAYS keep the "Scope Discipline" section verbatim.

## Self-review
If `spex/config.yml → self_review: true`: check no placeholders left; principles ≤5 and truly binding; project/tech reflect reality; no cross-file drift; nothing padded. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "spex/ exists, just overwrite" | Never clobber. Offer update / re-init / abort. |
| "Add a principle just in case" | A bloated constitution is useless. Only what's binding. |
| "Design an elaborate folder structure" | Reflect/propose only what's needed. |
| "Pre-download all docs now" | Only eager-distill CORE libs; the rest are pointers. |
| "They probably want strict mode" | Don't guess. Ask, or infer from real config. |
| "Let a subagent ask the user" | It can't. Gather every input in step 3, before fan-out. |
| "Parallel is better, skip the confirm" | Always offer the choice. Sequential is the fallback, not a bug. |
