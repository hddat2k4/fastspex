# Fastspex — Implementation Plan (self-contained)

> ⚠️ **SUPERSEDED (v1 historical record).** This is the original build plan and no longer
> matches the shipped toolkit. The current toolkit is **`init · spec · design · tasks ·
> implement`** (no `plan`, no `update`); memory files are **`product.md · tech.md ·
> structure.md · constitution.md`** (not `project.md`); artifacts are **`spec.md · design.md ·
> tasks.md`** (not `plan.md`); plus an optional **`spex/scripts/` gate layer** on Claude Code.
> For the authoritative current behavior see `README.md`, `CLAUDE.md`, each `skills/spex-*/SKILL.md`,
> and the design doc `docs/designs/2026-06-20-hybrid-script-layer-design.md`. Kept for history only.
>
> Bộ công cụ **spec-driven development** dạng **skill Claude Code**. Ưu tiên #1: **spec rõ ràng, KHÔNG phình** (no scope-creep / no gold-plating).
> File này đủ để implement mà không cần đọc lại chat. Artifacts viết **tiếng Anh** (D8); ghi chú hướng dẫn tiếng Việt.
> Ngày: 2026-06-14. Namespace lệnh: `/spex:*`.

---

## 0. Cách dùng plan này

Build theo thứ tự **Phase 0 → 5** (mục 6). Mỗi skill/template đã có **full nội dung** ở mục 5 — phần lớn là copy vào đúng path. Khi viết, bám **quy ước chung** (mục 3) và **tham khảo prompt SDD khác** (mục 7) để chắt lọc, KHÔNG copy nguyên.

Phạm vi: **A-core** = `init · spec · plan · tasks · implement` + support `update`. Bản B (để sau): `clarify`, `verify`, `scope-check` thành bước/agent riêng.

---

## 1. Quyết định thiết kế (D1–D13)

| # | Quyết định |
|---|---|
| D1 | Hình thức = **bộ skill Claude Code** (markdown + slash command, KHÔNG CLI/thư viện). "Cài" = copy file. |
| D2 | Gate **lai**: HARD-GATE chỉ ở **spec & plan**; `init`/`tasks`/`implement` không gate; **right-size** việc nhỏ. |
| D3 | Notation = **Story + EARS + "Out of scope"** mỗi requirement. EARS không map story → cắt; không bịa edge case. |
| D4 | 3 context file: `project.md` (overview **+ structure**) · `tech.md` (stack + docs) · `constitution.md` (rules). Có **inclusion mode**. |
| D5 | Docs: **Context7 → ContextHub → WebSearch/WebFetch**; lưu **digest chắt lọc**; **eager distill CORE libs** lúc init, lazy phần còn lại. |
| D6 | Build **A-core** trước; chừa chỗ cho bản B. |
| D7 | Tên **Fastspex**; lệnh `/spex:*`; skill `spex-*`; thư mục artifact `spex/`. |
| D8 | File **tiếng Anh**, chat tiếng Việt. |
| D9 | `init` **không gate** → kết bằng **brief & handoff**; sửa context qua lệnh riêng **`/spex:update`**. |
| D10 | `plan` thêm **Error handling + Mermaid (trong details/) + Constitution Check**; bỏ `quickstart` (YAGNI). |
| D11 | **self-review nhẹ ở MỌI skill**; **toggle** qua `spex/config.yml → self_review: true|false`. |
| D12 | `tasks`: granularity **lai** (coarse + sub-task 2 cấp); **viết độc lập nhất có thể** + `[P]`; gắn `_Req: Rx_`. |
| D13 | `implement`: **sequential mặc định + option song song `[P]`** (sub-agent); **scope-guard**; **verify test** trước khi báo done. |

---

## 2. File layout

```
# Nơi AUTHOR bộ công cụ (repo này)
E:\PersonalProject\spec_driven\fastspex\
  IMPLEMENTATION_PLAN.md        # file này
  README.md                     # cách cài + dùng
  skills/
    spex-init/SKILL.md
    spex-spec/SKILL.md
    spex-plan/SKILL.md
    spex-tasks/SKILL.md
    spex-implement/SKILL.md
    spex-update/SKILL.md
  templates/
    project.md  tech.md  constitution.md
    spec.md  plan.md  tasks.md

# "Cài" = copy skills/* vào .claude/skills/ (project) hoặc ~/.claude/skills/ (global)

# Tài liệu sống do /spex:init sinh trong project NGƯỜI DÙNG
spex/
  config.yml                    # fastspex:1 · mode · created · toggles
  memory/
    project.md  tech.md  constitution.md
    tech-docs/<lib>.md          # digest docs chắt lọc
  specs/<feature>/
    spec.md  plan.md  tasks.md
    details/                    # tùy chọn: architecture.md, data-model.md, contracts.md, decisions.md
```

---

## 3. Quy ước chung (áp cho mọi SKILL.md)

**Anatomy 1 SKILL.md** (học Superpowers):
1. Frontmatter `name` + `description` (description quyết định trigger — viết rõ "Use when…").
2. `## Overview` + 1 câu **core principle**.
3. `## When to use` (điều kiện áp dụng / không).
4. `## Flow` (các bước đánh số).
5. `## Self-review` (đọc `spex/config.yml`; nếu `self_review: false` → skip).
6. `## Red flags` (bảng "Thought → Reality" chống bào chữa).
7. `<HARD-GATE>` nếu có (chỉ spec & plan).

**Anti-bloat kit** (gắn xuyên suốt — ưu tiên #1):
- Out-of-scope mỗi requirement · Scope Discipline (constitution) · scope-check (plan) · scope-guard (implement).
- Red-flag table mọi skill · HARD-GATE ở spec/plan · YAGNI · `[NEEDS CLARIFICATION]` ≤3 · digest docs chắt lọc.

**Self-review nhẹ (D11)** — checklist tự soi inline trước gate/handoff:
- Có placeholder/TBD/TODO? → điền hoặc bỏ.
- Mọi requirement/spec được phủ chưa? Có gì **thừa ngoài spec** không? → cắt.
- Nhất quán tên/kiểu giữa các phần?
→ Sửa tại chỗ, không cần re-review.

**Docs sources (D5)** — fallback: `Context7 (resolve-library-id → query-docs)` → `ContextHub` → `WebSearch/WebFetch`. Distill **chỉ phần API thực dùng** → `spex/memory/tech-docs/<lib>.md`. KHÔNG dump full docs.

**Inclusion mode (frontmatter context file)**: `always` (luôn nạp) · `fileMatch` (theo glob) · `manual` (`#tên`). 3 file memory mặc định `always`; `tech-docs/*` nên `manual`.

**Right-size (D2)**: việc nhỏ/rõ → rút gọn (spec gọn, ít task), KHÔNG bắt buộc đủ nghi thức. "Phẫu thuật bằng dao mổ, không dùng xe nâng."

---

## 4. `spex/config.yml` (do init sinh)

```yaml
fastspex: 1
mode: brownfield        # greenfield | brownfield
created: 2026-06-14     # ngày init
self_review: true       # bật/tắt self-review ở mọi skill
```
Mọi skill đọc file này. Mở rộng toggle sau (vd `right_size`, `gate_strictness`).

---

## 5. NỘI DUNG ĐẦY ĐỦ TỪNG FILE

> Các block dưới dùng 4 dấu ` để bọc (vì nội dung có code fence bên trong). Khi tạo file, lấy phần BÊN TRONG block.

### 5.1 `templates/constitution.md`

````markdown
---
inclusion: always
---
# [PROJECT_NAME] — Constitution
> Non-negotiable principles. Keep it SHORT: record only what is truly binding.
> On violation → stop and ask the human.

## Core Principles   (2–5 only; do NOT pad to fill)
### 1. [Name]
[Imperative, verifiable rule.] — Because: [one-line rationale].

## Coding Constraints
- [required style/lint · banned/required patterns · error-handling rule]

## Testing Policy
- [minimum bar · when tests-first is mandatory]

## ⛔ Scope Discipline   (fixed — Fastspex signature; do not remove)
- Build ONLY what the spec asks. NO extra functions/options/abstractions/edge-cases beyond the spec.
- "Might need it later" → DON'T build it (YAGNI). Push it to "Out of scope" instead of coding it.

## Governance
- Editing the constitution = bump version + record the reason.
**Version**: 1.0.0 | **Ratified**: [DATE] | **Last Amended**: [DATE]
````

### 5.2 `templates/project.md`

````markdown
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
````

### 5.3 `templates/tech.md`

````markdown
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
- Sources (fallback): Context7 → ContextHub → WebSearch/WebFetch.
- In /spex:plan & /spex:implement: query by ID at the pinned version → distill ONLY what's used → save tech-docs/<lib>.md.
- Do NOT dump full docs. Keep digests focused on the APIs actually used.
- CORE libs distilled eagerly at init; the rest are lazy.
````

### 5.4 `templates/spec.md`

````markdown
---
feature: <name>
status: draft        # draft | approved
---
# Spec: [FEATURE_NAME]

## Why
[1–2 sentences: problem & why now.]

## What changes
- [behavior/capability ADDED · MODIFIED · REMOVED — high level, NOT code]
- Mark **BREAKING** if it changes existing behavior.

## Requirements
### R1. [Name] — [Must|Should|Could]
As a <role>, I want <goal>, so that <value>.
- WHEN <condition> THE SYSTEM SHALL <behavior>.
- IF <error precondition> THEN THE SYSTEM SHALL <response>.
Out of scope: <what R1 does NOT cover; "—" if none>.

## Non-goals   (optional — only if there's a meaningful overall boundary)
- [explicitly NOT building]
```` 

Brownfield delta (thay mục Requirements khi đụng capability có sẵn): dùng `## ADDED / ## MODIFIED / ## REMOVED Requirements`; **MODIFIED chép FULL nội dung requirement** (tránh mất chi tiết khi merge).

### 5.5 `templates/plan.md`

````markdown
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
````

### 5.6 `templates/tasks.md`

````markdown
---
feature: <name>
status: draft
---
# Tasks: [FEATURE_NAME]

- [ ] T1. <self-contained action>   _Req: R1_   [P]
  - [ ] T1.1 <sub-step>            # only when complex (max 2 levels)
- [ ] T2. <action>   _Req: R2_   (after T1)   # dependency only when unavoidable
```
- `[P]` = independent / parallel-safe. Default: maximize independence; never let two tasks edit the same file at once.
````

### 5.7 `skills/spex-init/SKILL.md`

````markdown
---
name: spex-init
description: Initialize Fastspex in a project (greenfield or brownfield). Scaffolds spex/ and generates project.md, tech.md, constitution.md. Run once before /spex:spec.
---
# Fastspex: Init

## Overview
Set up the persistent context a spec-driven workflow needs. **Core principle: capture only what's binding; keep every file lean.**

## When to use
- Starting Fastspex in a repo. NOT for editing context later — use spex-update for that.

## Flow
1. **Detect mode.** Code/manifests/.git present → brownfield; empty → greenfield. Confirm with the user (1 question).
2. **Scaffold (do not clobber).** If `spex/` exists → stop and offer update / re-init / abort. Else create:
   `spex/memory/`, `spex/memory/tech-docs/`, `spex/specs/`, and `spex/config.yml` (fastspex:1, mode, created, self_review: true).
3. **Generate project.md** (template). greenfield: ask ≤5 questions (purpose+who · 3–5 MVP features · out of scope) → propose an annotated tree from the stack. brownfield: shallow `tree` (depth 2, ignore node_modules/.git/dist) → annotated tree + naming + README → present "inferred from …" → confirm.
4. **Generate tech.md** (template). greenfield: ask intended stack → resolve-library-id per lib → store ID+version. brownfield: parse manifests (package.json/requirements.txt/go.mod/pom.xml…) → resolve IDs. Then **eager-distill CORE libs** (ask the user to confirm the short "core" set) → tech-docs/. Non-core stay pointers (lazy).
5. **Generate constitution.md** (template). greenfield: ask ≤5 questions (language/style, test policy, non-negotiables) → 2–5 principles, each name + verifiable rule + one-line rationale. brownfield: infer from lint config/CI/CONTRIBUTING/README → present with sources → confirm. ALWAYS keep the "Scope Discipline" section verbatim.
6. **Brief & handoff (NO gate).** Print 2–3 bullets per file (what was captured), then:
   "Review here: `spex/memory/`. To change anything: `/spex:update`. When ready: `/spex:spec`." Do not block.

## Self-review
If `spex/config.yml → self_review: true`: check no placeholders left; principles ≤5 and truly binding; project/tech reflect reality; nothing padded. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "spex/ exists, just overwrite" | Never clobber. Offer update / re-init / abort. |
| "Add a principle just in case" | A bloated constitution is useless. Only what's binding. |
| "Design an elaborate folder structure" | Reflect/propose only what's needed. |
| "Pre-download all docs now" | Only eager-distill CORE libs; the rest are pointers. |
| "They probably want strict mode" | Don't guess. Ask, or infer from real config. |
````

### 5.8 `skills/spex-spec/SKILL.md`

````markdown
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
````

### 5.9 `skills/spex-plan/SKILL.md`

````markdown
---
name: spex-plan
description: Turn an approved spec into a lean technical plan (HOW) with optional detail files; pulls docs via Context7/ContextHub/WebSearch; requires approval before /spex:tasks.
---
# Fastspex: Plan

## Overview
Decide HOW to build the approved spec — lean overview, depth in linked detail files. **Core principle: the plan never exceeds the spec.**

## When to use
- After a spec is `approved`. If spec.md status ≠ approved → stop.

## Flow
1. **Read** spec.md + memory/ (project, tech, constitution).
2. **Distill docs** for libs this feature touches (lazy): ensure tech-docs/ exists; if missing → Context7 → ContextHub → WebSearch → save digest.
3. **Draft plan.md** (template, 2-tier): Approach · Changes (create/modify/delete) · Error handling · Testing · Docs used · Details(links). Heavy topics (data model, contracts, decisions, architecture+Mermaid) → `details/<file>.md`, linked only. Create a detail file ONLY when it would bloat plan.md.
4. **Scope-check + Constitution Check**: the plan adds nothing beyond the spec and violates no constitution rule. Flag and ask on conflict.
5. **Save** plan.md (status: draft).
6. **HARD-GATE.**

## Self-review
If enabled: every requirement is addressed by some change; no placeholders; no design beyond spec; detail links resolve. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "Add an abstraction for flexibility" | Not unless the spec needs it. YAGNI. |
| "Refactor this while I'm here" | Out of spec → note it and ask, don't do it. |
| "Put all the docs in the plan" | Digest only what's used; link details/. |

<HARD-GATE>
Do NOT proceed to /spex:tasks until the user approves. On approval set status: approved.
</HARD-GATE>
````

### 5.10 `skills/spex-tasks/SKILL.md`

````markdown
---
name: spex-tasks
description: Break an approved plan into an independent, traceable task checklist (tasks.md). No approval gate.
---
# Fastspex: Tasks

## Overview
Decompose the plan into a checklist. **Core principle: tasks are independent and each traces to a requirement.**

## When to use
- After plan.md is `approved`.

## Flow
1. **Read** spec + plan (+ details/).
2. **Decompose** into ordered tasks in tasks.md; each tagged `_Req: Rx_` and tied to a plan "Change".
3. **Granularity (hybrid):** default coarse (1 task = 1 logical unit, ~≤30 min, TDD implied); split into 2-level sub-tasks (T1.1) only when complex.
4. **Independence:** make each task self-contained; never let two tasks edit the same file; group files-that-change-together. Mark `[P]` for parallel-safe tasks; add a dependency ("after T1") only when unavoidable.
5. **TDD** per constitution test policy. Right-size for small features.
6. **Save** tasks.md (status: draft) → ready for /spex:implement.

## Self-review
If enabled: every requirement maps to ≥1 task; no orphan task beyond spec/plan; dependencies minimal and correct. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "One giant task is simpler" | Split by responsibility so tasks stay independent. |
| "Add a task to clean things up" | Not in the plan → don't. |
| "These two tasks can share edits to file X" | Merge them or sequence them — never parallel-edit one file. |
````

### 5.11 `skills/spex-implement/SKILL.md`

````markdown
---
name: spex-implement
description: Execute tasks.md — TDD per task, scope-guard, tick [x]. Sequential by default with an option to run independent [P] tasks in parallel. Verify tests before claiming done.
---
# Fastspex: Implement

## Overview
Build exactly what the tasks say. **Core principle (scope-guard): code only what the task/requirement asks — nothing extra.**

## When to use
- After tasks.md exists.

## Flow
1. **Read** spec + plan + tasks + memory (constitution, tech-docs/).
2. **Execute tasks** in order, respecting dependencies. Default sequential. If the user opts in, run `[P]` (independent) tasks in parallel via sub-agents.
3. **Per task (TDD):** write the failing test → run it (see it fail) → minimal implementation → run tests (pass) → tick `[x]`.
4. **Scope-guard:** implement only the task/`_Req:`. No "while I'm here" refactors, no extra options.
5. **Docs:** use tech-docs/; if a needed digest is missing → Context7 → ContextHub → WebSearch → save.
6. **Self-review + verify:** if enabled, confirm code matches task/spec with nothing extra; then RUN the tests and read output before claiming anything passes.
7. Feature done when all tasks are `[x]`.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "Refactor this to be cleaner" | Out of task. Don't. |
| "Add an option just in case" | YAGNI. Build the task only. |
| "This task is like the other, do it too" | Follow tasks.md exactly. |
| "Tests probably pass" | No completion claims without fresh test output. |
````

### 5.12 `skills/spex-update/SKILL.md`

````markdown
---
name: spex-update
description: Update Fastspex knowledge/config — edit project, tech, constitution, docs digests, or config toggles. Re-distills docs and bumps constitution version as needed.
---
# Fastspex: Update

## Overview
Maintain the living context. **Core principle: edits keep files lean — apply the same anti-bloat rules.**

## When to use
- `/spex:update [project|tech|constitution|docs|config]` to change context after init.

## Flow
1. **Load** the target file(s).
2. **project / constitution:** apply the change; keep ≤ the existing discipline (no padding). constitution → bump **Version** + record the reason in Governance.
3. **tech:** add/remove libs → re-resolve IDs; for affected libs re-distill digests (Context7 → ContextHub → WebSearch) → tech-docs/.
4. **docs:** refresh a specific tech-docs/<lib>.md digest (keep it focused on used APIs).
5. **config:** flip toggles in `spex/config.yml` (e.g., `self_review: false`).
6. **Brief** what changed + where. No gate.

## Self-review
If enabled: change is minimal and consistent; no placeholders; constitution version bumped if edited. Fix inline.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "Rewrite the whole file" | Apply the smallest change that satisfies the request. |
| "Add more rules while editing" | Only what was asked. |
| "Skip the version bump" | Constitution edits always bump version + reason. |
````

### 5.13 `README.md`

````markdown
# Fastspex
A lean, spec-driven development toolkit for Claude Code. Clear specs, no scope-creep.

## Install
Copy `skills/spex-*` into your skills directory:
- Project: `.claude/skills/`
- Global:  `~/.claude/skills/`
(Or package as a Claude Code plugin with `plugin.json` — optional.)

## Use
1. `/spex:init` — set up `spex/` context (greenfield or brownfield).
2. `/spex:spec` — write a feature spec (approval required).
3. `/spex:plan` — technical plan (approval required).
4. `/spex:tasks` — break into an independent task checklist.
5. `/spex:implement` — build with TDD + scope-guard.
- `/spex:update` — edit context/config anytime.

## Principles
Story+EARS specs · per-requirement "Out of scope" · HARD-GATE at spec & plan · self-review (toggle in `spex/config.yml`) · docs via Context7→ContextHub→WebSearch · YAGNI everywhere.
````

---

## 6. Build phases (thứ tự)

- **Phase 0 — Collect references.** Copy ~29 Superpowers prompt files vào `sdd-research/collected/superpowers/<skill>/` (nguồn: `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.1.0/skills/`). Dùng làm tham khảo + tư liệu.
- **Phase 1 — Init + Update + templates.** Tạo `templates/*` (mục 5.1–5.6) → `skills/spex-init` (5.7) → `skills/spex-update` (5.12).
- **Phase 2 — Spec.** `skills/spex-spec` (5.8).
- **Phase 3 — Plan.** `skills/spex-plan` (5.9).
- **Phase 4 — Tasks + Implement.** `skills/spex-tasks` (5.10) + `skills/spex-implement` (5.11).
- **Phase 5 — Glue + README.** `README.md` (5.13); tinh chỉnh `description` từng skill cho trigger chuẩn; (tùy chọn) đóng plugin `plugin.json` + SessionStart hook như Superpowers.

> Khi viết mỗi SKILL.md, có thể gọi `superpowers:writing-skills`. **Tham khảo prompt SDD khác rồi chắt lọc** (mục 7) — học cấu trúc/cơ chế, KHÔNG copy nguyên; giữ lean + tiếng Anh.

---

## 7. Prompt tham khảo (đọc rồi chắt lọc)

- **Spec Kit** `templates/commands/{specify,plan,tasks,implement,clarify,analyze,constitution}.md` + `templates/{spec,plan,tasks,constitution}-template.md` — https://github.com/github/spec-kit
- **Kiro** spec-process-guide (mirror): requirements/design/tasks phase; steering docs — https://kiro.dev/docs/ · https://github.com/jasonkneen/kiro
- **OpenSpec** `schemas/spec-driven/schema.yaml` + templates (delta ADDED/MODIFIED/REMOVED) — https://github.com/Fission-AI/OpenSpec
- **Superpowers** `writing-plans`, `subagent-driven-development`, `test-driven-development`, `verification-before-completion` — local plugin cache (đã collect ở Phase 0).
- Tổng hợp đối chiếu: `sdd-research/spec-driven-comparison.md`.

---

## 8. Verification (sau khi build)

1. **init greenfield:** chạy trên thư mục trống → `spex/memory/{project,tech,constitution}.md` + `config.yml` sinh đúng, có frontmatter inclusion; kết thúc bằng brief & handoff (không gate).
2. **init brownfield:** chạy trên 1 repo nhỏ có sẵn → tech.md detect đúng stack + resolve Context7 ID; project.md có annotated tree từ cây thật; constitution suy từ lint/CI.
3. **Full loop 1 feature nhỏ:** spec (Story/EARS/Out-of-scope, ≤3 markers) → ★gate → plan (lean + details nếu cần) → ★gate → tasks (`_Req:` + `[P]`) → implement (TDD, tick `[x]`, verify test). Xác nhận **2 HARD-GATE đều dừng** và **KHÔNG phát sinh function/edge-case ngoài spec**.
4. **Docs:** digest lưu vào `tech-docs/<lib>.md`, không nhồi nguyên docs; fallback chain hoạt động.
5. **Toggle:** đặt `self_review: false` → các skill bỏ qua self-review.
6. **Skill load:** mỗi `SKILL.md` có `name`/`description` hợp lệ, nạp được qua Skill tool; `description` trigger đúng ngữ cảnh.

## 9. Việc chốt sau (không chặn build)
- Đóng thành Claude Code plugin (`plugin.json` + SessionStart auto-inject) hay để skill thủ công.
- Vị trí cài: project `.claude/skills/` hay global `~/.claude/skills/`.
- Bản B: `/spex:clarify` (≤5 câu trước draft) · `/spex:verify` (đối chiếu code↔spec cuối) · scope-check thành bước/agent riêng.
