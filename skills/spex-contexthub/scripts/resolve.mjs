#!/usr/bin/env node
// resolve.mjs — Fastspex ContextHub doc-URL resolver. Zero-dep, Node 18+ (global fetch).
// Usage: node resolve.mjs <package> <ecosystem> [version]
//   ecosystem: npm | pypi | go | maven   (maven package = "group:artifact")
// Output (stdout): JSON { name, ecosystem, version, docsUrls[], llmsTxt[], notes[] }
// It only RESOLVES where docs live — it never fetches or distills content (that is the LLM's job).

const [, , pkgArg, ecoArg, versionArg] = process.argv;
const TIMEOUT_MS = 8000;

function out(obj, code = 0) {
  process.stdout.write(JSON.stringify(obj, null, 2) + "\n");
  process.exit(code);
}
function fail(msg) {
  out({ error: msg }, 1);
}

if (!pkgArg || !ecoArg) {
  fail("usage: node resolve.mjs <package> <ecosystem:npm|pypi|go|maven> [version]");
}
const eco = ecoArg.toLowerCase();

async function fetchWithTimeout(url, opts = {}) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), TIMEOUT_MS);
  try {
    return await fetch(url, { ...opts, signal: ctrl.signal, redirect: "follow" });
  } finally {
    clearTimeout(t);
  }
}
async function getJson(url) {
  const res = await fetchWithTimeout(url, { headers: { accept: "application/json" } });
  if (!res.ok) throw new Error(`HTTP ${res.status} for ${url}`);
  return res.json();
}
function uniq(arr) {
  return [...new Set(arr.filter(Boolean))];
}
function cleanRepoUrl(u) {
  if (!u) return null;
  if (typeof u === "object") u = u.url || "";
  return String(u)
    .replace(/^git\+/, "")
    .replace(/\.git$/, "")
    .replace(/^git:\/\//, "https://")
    .replace(/^ssh:\/\/git@/, "https://")
    .replace(/^git@([^:]+):/, "https://$1/");
}
function originOf(u) {
  try {
    return new URL(u).origin;
  } catch {
    return null;
  }
}

const CODE_HOSTS = new Set([
  "https://github.com", "https://gitlab.com", "https://bitbucket.org",
  "https://codeberg.org", "https://sr.ht", "https://sourceforge.net",
]);

async function probeLlms(urls) {
  // Code hosts are repos, not doc sites — probing them yields false positives.
  const origins = uniq(urls.map(originOf)).filter((o) => !CODE_HOSTS.has(o));
  const found = [];
  for (const o of origins) {
    for (const name of ["llms.txt", "llms-full.txt"]) {
      const target = `${o}/${name}`;
      try {
        const res = await fetchWithTimeout(target, { method: "GET" });
        if (res.ok) {
          const ct = res.headers.get("content-type") || "";
          // Guard against SPA catch-all routes that 200 with HTML.
          if (!ct.includes("html")) found.push(target);
        }
      } catch {
        /* ignore — probe is best-effort */
      }
    }
  }
  return found;
}

async function resolveNpm(pkg, version) {
  const path = pkg.replace("/", "%2F"); // scoped: @scope/name -> @scope%2Fname
  const data = await getJson(`https://registry.npmjs.org/${path}`);
  const v = version || data["dist-tags"]?.latest;
  const meta = data.versions?.[v] || data;
  return {
    version: v,
    docsUrls: uniq([
      meta.homepage || data.homepage,
      cleanRepoUrl(meta.repository || data.repository),
    ]),
  };
}

async function resolvePypi(pkg, version) {
  const url = version
    ? `https://pypi.org/pypi/${encodeURIComponent(pkg)}/${encodeURIComponent(version)}/json`
    : `https://pypi.org/pypi/${encodeURIComponent(pkg)}/json`;
  const info = (await getJson(url)).info || {};
  const pu = info.project_urls || {};
  return {
    version: info.version,
    docsUrls: uniq([
      pu.Documentation, pu.Docs, pu.Homepage, pu["Home-page"],
      pu.Source, pu.Repository, info.docs_url, info.home_page, info.project_url,
    ]),
  };
}

async function resolveGo(mod, version) {
  // pkg.go.dev URL is deterministic; no clean JSON API needed.
  const base = version ? `https://pkg.go.dev/${mod}@${version}` : `https://pkg.go.dev/${mod}`;
  return { version: version || null, docsUrls: [base] };
}

async function resolveMaven(coord, version) {
  let group, artifact;
  if (coord.includes(":")) [group, artifact] = coord.split(":");
  else artifact = coord;
  const notes = [];
  let v = version;
  try {
    const q = group ? `g:${group} AND a:${artifact}` : `a:${artifact}`;
    const data = await getJson(
      `https://search.maven.org/solrsearch/select?q=${encodeURIComponent(q)}&rows=1&wt=json`
    );
    const doc = data.response?.docs?.[0];
    if (doc) {
      group = group || doc.g;
      v = v || doc.latestVersion || doc.v;
    }
  } catch (e) {
    notes.push(`maven search failed: ${e.message}`);
  }
  const urls = [];
  if (group && v) urls.push(`https://javadoc.io/doc/${group}/${artifact}/${v}`);
  else if (group) urls.push(`https://javadoc.io/doc/${group}/${artifact}`);
  return { version: v || null, docsUrls: uniq(urls), notes };
}

const RESOLVERS = { npm: resolveNpm, pypi: resolvePypi, go: resolveGo, maven: resolveMaven };

(async () => {
  const resolver = RESOLVERS[eco];
  if (!resolver) fail(`unsupported ecosystem: ${eco} (npm|pypi|go|maven)`);
  const result = { name: pkgArg, ecosystem: eco, version: null, docsUrls: [], llmsTxt: [], notes: [] };
  try {
    const r = await resolver(pkgArg, versionArg);
    result.version = r.version ?? versionArg ?? null;
    result.docsUrls = r.docsUrls || [];
    if (r.notes) result.notes.push(...r.notes);
    result.llmsTxt = await probeLlms(result.docsUrls);
  } catch (e) {
    result.notes.push(`resolve failed: ${e.message}`);
  }
  out(result);
})();
