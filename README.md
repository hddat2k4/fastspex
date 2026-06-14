# Fastspex
A lean, spec-driven development toolkit for Claude Code. Clear specs, no scope-creep.

## Install

### Any agent — Codex, Cursor, Gemini, Copilot… (recommended)

Cross-tool install via the open [`skills`](https://github.com/vercel-labs/skills) CLI (70+ agents). It reads this repo's `skills/` folder and lets you pick a target:

```bash
# All skills (auto-detects your agent)
npx skills add https://github.com/hddat2k4/fastspex

# A single skill
npx skills add https://github.com/hddat2k4/fastspex --skill spex-init

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

Copy `skills/spex-*` into your skills directory:
- Project: `.claude/skills/`
- Global:  `~/.claude/skills/`

## Use
1. `/spex:init` — set up `spex/` context (greenfield or brownfield).
2. `/spex:spec` — write a feature spec (approval required).
3. `/spex:plan` — technical plan (approval required).
4. `/spex:tasks` — break into an independent task checklist.
5. `/spex:implement` — build with TDD + scope-guard.
- `/spex:update` — edit context/config anytime.

## Principles
Story+EARS specs · per-requirement "Out of scope" · HARD-GATE at spec & plan · self-review (toggle in `spex/config.yml`) · docs via Context7→ContextHub→WebSearch · YAGNI everywhere.
