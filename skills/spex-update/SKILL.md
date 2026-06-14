---
name: spex-update
description: Update Fastspex knowledge/config — edit project, tech, constitution, docs digests, or config toggles. Re-distills docs and bumps constitution version as needed.
---
# Fastspex: Update

## Overview
Maintain the living context. **Core principle: edits keep files lean — apply the same anti-bloat rules.**

## When to use
- `/spex:update [project|tech|constitution|docs|config]` to change context after init.

## Flow
1. **Load** the target file(s).
2. **project / constitution:** apply the change; keep ≤ the existing discipline (no padding). constitution → bump **Version** + record the reason in Governance.
3. **tech:** add/remove libs → re-resolve IDs; for affected libs re-distill digests (Context7 → ContextHub → WebSearch) → tech-docs/.
4. **docs:** refresh a specific tech-docs/<lib>.md digest (keep it focused on used APIs).
5. **config:** flip toggles in `spex/config.yml` (e.g., `self_review: false`).
6. **Brief** what changed + where. No gate.

## Self-review
If enabled: change is minimal and consistent; no placeholders; constitution version bumped if edited. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "Rewrite the whole file" | Apply the smallest change that satisfies the request. |
| "Add more rules while editing" | Only what was asked. |
| "Skip the version bump" | Constitution edits always bump version + reason. |
