# Detail: Doc-source resolution + ContextHub install

Single source of truth for Requirement 2. The design summarizes; this file holds the full
procedure, the config schema change, and the install-script behavior.

## 1. The canonical resolution block (shared, inserted verbatim into 3 skills)
Insert this same block where each skill distills a digest — `init` §B (eager CORE libs),
`design` step 2, `implement` step 5 — replacing the old `resolve via docs_source (Context7 ·
WebSearch …)` wording. It is short by design so the three copies cannot meaningfully drift; the
chain itself is also restated once in `CLAUDE.md`.

```
Doc-source resolution (run per digest that must be distilled):
1. Context7 MCP available → use Context7.
2. Else if ContextHub installed (config `contexthub_install: installed`, `chub-mcp` reachable)
   → use ContextHub.
3. Else if config `contexthub_install: unknown` → ask the user ONCE (binary AskUserQuestion,
   "Install ContextHub …?", Yes recommended-first):
     • Yes → run scripts/<bash|powershell>/install-contexthub; on exit 0 set
       config `contexthub_install: installed` and use ContextHub.
     • No  → set config `contexthub_install: declined`.
4. Else (declined, or ContextHub unavailable) → use WebSearch / WebFetch.
Failure at query time → fall to the NEXT tier. If every tier fails, save a name+version
pointer noting "docs not distilled". Never block.
```

Notes:
- "Context7 MCP available" / "`chub-mcp` reachable" are agent-side checks (is the tool present).
- The one-time prompt is the ONLY interactive point; the `contexthub_install` flag suppresses
  re-prompting across every later step and skill.

## 2. config.yml schema change (written by `/init`)
- **Remove** `docs_source` (resolution is now automatic; readers ignore it if a legacy file has it).
- **Add** `contexthub_install: unknown` at init time. Values: `unknown | installed | declined`.

Read via the existing `read_config contexthub_install` helper (`common.sh`); write by appending /
replacing the line (init owns creation, skills flip `unknown → installed|declined`).

## 3. Install script behavior (new files)
`skills/init/scripts/bash/install-contexthub.sh` and
`skills/init/scripts/powershell/install-contexthub.ps1`. Copied to `spex/scripts/` by `/init`
step 2b (the existing whole-dir copy already covers new files — no copy-logic change needed).

Behavior (both variants, parity):
1. Require `npm` on PATH → else print guidance, exit non-zero.
2. `npm install -g @aisuite/chub`.
3. Register the MCP server: if `claude` CLI present → `claude mcp add --scope user chub -- chub-mcp`;
   else write/merge `{ "mcpServers": { "chub": { "command": "chub-mcp" } } }` into `~/.claude/mcp.json`.
4. Print a one-line `--json` result `{"installed":true}` on success; exit 0 on success, non-zero on
   any failed step (caller leaves config `unknown` on failure so the next run can retry, OR sets
   `declined` only on explicit user "No" — failure ≠ decline).

Idempotency: re-running is safe (npm `-g` upgrades in place; `claude mcp add` / json-merge skip a
duplicate `chub` entry).

## 4. Scope guard
NOT in scope (matches spec R2 Out-of-scope): authoring ContextHub specs, auto-installing Context7,
offline caching beyond `tech-docs/`. The script only installs + registers; it does not configure
API keys (ContextHub needs none for the bundled registry).
