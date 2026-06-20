---
title: Fastspex Hybrid Script Layer
date: 2026-06-20
status: approved-for-planning
---

# Fastspex — Optional Script Layer for Claude Code (Hybrid)

## Context

Fastspex is a spec-driven toolkit shipped as **pure-prompt Skills** (markdown), so it
runs on 70+ agents via `npx skills` with zero runtime — its core value prop. GitHub
**spec-kit** takes the opposite approach: shell scripts (`create-new-feature.sh`,
`check-prerequisites.sh`, `common.sh`, `setup-plan.sh`, `setup-tasks.sh`) do the
deterministic work (numbering, dir creation, prerequisite gating, path resolution) and
the LLM only writes content. spec-kit needs a Python CLI to bootstrap and maintains
bash **and** PowerShell variants.

Porting spec-kit's scripts wholesale would break Fastspex's portability. This design adds
an **optional** deterministic layer **for Claude Code only**, with every skill keeping its
existing prompt behavior as a fallback. Non-Claude agents (and shell-less environments)
behave exactly as they do today.

## Goals

1. Make the **deterministic** parts reliable on Claude Code: feature numbering, spec-dir
   scaffold, and hard prerequisite/gate checks (exit-code based).
2. Fix Fastspex's genuine weakness — **"which feature is active?"** — with a resolution
   rule shared by both the script path and the prompt fallback.
3. **Preserve portability**: identical skill content, gates, and output format. If the
   script layer is absent, skills run inline as today.

## Non-goals

- No Python/CLI bootstrap. `/spex:init` remains the bootstrap (it's a skill).
- No change to spec/design/tasks **content, format, or gate semantics**.
- No git dependency. Branch creation is opt-in (`--branch`), **off by default**.
- Not porting `setup-plan`/`setup-tasks` as separate scripts — `common` covers paths.

## Decisions (locked)

| # | Decision |
|---|---|
| H1 | Hybrid: pure-prompt default + **optional** script layer for Claude Code. |
| H2 | Scripts are **copied into the project by `/spex:init`** to `spex/scripts/`, not called from the ephemeral plugin cache. |
| H3 | Init finds the bundled scripts via **`${CLAUDE_SKILL_DIR}/scripts/`** (the documented, reliable per-skill var). Only `spex-init` touches this var. |
| H4 | Exactly **3 scripts** per platform: `common`, `new-feature`, `check` (bash + PowerShell = 6 files). |
| H5 | Feature numbering `NNN-slug` (e.g. `001-login`). Old `<slug>` dirs keep working. |
| H6 | Active feature resolved by a shared 4-step order; persisted in `spex/active-feature`. |
| H7 | `new-feature` does **not** create a git branch by default; `--branch` flag opts in. |
| H8 | Graceful degradation keyed on existence of `spex/scripts/` + a `scripts:` flag in `config.yml`. |
| H9 | `new-feature` writes only a **frontmatter stub**; the skill fills the body from the template (template stays single source of truth in the plugin). |

## Architecture

### Repo layout (authoring side)

```
fastspex/
  skills/
    spex-init/
      SKILL.md
      scripts/                      # bundled here so init can use ${CLAUDE_SKILL_DIR}/scripts
        bash/        common.sh  new-feature.sh  check.sh
        powershell/  common.ps1 new-feature.ps1 check.ps1
    spex-spec/SKILL.md              # + "Step 0 — Locate & gate"
    spex-design/SKILL.md            # + "Step 0 — Locate & gate"
    spex-tasks/SKILL.md             # + "Step 0 — Locate & gate"
    spex-implement/SKILL.md         # + "Step 0 — Locate & gate"
  templates/ …                      # unchanged
```

### Project layout (after `/spex:init` under Claude Code)

```
spex/
  config.yml            # + scripts: true|false
  active-feature        # one line: "001-login" (written by new-feature; manual fallback)
  scripts/              # copied from the plugin by init (Claude Code only)
    bash/  common.sh  new-feature.sh  check.sh
    powershell/  common.ps1 new-feature.ps1 check.ps1
  memory/ …
  specs/001-login/ …
```

On non-Claude installs, `spex/scripts/` never appears → skills fall back to prompt.

### Init: materialize the script layer

`/spex:init` gains one step (Claude Code + shell only):
copy `${CLAUDE_SKILL_DIR}/scripts/` → `spex/scripts/`, then set `scripts: true` in
`config.yml`. On other agents or without a shell, skip and set `scripts: false`.
This is the **only** place `${CLAUDE_SKILL_DIR}` is referenced.

### The three scripts (contracts)

**`common`** (sourced library; not run directly)
- `find_spex_root` — walk up for `spex/config.yml`; echo root or fail.
- `read_config <key>` — read a scalar from `config.yml` (grep/sed; no YAML dep).
- `resolve_feature` — apply the resolution order (below); echo `NNN-slug`.
- `feature_paths <feature>` — echo `FEATURE_DIR`, `SPEC`, `DESIGN`, `TASKS`.
- `frontmatter_status <file>` — echo the `status:` value from a file's frontmatter.

**`new-feature`** — used by `/spex:spec`
- Usage: `new-feature [--json] [--branch] <slug-or-description>`
- Compute next number = max existing `spex/specs/NNN-*` + 1, zero-padded to 3.
- Slugify (lowercase, spaces→`-`, strip non-alnum, trim, cap word count).
- `mkdir -p spex/specs/NNN-slug/`; write `spec.md` **frontmatter stub** only
  (`feature: NNN-slug`, `status: draft`).
- Write `spex/active-feature` = `NNN-slug`.
- `--branch` → also `git checkout -b NNN-slug` (off by default).
- Output (JSON or text): `feature`, `feature_dir`, `spec_file`.

**`check`** — used at the top of `/spex:design`, `/spex:tasks`, `/spex:implement`
- Usage: `check [--json] --phase <design|tasks|implement>`
- Resolve active feature.
- Gate (prior artifact must exist with `status: approved`):
  - `design`  → requires `spec.md` approved
  - `tasks`   → requires `design.md` approved
  - `implement` → requires `tasks.md` approved
- List available docs (`details/*`, `tech-docs/*`).
- Output JSON `{ feature, feature_dir, phase, ok, blocking, available_docs }`.
- **Exit non-zero** when the gate fails (hard gate).

> `check` is the **entry** gate (prior phase approved). Each skill still runs its own
> **exit** gate (`AskUserQuestion`) at the end. Two-sided, same as today.

### Active-feature resolution order (shared by script + prompt fallback)

1. `spex/active-feature` file, if the named dir exists.
2. git branch matching `NNN-*`, if git present and the dir exists.
3. Exactly one dir under `spex/specs/*` → use it.
4. Newest by mtime; if still ambiguous → ask the user.

### Skill change — "Step 0 — Locate & gate" (spec/design/tasks/implement)

Inserted at the top of each skill's Flow:

> **Step 0 — Locate feature & gate.** If `spex/scripts/` exists and a shell is available,
> run the helper for this OS (`bash spex/scripts/bash/check.sh --phase <phase> --json`, or
> `pwsh spex/scripts/powershell/check.ps1 ...` on Windows) and use its JSON. Otherwise do
> it inline: resolve the active feature via the resolution order, and confirm the prior
> artifact is `status: approved`.

- `spex-spec` "Save" step: prefer `new-feature` to scaffold the numbered dir; else create
  `spex/specs/<NNN-slug>/` inline using the same numbering rule.
- All existing gate/content/format text is unchanged.

### config.yml

Add `scripts: true|false`. Active feature lives in `spex/active-feature` (not config), so
bash never edits YAML.

## Backward compatibility & migration

- Existing `<slug>` (un-numbered) spec dirs resolve via rules 3–4; numbering applies to new
  features only. No rename, no break.
- A project initialized before this change has no `spex/scripts/` and no `scripts:` key →
  treated as `scripts: false` → pure prompt. Re-running init can add the layer.

## Trade-offs

- **Double maintenance** (bash + PowerShell) for 3 scripts. Mitigation: keep scripts tiny
  and behavior-equivalent; the prompt fallback is the spec they must match.
- Slightly more surface area in `spex/`. Mitigation: all optional and self-contained.

## Implementation outline (for the plan)

1. Write the 6 scripts (`common`, `new-feature`, `check` × bash/pwsh) with the contracts above.
2. Update `spex-init`: add the copy-scripts step + `scripts:` flag + active-feature note.
3. Add "Step 0" to `spex-spec`, `spex-design`, `spex-tasks`, `spex-implement`; wire
   `spex-spec` Save to `new-feature`.
4. Update `config.yml` template/handling for `scripts:`.
5. Refresh `IMPLEMENTATION_PLAN.md` (stale: still says `plan.md`/`project.md`/`spex-update`)
   and add a short "Optional script layer" note to `README.md` + `CLAUDE.md`.
6. Verify: Claude Code full loop (scripts used) **and** simulated no-script loop (fallback).

## Open questions

None blocking. (Optionally, a later enhancement: init copies `templates/` → `spex/templates/`
so `new-feature` can use a project-editable template instead of a frontmatter stub.)
