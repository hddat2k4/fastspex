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
1. **Detect mode.** Code/manifests/.git present → brownfield; empty → greenfield. Confirm with the user (1 question).
2. **Scaffold (do not clobber).** If `spex/` exists → stop and offer update / re-init / abort. Else create:
   `spex/memory/`, `spex/memory/tech-docs/`, `spex/specs/`, and `spex/config.yml` (fastspex:1, mode, created, self_review: true).
3. **Generate project.md** (template). greenfield: ask ≤5 questions (purpose+who · 3–5 MVP features · out of scope) → propose an annotated tree from the stack. brownfield: shallow `tree` (depth 2, ignore node_modules/.git/dist) → annotated tree + naming + README → present "inferred from …" → confirm.
4. **Generate tech.md** (template). greenfield: ask intended stack → resolve-library-id per lib → store ID+version. brownfield: parse manifests (package.json/requirements.txt/go.mod/pom.xml…) → resolve IDs. Then **eager-distill CORE libs** (ask the user to confirm the short "core" set) → tech-docs/. Non-core stay pointers (lazy).
5. **Generate constitution.md** (template). greenfield: ask ≤5 questions (language/style, test policy, non-negotiables) → 2–5 principles, each name + verifiable rule + one-line rationale. brownfield: infer from lint config/CI/CONTRIBUTING/README → present with sources → confirm. ALWAYS keep the "Scope Discipline" section verbatim.
6. **Brief & handoff (NO gate).** Print 2–3 bullets per file (what was captured), then:
   "Review here: `spex/memory/`. To change anything: `/spex:update`. When ready: `/spex:spec`." Do not block.

## Self-review
If `spex/config.yml → self_review: true`: check no placeholders left; principles ≤5 and truly binding; project/tech reflect reality; nothing padded. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "spex/ exists, just overwrite" | Never clobber. Offer update / re-init / abort. |
| "Add a principle just in case" | A bloated constitution is useless. Only what's binding. |
| "Design an elaborate folder structure" | Reflect/propose only what's needed. |
| "Pre-download all docs now" | Only eager-distill CORE libs; the rest are pointers. |
| "They probably want strict mode" | Don't guess. Ask, or infer from real config. |
