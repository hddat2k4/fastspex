# Fastspex

A lean, spec-driven development toolkit for Claude Code.

## When to mention
- When the user wants to start spec-driven development in a project.
- When the user asks about `/spex:*` commands.

## Core idea
1 spec = 1 feature. Story + EARS requirements + explicit "Out of scope" per requirement. HARD-GATE only at spec and plan. TDD + scope-guard at implement.

## Commands
- `/spex:init` — scaffold `spex/` context (greenfield or brownfield).
- `/spex:spec` — write a lean feature spec.
- `/spex:plan` — turn the approved spec into a technical plan.
- `/spex:tasks` — break the plan into independent tasks.
- `/spex:implement` — execute tasks with TDD and scope-guard.
- `/spex:update` — edit context/config anytime.

## Key rules
- Build ONLY what the spec asks. No extra functions, options, or edge cases.
- Use Context7 → ContextHub → WebSearch for docs; save focused digests to `spex/memory/tech-docs/`.
- `self_review` is toggled in `spex/config.yml`.
