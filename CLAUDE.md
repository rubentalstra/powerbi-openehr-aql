# CLAUDE.md

Project context for Claude Code (and other AI agents) working in this repository. Keep this file under ~300 lines — it is loaded on every session.

## Mission

Build and maintain **powerbi-openehr-aql**: a native Power BI custom data connector that lets analysts run [openEHR AQL](https://specifications.openehr.org/releases/QUERY/latest/AQL.html) against any openEHR Clinical Data Repository (CDR) from Power BI Desktop, with refresh through the on-premises gateway.

Primary artifact: a signed `.pqx` built on Windows CI, distributed via GitHub Releases.

The exhaustive spec lives in [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md); the current execution slice (Phase 0 + Phase 1 → v0.1.0) lives in [`please-look-at-this-optimized-hippo.md`](please-look-at-this-optimized-hippo.md).

## Stack

| Layer | Tech |
|---|---|
| Language | Power Query M |
| Build | `Microsoft.PowerQuery.SdkTools` (`MakePQX`) in `src/` |
| Sign | `MakePQX sign` with a self-signed PFX (real cert deferred post-v0.1.0) |
| Dev CDR | EHRbase 2.x in Docker (`dev/docker-compose.yml`) |
| Docs | MkDocs Material on GitHub Pages |
| CI | GitHub Actions, `windows-latest` runner |
| Test data | OPTs + compositions seeded by `dev/scripts/load-seed.{sh,ps1}` |

## Repo layout

```
src/                           Power Query SDK workspace
  OpenEHR.pq                   Main section document
  OpenEHR.query.pq             Dev test harness
  resources.resx               Localized strings
  OpenEHR{16,20,24,32,40,48}.png
  Aql.pqm                      HTTP + AQL execution
  Schema.pqm                   Result-set → table + RM expansion
  Paging.pqm                   GetAllPages (factory: takes Aql)
  Navigation.pqm               Nav-table helper + builders (factory: takes Aql, Paging, Schema)
  .pqignore                    Packaging exclusions for MakePQX
  .vscode/                     Power Query SDK workspace settings
tests/
  fixtures/canonical-queries.json
  integration/run-canonical.sh
dev/                           Local CDR + seed + scripts
docs/                          MkDocs content
.github/workflows/             CI, release, docs, CodeQL, link check
```

## M coding conventions

- `PascalCase` for public, exported members (`OpenEHR.Aql`, `OpenEHR.StoredQuery`).
- `camelCase` or `_camelCase` for locals inside `let` blocks.
- Namespace public functions as `OpenEHR.<Verb>`.
- Error records: `error Error.Record("OpenEHR.<Category>", message, details)` — category ∈ {`AqlError`, `AuthError`, `TimeoutError`, `ConflictError`, `NotFoundError`, `HttpError`}.
- **Never** take credentials as function parameters. Always `Extension.CurrentCredential()`.
- `Web.Contents` base URL must be **static**. Put variability in `RelativePath` / `Query` / `Headers`.
- `ExcludedFromCacheKey = {"Authorization"}` on every `Web.Contents` call so rotating tokens don't poison the cache.
- Every AQL projection in this repo aliases its column (`SELECT c/uid/value AS Uid ...`) so result columns never end up named `#0`/`#1`.

## Build / test commands

**Local macOS dev (editor + docker + docs):**

```bash
# Local CDR
(cd dev && cp -n .env.example .env && docker compose up -d)
bash dev/scripts/check-health.sh
bash dev/scripts/load-seed.sh

# Docs preview
pip install -r docs/requirements.txt
mkdocs serve
```

**Build / sign / test (Windows, usually via CI):**

```powershell
# Assumes MakePQX is already on PATH from the extracted
# Microsoft.PowerQuery.SdkTools package.
# Build
cd src
MakePQX compile . -t OpenEHR

# Sign with self-signed cert
MakePQX sign --certificate ..\dev-cert.pfx --password $env:CODE_SIGN_CERT_PASSWORD bin\AnyCPU\Debug\OpenEHR.mez

# Run M tests against test harness
MakePQX run OpenEHR.query.pq
```

From macOS, trigger a CI build remotely: `gh workflow run ci.yml`.

## Test CDR endpoints (DEV-ONLY CREDENTIALS)

| Endpoint | URL | User | Password |
|---|---|---|---|
| Local EHRbase | `http://localhost:8080/ehrbase/rest/openehr/v1` | `ehrbase` | `ehrbase` |
| Public sandbox (shared, do not flood) | `https://sandkiste.ehrbase.org/ehrbase/rest/openehr/v1` | (see sandbox docs) | (see sandbox docs) |

Both are **local / shared dev**. Never store real-tenant credentials anywhere Claude can read them.

## Gotcha list (review before touching M)

1. **`TestConnection` is mandatory.** Missing it = silent refresh failure on the gateway.
2. **OAuth `state`** must be preserved across `StartLogin` / `FinishLogin` or service-side refresh breaks.
3. **`Web.Contents` dynamic-source error** — base URL must be static; variability lives in `RelativePath` / `Query`.
4. **`ExcludedFromCacheKey = {"Authorization"}`** — without it, token rotation poisons the response cache.
5. **Never accept credentials as function arguments.** They persist into saved `.pbix` files.
6. **No `Diagnostics.Trace` at row level by default.** PHI leak.
7. **No DirectQuery.** Import + Incremental Refresh only for AQL.
8. **`query_parameters` (underscore)**, not `query-parameters`. The spec moved; older drafts used the hyphenated form.
9. **Alias every AQL column** with `AS` — otherwise `#0`/`#1`.
10. **Pad missing columns with typed nulls** so schema is stable across refreshes (empty result ≠ undefined schema).

## Never do

- Commit secrets: `*.pfx`, `*.snk`, `.env`, real-tenant URLs or tokens. `.gitignore` already blocks these, but double-check before every commit.
- Change `DataSource.Kind = "OpenEHR"` after the first release. Changing it orphans every saved credential in the wild.
- Log PHI — AQL queries or composition bodies — at `Information` level or above.
- Hand-edit signed `.pqx` artifacts. Rebuild and re-sign.
- `git commit` or `git push` from this session. The user runs git operations manually.

## Links

- openEHR AQL spec: https://specifications.openehr.org/releases/QUERY/latest/AQL.html
- openEHR REST spec (Definitions): https://specifications.openehr.org/releases/ITS-REST/latest/definition.html
- openEHR REST spec (EHR): https://specifications.openehr.org/releases/ITS-REST/latest/ehr.html
- Power Query M reference: https://learn.microsoft.com/en-us/powerquery-m/
- Power Query SDK: https://learn.microsoft.com/en-us/power-query/install-sdk
- TripPin samples (canonical nav table + paging patterns): https://learn.microsoft.com/en-us/power-query/samples/trippin/readme
- EHRbase: https://github.com/ehrbase/ehrbase
