---
feature: <name>
status: draft
---
# Tasks: [FEATURE_NAME]

- [ ] T1. <self-contained action>   _Req: R1_   [P]
  - [ ] T1.1 <sub-step>            # only when complex (max 2 levels)
- [ ] T2. <action>   _Req: R2_   (after T1)   # dependency only when unavoidable

- `[P]` = independent / parallel-safe. Default: maximize independence; never let two tasks edit the same file at once.
