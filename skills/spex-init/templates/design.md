---
feature: <name>
status: draft        # draft | approved
---
# Design: [FEATURE_NAME]

<!-- RULE: core sections live inline. Heavy detail (full schema, contracts, signatures, flow
diagrams, ADRs) is SUMMARIZED here in 2-3 lines and offloaded to details/<file>.md via a link.
The details/ file is the SINGLE source of truth — never duplicate its full content inline.
Link ONLY files that exist; omit sections that don't apply. -->

## Overview
[High-level technical approach + why. 1–3 paragraphs.]

### Technology Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [area]   | [choice] | [why]   |

### Out of scope
- [what this design explicitly does NOT touch]

## Architecture

### Components and Interfaces
<!-- One line per component: purpose + exact file path. Add (docs: tech-docs/<lib>.md) when the
component leans on a library, so the implementer knows which digest to open. Long signatures →
details/components.md. -->
- **[Component]** — `path/to/file` — [purpose]. (docs: `tech-docs/<lib>.md`)
- **[Component]** — `path/to/file` — [purpose].

## Data Model   (summary only; full schema → details/data-model.md)
- [entity — 1 line]. Full → `details/data-model.md`

## API / Contracts   (summary only; full → details/contracts.md)
- [METHOD /path — 1 line]. Full → `details/contracts.md`

## Request Flow   (summary only; full diagrams → details/flows.md)
1. [key happy-path step]
2. […]. Full (Mermaid, happy + error paths) → `details/flows.md`

## Error Handling
| Scenario | Error / Code | Response | Action |
|----------|-------------|----------|--------|
|          |             |          |        |

## Testing Strategy   (MANDATORY — do not defer entirely to tasks)
- **Unit**: …
- **Integration**: …
- **E2E / smoke**: …

## Docs used
- <lib> @version → `tech-docs/<lib>.md`  (Context7 /org/lib)

## Details   (the map — link every offloaded file that EXISTS; omit the rest)
- Data model → `details/data-model.md`
- Contracts / API → `details/contracts.md`
- Component signatures → `details/components.md`
- Request flow (Mermaid) → `details/flows.md`
- Key decisions / ADR → `details/decisions.md`
