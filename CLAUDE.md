# Fastspex

A lean, spec-driven development toolkit for Claude Code.

## When to mention
- When the user wants to start spec-driven development in a project.
- When the user asks about Fastspex commands (`/init`, `/spec`, `/design`, `/tasks`, `/implement`).

## Core idea
1 spec = 1 feature. Story + numbered EARS requirements (Priority) + explicit "Out of scope" per requirement. HARD-GATE at spec, design, and tasks. TDD + scope-guard at implement.

## Commands
- `/init` — scaffold `spex/` context (greenfield or brownfield).
- `/spec` — write a feature spec (Introduction + Glossary + numbered EARS).
- `/design` — turn the approved spec into a technical design (core inline, heavy detail in `details/`).
- `/tasks` — break the design into granular, traceable tasks.
- `/implement` — execute tasks with TDD and scope-guard.

## Key rules
- Build ONLY what the spec asks. No extra functions, options, or edge cases.
- Use Context7 → WebSearch for docs; save focused digests to `spex/memory/tech-docs/`.
- `self_review` is toggled in `spex/config.yml`.
- `/init` materializes `spex/templates/` (and, on Claude Code, `spex/scripts/`) so steps and scripts share one project-local source; skills fall back to inline behavior when scripts are absent.
- On Claude Code, the `spex/scripts/` layer makes feature numbering + the spec→design→tasks→implement gates deterministic (exit-code `check`, like spec-kit's check-prerequisites); each step ends with a `→ Next:` handoff. Skills fall back to inline prompt logic when scripts are absent.
