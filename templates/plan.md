---
feature: <name>
status: draft        # draft | approved
---
# Plan: [FEATURE_NAME]

## Approach
[1 short paragraph: technical approach & why. Complex architecture → details/architecture.md (Mermaid).]

## Changes
- Create: <path> — <purpose>
- Modify: <path> — <what & why>
- Delete: <path> — <why>

## Error handling
- [error case → response; tied to the IF/THEN lines in the spec]

## Testing
- [test levels + key cases, each tied to a requirement]

## Docs used
- <lib> → tech-docs/<lib>.md  (Context7 /org/lib @version)

## Details   (only link files that exist; omit otherwise)
- Architecture (Mermaid) → details/architecture.md
- Data model → details/data-model.md
- Contracts  → details/contracts.md
- Key decisions → details/decisions.md
