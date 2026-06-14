---
inclusion: always
---
# [PROJECT_NAME] — Tech Stack
> Source of truth for libraries + where to get their docs.

## Stack
| Area | Library | Version | Context7 ID | Docs digest |
|---|---|---|---|---|
| framework | next.js | 15.x | /vercel/next.js | tech-docs/next.md |
| (no Context7) | foo | 2.1 | — | <official docs URL> |

## Docs policy
- Sources: pick set by `config.yml: docs_source`; fallback Context7 → ContextHub (bundled **spex-contexthub**) → WebSearch/WebFetch.
- In /spex:plan & /spex:implement: query by ID at the pinned version → distill ONLY what's used → save tech-docs/<lib>.md.
- Do NOT dump full docs. Keep digests focused on the APIs actually used.
- CORE libs distilled eagerly at init; the rest are lazy.
