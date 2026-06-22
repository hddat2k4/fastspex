# Fastspex
A lean, spec-driven development toolkit for Claude Code. Clear specs, no scope-creep.

## Install

### Any agent — Codex, Cursor, Gemini, Copilot… (recommended)

Cross-tool install via the open [`skills`](https://github.com/vercel-labs/skills) CLI (70+ agents). It reads this repo's `skills/` folder and lets you pick a target:

```bash
# All skills (auto-detects your agent)
npx skills add https://github.com/hddat2k4/fastspex

# A single skill
npx skills add https://github.com/hddat2k4/fastspex --skill init

# Pick a specific agent and install globally
npx skills add https://github.com/hddat2k4/fastspex --agent codex --global
```

### Claude Code (plugin)

```bash
# 1. Add this repo as a marketplace
claude plugin marketplace add hddat2k4/fastspex

# 2. Install the plugin from it
claude plugin install fastspex@fastspex
```

Or inside a Claude Code session:

```
/plugin marketplace add hddat2k4/fastspex
/plugin install fastspex@fastspex
```

### Manual install

Copy the skill folders (`init`, `spec`, `design`, `tasks`, `implement`) into your skills directory:
- Project: `.claude/skills/`
- Global:  `~/.claude/skills/`

## Use
1. `/init` — set up `spex/` context (greenfield or brownfield). Also copies the artifact
   templates into `spex/templates/` (and, on Claude Code, the helper scripts into `spex/scripts/`)
   so every later step reads one project-local, editable source.
2. `/spec` — write a feature spec (approval required).
3. `/design` — technical design; core inline, heavy detail in `details/` (approval required).
4. `/tasks` — break into a granular, traceable task checklist (approval required).
5. `/implement` — build with TDD + scope-guard.

To change context after init, edit the files in `spex/memory/` directly. To tweak an artifact
template for a project, edit it in `spex/templates/`.

### What `/init` writes into your project
```
spex/
  config.yml            # fastspex:1 · mode · self_review · templates · scripts · docs_source
  memory/               # product.md · tech.md · structure.md · constitution.md (+ tech-docs/)
  templates/            # spec.md · design.md · tasks.md · product/tech/structure/constitution
  scripts/              # bash/ (+ powershell/) — Claude Code only; optional, skills fall back
  specs/                # one folder per feature (NNN-slug)
```

### Optional script layer (Claude Code)
On Claude Code, `/init` copies tiny helper scripts to `spex/scripts/` (bash + PowerShell)
that make feature numbering and the spec→design→tasks→implement **gates deterministic**
(exit-code `check`). Each step also ends with a `→ Next:` handoff so the workflow
is self-routing. On any other agent the scripts are simply absent and every command runs the
same logic inline — no behavior change, no runtime required.

## Principles
Story + numbered EARS specs · per-requirement "Out of scope" · HARD-GATE at spec, design & tasks · granular requirement tracing · self-review (toggle in `spex/config.yml`) · docs via Context7→WebSearch · YAGNI everywhere.
