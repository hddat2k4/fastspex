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
6. **HARD-GATE via AskUserQuestion.** Present the spec for approval or targeted clarification:
   - If there are no `[NEEDS CLARIFICATION]` markers:
     ```json
     {
       "questions": [
         {
           "question": "Approve this spec and proceed to /spex:plan?",
           "header": "Spec approval",
           "multiSelect": false,
           "options": [
             { "label": "Approve", "description": "Set status: approved and continue" },
             { "label": "Request changes", "description": "Describe what to change, then revise" },
             { "label": "Reject and stop", "description": "Keep as draft, do not plan" }
           ]
         }
       ]
     }
     ```
   - If there ARE clarification markers, expand the question to surface them:
     ```json
     {
       "questions": [
         {
           "question": "This spec has {N} open clarification(s). What would you like to do?",
           "header": "Spec approval",
           "multiSelect": false,
           "options": [
             { "label": "Answer clarifications now", "description": "I'll ask each [NEEDS CLARIFICATION] one by one" },
             { "label": "Approve anyway", "description": "Accept assumptions and proceed to /spex:plan" },
             { "label": "Request changes", "description": "Describe broader changes, then revise" }
           ]
         }
       ]
     }
     ```
     If the user chooses "Answer clarifications now", use `AskUserQuestion` for each marker with a free-text option or the relevant choices. Apply answers, remove resolved markers, re-save, then re-present the gate.
   - On **Approve**: set spec.md status to `approved` and stop. The next command is `/spex:plan`.
   - On **Request changes**: collect the feedback, edit the spec, re-save as draft, then re-run the gate.
   - On **Reject**: keep status as `draft` and stop.

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
