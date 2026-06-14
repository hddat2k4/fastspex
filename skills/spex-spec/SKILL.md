---
name: spex-spec
description: Write a clear, lean feature spec (Story + EARS + Out of scope) before planning. Drafts requirements, marks ambiguities, then requires approval before /spex:plan.
---
# Fastspex: Spec

## Overview
Turn one feature request into a testable WHAT/WHY spec. **Core principle: every requirement traces to the request; cut everything else.**

## When to use
- After /spex:init, to define a single feature/change. One spec = one feature.

## Flow
1. **Frame** the feature as a single change. Right-size: tiny/clear → a short spec.
2. **Draft requirements** in the spec.md template: number them R1, R2…; each = priority (Must/Should/Could) + Story + EARS acceptance + `Out of scope:`.
3. **Brownfield**: if touching an existing capability, write a DELTA (`## ADDED / ## MODIFIED / ## REMOVED Requirements`); MODIFIED copies the FULL requirement.
4. **Mark ambiguity** inline with `[NEEDS CLARIFICATION: …]` — **max 3**, prioritized by impact. Do not start a Q&A; draft first, let the user comment.
5. **Save** `spex/specs/<feature>/spec.md` (status: draft).
6. **HARD-GATE.**

## Notation rules
- EARS: `WHEN <condition> THE SYSTEM SHALL <behavior>` / `IF <precondition> THEN THE SYSTEM SHALL <response>`.
- Every EARS line must trace to the requirement's Story. No invented edge cases. Merge lines when possible.
- `Why` is the anchor: a requirement that doesn't serve `Why` → cut.

## Self-review
If enabled: no placeholders; every requirement has Story + ≥1 EARS + Out-of-scope; nothing beyond the request; ≤3 markers. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "Add this related feature too" | Not requested → don't spec it. Put under Out of scope. |
| "Cover this rare edge case" | Only if it traces to the request. Else cut. |
| "They'll probably want config X" | Don't guess. Mark `[NEEDS CLARIFICATION]` (≤3). |

<HARD-GATE>
Do NOT proceed to /spex:plan until the user approves. On approval set status: approved.
</HARD-GATE>
