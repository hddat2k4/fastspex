# Fastspex
A lean, spec-driven development toolkit for Claude Code. Clear specs, no scope-creep.

## Install

### As a Claude Code plugin (recommended)

```bash
claude plugin install https://github.com/YOUR_USERNAME/fastspex
```

Or clone and install locally:

```bash
git clone https://github.com/YOUR_USERNAME/fastspex /tmp/fastspex
claude plugin install /tmp/fastspex
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
