---
name: spec
description: Write a clear feature spec (Introduction + Glossary + numbered EARS requirements with Priority + per-requirement Out of scope) before design. Drafts requirements, marks ambiguities, then requires approval before /design.
---
# Fastspex: Spec

## Overview
Turn one feature request into a testable WHAT/WHY spec. **Core principle: every requirement traces to the request; cut everything else.**

## When to use
- After /init, to define a single feature/change. One spec = one feature.

## Flow
0. **Locate feature & load steering context.** If `spex/scripts/` exists and a shell is
   available, create the numbered feature dir with the helper:
   `bash spex/scripts/bash/new-feature.sh --json "<short description>"` (POSIX) or
   `powershell -File spex/scripts/powershell/new-feature.ps1 --json "<short description>"`
   (Windows), then write the spec body into the `spec_file` it returns. Otherwise (no scripts)
   create `spex/specs/<NNN-slug>/spec.md` inline using the numbering rule: `NNN` = highest
   existing `spex/specs/NNN-*` + 1 (zero-padded to 3); slug = lowercase, non-alnum→`-`, ≤5 words.
   **Then read `spex/memory/product.md` and `spex/memory/tech.md` (when present)** so every
   user story traces to the product's Purpose/Users and assumes the real stack — don't invent either.
1. **Frame** the feature as a single change. Right-size: tiny/clear → a short spec.
2. **Draft the spec** in the spec.md template:
   - `## Introduction` — what/why, files or modules touched, what is explicitly NOT changed, deps on other specs.
   - `## Glossary` (optional) — define domain terms only when they'd otherwise be ambiguous.
   - `## Requirements` — one `### Requirement N: Title — [Must|Should|Could]` per requirement (Priority required), each with a `**User Story:**` line and a `#### Acceptance Criteria` list of **numbered EARS** lines. Numbering restarts per requirement → criterion IDs read `N.M` (1.1, 1.2…) so design/tasks can trace granularly. End each requirement with `**Out of scope:**` (`—` if none).
   - `## Non-goals` (optional) — overall boundary of what you're not building.
   - `## Business Rules (Restated)` (optional) — when pre-existing BR IDs exist, map each to a Requirement.
3. **Brownfield**: if touching an existing capability, write a DELTA (`## ADDED / ## MODIFIED / ## REMOVED Requirements`); MODIFIED copies the FULL requirement.
4. **Mark ambiguity** inline with `[NEEDS CLARIFICATION: …]` — **max 3**, prioritized by impact. Do not start a Q&A; draft first, let the user comment.
5. **Save** the spec body into the feature dir from Step 0, as `spec.md` (status: draft).
6. **HARD-GATE.** Prefer `AskUserQuestion`; a typed approval token (`approved` / `looks good` / `yes` / `lgtm` / `ok proceed`, case-insensitive) is ALSO accepted for portability to non-Claude agents. Present the spec for approval or targeted clarification:
   - If there ARE `[NEEDS CLARIFICATION]` markers: ask each one **directly** with `AskUserQuestion` — phrase the actual question and give concrete answer options, listing the **recommended** option FIRST (label it "(Recommended)"). Apply the chosen answer, remove that resolved marker, re-save the spec, and repeat for the next marker. When all markers are resolved, present the binary approval gate below. Do NOT show a meta-prompt asking whether to answer or accept assumptions.
   - When there are no remaining `[NEEDS CLARIFICATION]` markers, present the binary approval gate:
     ```json
     {
       "questions": [
         {
           "question": "Approve this spec and proceed to /design?",
           "header": "Spec approval",
           "multiSelect": false,
           "options": [
             { "label": "Approve", "description": "Set status: approved; I'll then suggest /design without running it" },
             { "label": "Request changes", "description": "Describe what to change, then I revise and re-gate" }
           ]
         }
       ]
     }
     ```
   - On **Approve** (button or typed token): set spec.md status to `approved`, stop, and state **→ Next: `/design`** — suggest it **without running it**.
   - On **Request changes**: collect the feedback, edit the spec, re-save as draft, then re-run the gate.

## Notation rules
- EARS patterns: Event `WHEN … THE SYSTEM SHALL …` · Ubiquitous `THE SYSTEM SHALL …` · State `WHILE … THE SYSTEM SHALL …` · Unwanted `IF … THEN THE SYSTEM SHALL …` · Optional `WHERE … THE SYSTEM SHALL …` · Precondition `GIVEN … WHEN … THEN …`.
- Number every acceptance criterion (restart per requirement) so each gets a stable `N.M` ID.
- Every EARS line must trace to the requirement's Story. No invented edge cases. Merge lines when possible.
- The Story is the anchor: a requirement that doesn't serve it → cut.

## Self-review
If enabled: no placeholders; every requirement has Priority + Story + ≥1 numbered EARS + Out-of-scope; nothing beyond the request; ≤3 markers. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "Add this related feature too" | Not requested → don't spec it. Put under Out of scope. |
| "Cover this rare edge case" | Only if it traces to the request. Else cut. |
| "They'll probably want config X" | Don't guess. Mark `[NEEDS CLARIFICATION]` (≤3). |
| "Skip the EARS numbers" | Numbering gives the `N.M` IDs that tasks trace to. Keep them. |
