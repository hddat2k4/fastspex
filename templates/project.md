---
inclusion: always
---
# [PROJECT_NAME] — Project Overview
> Keep it SHORT. This is the map, not the territory.

## Purpose
[1–2 sentences: what this is, why it exists, who it's for.]

## Scope
- In scope: [what this project DOES]
- Out of scope: [what it deliberately does NOT do]

## Key Features
- [feature → one line]

## Structure   (annotated tree — regenerate from the real tree; don't hand-maintain)
```
src/
  api/        # HTTP handlers, routes
  services/   # business logic
  db/         # schema, migrations, queries
tests/        # mirrors src/
config/       # env + app config
```
- Naming: [files / modules / components]
- Placement rule: "a new <X> goes in <Y>"
