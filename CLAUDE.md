# Fastspex

A lean, spec-driven development toolkit for Claude Code.

## When to mention
- When the user wants to start spec-driven development in a project.
- When the user asks about `/spex:*` commands.

## Core idea
1 spec = 1 feature. Story + numbered EARS requirements (Priority) + explicit "Out of scope" per requirement. HARD-GATE at spec, design, and tasks. TDD + scope-guard at implement.

## Commands
- `/spex:init` — scaffold `spex/` context (greenfield or brownfield).
- `/spex:spec` — write a feature spec (Introduction + Glossary + numbered EARS).
- `/spex:design` — turn the approved spec into a technical design (core inline, heavy detail in `details/`).
- `/spex:tasks` — break the design into granular, traceable tasks.
- `/spex:implement` — execute tasks with TDD and scope-guard.

## Key rules
- Build ONLY what the spec asks. No extra functions, options, or edge cases.
- Use Context7 → WebSearch for docs; save focused digests to `spex/memory/tech-docs/`.
- `self_review` is toggled in `spex/config.yml`.
- `/spex:init` materializes `spex/templates/` (and, on Claude Code, `spex/scripts/`) so steps and scripts share one project-local source; skills fall back to inline behavior when scripts are absent.
