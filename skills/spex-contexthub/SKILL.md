---
name: spex-contexthub
description: Resolve a library's canonical docs (registry + llms.txt) without any MCP server, then distill only the used API into tech-docs/. The bundled middle tier of the Context7 → ContextHub → WebSearch chain.
---
# Fastspex: ContextHub

## Overview
Self-contained doc fetcher — turns a library name into a focused `tech-docs/<lib>.md` digest using a bundled resolver script + your own `WebFetch`. **No MCP server required.** This is the "ContextHub" tier referenced by spex-init/plan/implement/update.

## When to use
- A doc digest is missing and `config.yml → docs_source: contexthub`, OR the doc chain has fallen past Context7. NOT a standalone workflow step — it is called by the other spex skills.

## Inputs
- `lib` (package name) · `ecosystem` (`npm`|`pypi`|`go`|`maven` — infer from the manifest) · optional `version` (pin from the manifest/lockfile). For maven, `lib` is `group:artifact`.

## Flow
1. **Resolve URLs.** From this skill's directory, run the bundled resolver (Node 18+, zero-dep):
   `node scripts/resolve.mjs <lib> <ecosystem> [version]`
   It prints JSON: `{ name, version, docsUrls[], llmsTxt[], notes[] }`. No doc-fetching tool of your own is needed for this step.
2. **Pick a source.** Prefer `llmsTxt[0]` (authored for LLMs) → else the first `docsUrls` entry that looks like official docs → else the repo URL.
3. **Fetch.** `WebFetch` the chosen URL (plus its API/reference page if the landing page is just navigation). If `docsUrls` is empty or every fetch fails → return `{ ok: false }` so the caller falls back to WebSearch.
4. **Distill.** Extract ONLY the APIs the feature/stack actually uses — signatures, key options, one short example. Drop marketing, install boilerplate, and unrelated APIs.
5. **Save.** Write `spex/memory/tech-docs/<lib>.md`: first line `> <lib> @<version> — source: <url>`, then the focused digest. Return `{ ok: true, path }`.

## Rules
- NEVER ask the user anything — must stay parallel-safe inside spex-init §B.
- Keep the digest focused — same anti-bloat rule as the rest of Fastspex. No full-doc dumps.
- If the resolver errors (see `notes`) or Node is absent, don't block — report `{ ok: false }` and let the caller fall back to WebSearch.

## Red flags — STOP if you think
| Thought | Reality |
|---|---|
| "Dump the whole docs page" | Digest only the used API. Lean files only. |
| "Resolver failed, so stop" | Never block. Return ok:false → caller uses WebSearch. |
| "Ask the user for the docs URL" | No questions. Resolve or fall back silently. |
