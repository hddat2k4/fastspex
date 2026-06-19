---
inclusion: always
---
# [PROJECT_NAME] — Structure
> The map so new code lands in the right place. Regenerate the tree from the real repo; don't hand-maintain.

## Folder Map
```
src/
  api/        # HTTP handlers, routes
  services/   # business logic
  db/         # schema, migrations, queries
tests/        # mirrors src/
config/       # env + app config
spex/         # Fastspex context (memory/) + feature specs (specs/)
```

## Naming Conventions
- [files / modules / components → the rule]

## Where to Put New Things
| What | Where | Naming |
|------|-------|--------|
| API endpoint | `src/api/...` |  |
| Service | `src/services/...` |  |
| Test | `<same-dir>` or `tests/` mirror |  |

## Import / Module Boundaries   (optional)
- [who can import from whom]

## Auto-Generated (do not edit)
- `node_modules/`, build output, generated migrations…
