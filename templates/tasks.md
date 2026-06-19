---
feature: <name>
status: draft
---
# Tasks: [FEATURE_NAME]

## Overview
[1 short paragraph: what this change spans — migrations, services, APIs, UI… + a bullet list.]

## Tasks

- [ ] 1. [Group title — e.g. "Database — migration"]
  - [ ] 1.1 [Concrete coding sub-task]   [P]
    - [detail bullet — exact `path/to/file`, what to add/change]
    - _Requirements: 1.1, 1.6_
  - [ ] 1.2 [Concrete coding sub-task]   (after 1.1)
    - [detail]
    - _Requirements: 2.3_

- [ ] 2. [Group title — e.g. "Backend — service"]
  - [ ] 2.1 [Sub-task]   [P]
    - [detail]
    - _Requirements: 3.1, 3.2_

- [ ] 3. [Group title — Tests]
  - [ ] 3.1 Write tests for [component]
    - [test cases to cover]
    - _Requirements: 1.1, 2.1_

## 4. Out of scope (capture only)   (optional terminal group)
- [excluded item — plain bullet, no checkbox]

<!-- Conventions (LOCKED):
  - Two-level decimal only: "- [ ] N" then "- [ ] N.M" (max 2 levels); detail = plain bullets.
  - Each sub-task N.M ends with its OWN _Requirements: a.b, c.d_ citing GRANULAR criterion IDs
    (1.1) — never whole requirements (1), never one shared line per group.
  - Order: schema → services → APIs → UI → integration → tests.
  - [P] = independent / parallel-safe; (after N.M) = dependency, ONLY when unavoidable.
    Never let two parallel tasks edit the same file.
  - States: [ ] todo, [x] done, [/] in-progress. Deviation/result notes in ">" blockquotes.
  - Coding tasks only (write/modify/test code). No deploy/UAT/metrics/training.

  Deviation-note example (add during execution when reality differs from the design):
  - [/] 2.1 Wire the dispatcher
    > Deviation: endpoint lives in a sibling spec, not built yet. Branch implemented;
    > call site is one line. Gated behind feature flag X.
    - _Requirements: 3.1_
-->
