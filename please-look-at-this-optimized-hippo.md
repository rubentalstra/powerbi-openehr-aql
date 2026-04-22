# Implementation Plan — Phase 0 + Phase 1 MVP (v0.1.0)

## Context

The repo `powerbi-openehr-aql` currently contains only `README.md`, and a 1,537-line [`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md) — no source, no scaffolding, no infra. The source plan is a complete specification across 4 phases and 30+ tasks; this plan is the **execution order** for the first slice the user committed to: **Phase 0 (Foundation) + Phase 1 (MVP through v0.1.0)**.

**Why now:** The user wants to start building. The source plan is exhaustive but does not handle two real constraints surfaced in clarification:
1. **Dev host is macOS, not Windows.** Power BI Desktop, the on-prem gateway, and the Power Query SDK's interactive features are Windows-only. We adapt by doing all build/sign work on a **GitHub Actions `windows-latest` runner** and reserving Power BI Desktop validation for whenever the user has Windows access.
2. **No paid code-signing cert.** We use a **self-signed PFX** for dev/CI builds; users install it as a trusted publisher locally. A real cert purchase is deferred until post-v0.1.0 traction.

**Outcome:** A signed (self-signed) `.pqx` produced by CI, verifiable end-to-end against local EHRbase, with full repo scaffolding, docs site, and release pipeline ready to swap in a real cert later.

---

## Constraints baked into this plan

| Constraint | Adaptation |
|---|---|
| macOS-only dev host | M editing in VS Code on macOS; build/sign/test on `windows-latest` CI runner. Docker (EHRbase) runs locally on macOS. |
| No paid code-signing cert | Self-signed `.pfx` generated once via `New-SelfSignedCertificate` in CI bootstrap; PFX base64 stored as repo secret. Document the "trusted root cert install" install path for users. |
| User cannot run Power BI Desktop locally | Acceptance criteria split into **CI-verifiable** (must pass to merge) and **Windows-Desktop-verifiable** (deferred, user runs when Windows available). Mark each task accordingly. |
| Power Query SDK VS Code extension on macOS | Has limited functionality (no Power BI Desktop integration). Use it for syntax/lint only; CI does the actual builds via `MakePQX` from .NET 10 SDK (cross-platform, but we run on Windows for compat). |

---

## Execution order — Phase 0 (Foundation)

Tasks ordered for minimum churn. Source-plan tasks in brackets.

### Step 1 — Root scaffolding [Task 0.1]
**Files at repo root:**
- `README.md` — replace 1-line stub with project hero, install path, links to docs site (placeholder URL), badge row
- `CHANGELOG.md` — Keep-a-Changelog 1.1.0 template, "Unreleased" section
- `ROADMAP.md` — distilled from `IMPLEMENTATION_PLAN.md` phase summaries
- `CONTRIBUTING.md` — branch naming (`feat/`, `fix/`, `docs/`, `chore/`), Conventional Commits, PR template ref, dev setup pointer to `dev/`
- `CODE_OF_CONDUCT.md` — Contributor Covenant 2.1 verbatim
- `SECURITY.md` — disclosure policy, contact email (placeholder for user to fill: `security@<domain>` or GitHub Security Advisories), 48h ack / 14d fix SLA
- `SUPPORT.md` — bugs → Issues, Q → Discussions, AQL syntax → openEHR Discourse
- `.gitignore` — exclude `*.pqx`, `*.mez`, `*.pfx`, `*.snk`, `.env`, `.env.local`, `bin/`, `obj/`, `.vs/`, `.idea/`, `.vscode/*` (except `.vscode/settings.json`, `.vscode/extensions.json`), `node_modules/`, `site/`, `dev/secrets/`
- `.gitattributes` — `*.pq text eol=lf linguist-language=PowerQuery`, `*.pqm text eol=lf linguist-language=PowerQuery`, `*.pbix binary`, `*.pqx binary`
- `.editorconfig` — 4-space indent for `*.pq,*.pqm`; 2-space for `*.yml,*.yaml,*.json,*.md`; LF; UTF-8

**Note:** `CLAUDE.md` deferred to Step 6.

**Verify:** `git status` clean after add+commit; GitHub repo "About" sidebar populated; license auto-detected.

### Step 2 — `.github/` automation [Task 0.2]
**Files under `.github/`:**
- `CODEOWNERS` — `* @rubentalstra`
- `FUNDING.yml` — commented-out placeholders for `github`, `open_collective`
- `dependabot.yml` — `github-actions` weekly; reserve `npm`, `docker`, `pip` ecosystems for later when those package files exist
- `PULL_REQUEST_TEMPLATE.md` — Summary / Type / Testing / Breaking change / Linked issue
- `ISSUE_TEMPLATE/bug_report.yml` — fields per source plan (connector ver, PBI Desktop ver, OS, CDR vendor+ver, AQL [PHI-redacted], error record, repro)
- `ISSUE_TEMPLATE/feature_request.yml` — problem / solution / alternatives / who benefits
- `ISSUE_TEMPLATE/cdr_compatibility.yml` — vendor / vendor ver / REST ver / works / fails / sample req+resp
- `ISSUE_TEMPLATE/config.yml` — `blank_issues_enabled: false`; contact links to GitHub Discussions and openEHR Discourse
- `DISCUSSION_TEMPLATE/q-and-a.yml`, `show-and-tell.yml`, `ideas.yml`

**Verify:** YAML lints with `yamllint` (install via `brew install yamllint`); GitHub UI shows three issue templates; CODEOWNERS auto-assigns on a dummy PR.

### Step 3 — EHRbase local CDR [Task 0.4]
**Files under `dev/`:**
- `dev/docker-compose.yml` — services: `ehrbase-postgres` (postgres 16 with init script for required extensions), `ehrbase` (pin `ehrbase/ehrbase:2.x.x` — pick exact version, **never `latest`**), `keycloak` (deferred config until Phase 2 but include in compose so port assignment is stable)
- `dev/postgres-init/01-init-ehrbase.sql` — create roles, extensions (`temporal_tables`, `jsquery`, `btree_gist`); copy from EHRbase upstream init
- `dev/seed-data/templates/` — 3 OPTs sourced from [EHRbase test fixtures](https://github.com/ehrbase/ehrbase/tree/develop/service/src/test/resources/knowledge/operational_templates): `vital_signs.opt`, `laboratory_test.opt`, `demographics.opt`
- `dev/seed-data/compositions/` — ≥50 sample compositions in canonical JSON (generate via Better Sample Generator or hand-craft small set, then loop-insert with variations)
- `dev/scripts/load-seed.sh` — bash version (macOS-friendly) using `curl`; uploads templates via `POST /definition/template/adl1.4`, then loops compositions via `POST /ehr/{ehr_id}/composition`. Mirror `load-seed.ps1` for Windows CI.
- `dev/scripts/load-seed.ps1` — PowerShell equivalent for CI / Windows users
- `dev/scripts/check-health.sh` + `.ps1` — pings `/management/health`, `/definition/template`, `/query/aql`
- `dev/.env.example` — documents required env vars (`EHRBASE_USER`, `EHRBASE_PASSWORD`, ports); the real `.env` is gitignored

**Adaptation for macOS:** Provide bash scripts as primary; PowerShell as secondary for Windows CI. Source plan was PowerShell-only.

**Verify (CI-verifiable, runs on macOS too):** `docker compose up -d` healthy in <60s; `check-health.sh` green; ≥3 templates listable; `SELECT COUNT(c) FROM EHR e CONTAINS COMPOSITION c` returns ≥50; one canonical query returns rows.

### Step 4 — Documentation site (MkDocs Material) [Task 0.5]
**Files:**
- `mkdocs.yml` — Material theme; nav structure mirrors source plan section 0.5 doc tree; `repo_url`, `edit_uri`
- `docs/index.md` — landing (mirror README hero)
- All placeholder pages from source plan section 0.5 (auth, cookbook, reference, compliance, troubleshooting, contributing — each a stub with H1 + "Coming soon" + back-link)
- `.github/workflows/docs.yml` — runs on push to `main`; checkout (`actions/checkout@v5`) → setup Python 3.13 (`actions/setup-python@v5`) → `pip install mkdocs-material` → `mkdocs gh-deploy --force`. `permissions: contents: write`.
- Repo Setting: GitHub Pages source = `gh-pages` branch root (must be done manually in repo settings after first workflow run; document in `CONTRIBUTING.md`)

**Verify (CI-verifiable):** workflow green; `https://rubentalstra.github.io/powerbi-openehr-aql` loads with full nav.

### Step 5 — `CLAUDE.md` + `.claude/` [Task 0.6]
**Files:**
- `CLAUDE.md` at root — sections per source plan: mission, stack table, repo layout (current + projected), M conventions, build/test commands (macOS bash + Windows pwsh equivalents), test CDR endpoints (local-only creds clearly marked DEV-ONLY), the 10-item gotcha list, "never do" list, links
- `.claude/settings.json` — minimal: model preference, allowlist for safe local commands (`docker compose ps`, `docker compose logs`, `mkdocs serve`, `pwsh -File dev/scripts/*`, `bash dev/scripts/*`)
- `.claude/settings.local.json` listed in `.gitignore` (already covered by `.gitignore` entry above; verify)
- `.claude/commands/build.md` — invokes CI workflow remotely via `gh workflow run ci.yml` (since local Windows build unavailable on macOS) **plus** documents the local `MakePQX` invocation for users on Windows
- `.claude/commands/test-aql.md` — accepts AQL string arg, runs via `curl` against local EHRbase, pretty-prints JSON via `jq`
- `.claude/commands/release.md` — bumps version in `version.txt`, updates `CHANGELOG.md`, tags `v$VERSION`, pushes
- `.claude/commands/spec.md` — accepts topic arg; uses `WebFetch` against the relevant openEHR / Power Query / TripPin spec page
- `.claude/commands/review.md` — runs Claude through the repo-root connector files with critique prompt

**Note on Task 0.3 (local tooling):** Skipped as a discrete step — most of it is environment setup the user does once. Tracked instead in `CLAUDE.md` "Prereqs" section. macOS-relevant subset: `git`, Docker Desktop for Mac, VS Code + Power Query SDK extension, .NET 10 SDK (`brew install --cask dotnet-sdk`), Node.js 24 LTS (`brew install node@24`), PowerShell 7.6 (`brew install --cask powershell`), `yamllint` (`brew install yamllint`), `jq` (`brew install jq`).

---

## Execution order — Phase 1 (MVP → v0.1.0)

### Step 6 — Connector skeleton via SDK on Windows CI [Task 1.1]
**Cannot be done locally on macOS** — the SDK's "Create new project" is a VS Code command that requires the Windows-only build chain to validate. Workaround:
1. Hand-author the file set rather than using the SDK generator. The generated files are documented; we replicate them.
2. Files under `src/`:
   - `OpenEHR.pq` — section document with hello-world per source plan
   - `OpenEHR.query.pq` — dev test harness
   - `.pqignore` — excludes local non-connector files from `MakePQX compile`
   - `.vscode/settings.json` — points the Power Query SDK at `OpenEHR.query.pq` / `OpenEHR.mez`
   - `resources.resx` — `DataSourceLabel`, `ButtonTitle`, `ButtonHelp`, error message keys
   - `OpenEHR{16,20,24,32,40,48}.png` — placeholder icons (solid-color squares with letter, generated via `magick` or hand-drawn; designer pass deferred)
3. CI workflow (`.github/workflows/ci.yml`, see Step 11) builds and uploads `OpenEHR.mez` as artifact.

**Lock now:** `DataSource.Kind = "OpenEHR"` — never change after v0.1.0; changing orphans every saved credential.

**Verify (CI):** `MakePQX compile` succeeds on `windows-latest`; `.mez`/`.pqx` artifact uploaded.
**Verify (deferred — user on Windows):** copy `.pqx` to `%USERPROFILE%\Documents\Power BI Desktop\Custom Connectors\`; "openEHR (Beta)" appears in Get Data → Other; 3-row table returns.

### Step 7 — Basic Auth [Task 1.2]
Modify `src/OpenEHR.pq`:
- `Authentication = [ UsernamePassword = [], Anonymous = [] ]`
- `OpenEHR.Contents(cdrBaseUrl as Uri.Type)` — accepts URL only, never credentials
- `GetAuthHeader()` reads `Extension.CurrentCredential()`, builds `Authorization: Basic <base64>`
- Initial test: hit `GET /definition/template` against local EHRbase

**Verify (CI):** unit test (M test harness or PowerShell-driven `MakePQX run`) confirms header construction.
**Verify (deferred):** Power BI Desktop prompts for creds, persists, surfaces `OpenEHR.AuthError` on bad creds, omits creds from saved `.pbix` (grep test).

### Step 8 — AQL execution [Task 1.3]
**Refactor:** Move HTTP client to `src/Aql.pqm`.
- `ExecuteAql(cdrBaseUrl, aql, optional params, optional offset, optional fetch)` — POST `/query/aql`
- **Critical pattern:** `Web.Contents(staticBase, [RelativePath = "query/aql", Headers, Content, ManualStatusHandling = {400,401,403,404,408,409,500}])`. URL must be static; everything dynamic goes in `RelativePath`/`Query`. Source-plan gotcha #3.
- Map status codes to error categories: `OpenEHR.AqlError` (400), `OpenEHR.AuthError` (401/403), `OpenEHR.TimeoutError` (408), `OpenEHR.HttpError` (other)
- Body uses `query_parameters` (underscore, current spec — gotcha #8)

**Verify (CI integration test):** spin up EHRbase via service container; run `SELECT c/uid/value AS Uid FROM EHR e CONTAINS COMPOSITION c LIMIT 10`; assert response has `meta`/`q`/`columns`/`rows`. Run an invalid AQL; assert `OpenEHR.AqlError` raised with vendor message.

### Step 9 — Result-set → table + RM-object flattening + paging [Tasks 1.4, 1.5, 1.6]
**Files:** `src/Schema.pqm`, `src/Paging.pqm`.
- `ResultSetToTable(rs)` — `#table(colNames, rows)`; handle empty rows (typed empty table); fall back to `path` when `name` missing (legacy CDRs)
- `RmExpanders` record per source plan: `DV_QUANTITY` → `_magnitude`/`_units`/`_precision`; `DV_CODED_TEXT` → `_value`/`_code`/`_terminology`; `DV_TEXT`, `DV_DATE_TIME`, `DV_BOOLEAN`, `DV_COUNT`. Unknown `_type` → `<col>_json` text column.
- Sample **first non-null row** for type detection (gotcha — never row 0)
- Opt-out via `ExpandRmObjects = false`
- `GetAllPages(cdrBaseUrl, aql, params, pageSize)` — lag-one `List.Generate`; stop when latest page returns `< pageSize` rows; `Binary.Buffer` each response (prevents lazy re-fetch)

**Verify (CI integration test):** seed an EHR with a blood-pressure composition; query systolic; assert `systolic_magnitude` is `Number.Type`, `systolic_units` is `Text.Type`. 2,500-row query with pageSize 1000 → 3 HTTP calls (assert via mock or count requests in EHRbase logs).

### Step 10 — Public function API + navigation table + TestConnection [Tasks 1.7, 1.8, 1.9]
- `OpenEHR.Aql` typed function via `Value.ReplaceType` — multi-line, code-formatted AQL field
- `OpenEHR.StoredQuery` — POST `/query/{qname}[/{version}]`
- `Table.ToNavigationTable` helper (verbatim copy from Microsoft docs — it is **not** built in)
- `OpenEHR.Contents` returns nav table: Ad-hoc AQL (function leaf) / Stored Queries (folder, lazy via `Table.AddColumn`) / Templates (folder) / EHRs (table leaf)
- `TestConnection = (dataSourcePath) => let url = Json.Document(dataSourcePath)[cdrBaseUrl] in { "OpenEHR.Contents", url }` — **mandatory** for gateway refresh; missing it = silent refresh failure

**Verify (CI):** function metadata serialization round-trip; nav-table type metadata present.
**Verify (deferred — user on Windows):** Get Data → openEHR → enter base URL → see 4-entry navigator; expand "Stored Queries" → list populates from `GET /definition/query/`. Publishing a sample `.pbix` to Power BI Service + scheduled refresh succeeds twice in a row (gateway round-trip).

### Step 11 — CI pipeline [Task 1.11]
**`.github/workflows/ci.yml`** — runs on PR + push to `main`:
- `runs-on: windows-latest`
- Steps: checkout → download/extract `Microsoft.PowerQuery.SdkTools` → spin up EHRbase via `services:` container (postgres + ehrbase) → wait for health (loop `curl /management/health`, max 90s, **not** fixed sleep) → run `dev/scripts/load-seed.ps1` → `cd src && MakePQX compile . -t OpenEHR` → run M unit tests via `cd src && MakePQX run OpenEHR.query.pq` → upload `OpenEHR.mez` artifact
- Matrix later when adding multi-CDR (Phase 2)

**`.github/workflows/codeql.yml`** — CodeQL on PowerShell helpers (`dev/scripts/*.ps1`)

**`.github/workflows/spec-link-check.yml`** — weekly cron; `lychee` action over `docs/**` and `IMPLEMENTATION_PLAN.md`; opens issue on broken links

**Verify (CI):** PR triggers `ci.yml`, completes <10 min; intentionally-broken test fails the workflow; CI status badge in `README.md`.

### Step 12 — Self-signed cert + release pipeline [Task 1.12, adapted]
**Self-signed cert generation (one-time, run on Windows or via `pwsh` on macOS):**

```powershell
$cert = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject "CN=powerbi-openehr-aql Dev Cert" `
    -KeyUsage DigitalSignature `
    -FriendlyName "powerbi-openehr-aql Dev Cert" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(3)
$pfxPwd = ConvertTo-SecureString -String "<dev-password>" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath ./dev-cert.pfx -Password $pfxPwd
[Convert]::ToBase64String([IO.File]::ReadAllBytes("./dev-cert.pfx")) | Set-Clipboard
# Also export public .cer for end-user trust install
Export-Certificate -Cert $cert -FilePath ./dev-cert.cer
```

**Repo secrets:** `CODE_SIGN_CERT_PFX_BASE64`, `CODE_SIGN_CERT_PASSWORD`.

**`.github/workflows/release.yml`** — runs on tag `v*`:
- Build `.mez` → decode PFX from secret → `MakePQX sign --certificate dev-cert.pfx --password $env:CODE_SIGN_CERT_PASSWORD OpenEHR.mez` → output `.pqx` → generate changelog from conventional commits (e.g., `git-cliff` action) → `gh release create $TAG --notes-file CHANGELOG_FRAGMENT.md OpenEHR.pqx dev-cert.cer`

**Trade-offs of self-signed (document in `docs/getting-started/install-uncertified.md` AND `docs/getting-started/install-self-signed.md`):**
- ✅ Free, instant, perfect for dev / internal testing / CI
- ❌ End users see SmartScreen warnings; must either (a) set Power BI security to "Allow any extension" (security risk warning) **or** (b) install the published `dev-cert.cer` to Windows "Trusted Root Certification Authorities" + "Trusted Publishers" stores (one-time, requires admin)
- ❌ **Not viable for AppSource certification** (Phase 3 Task 3.5) — that requires a real EV/OV cert from Sectigo/DigiCert/SSL.com
- ❌ Cert expiry (3y here) means re-issuing + re-signing future releases

**Verify (CI):** tagging `v0.0.1-alpha` triggers `release.yml`; signed `.pqx` and `.cer` attached to GitHub Release; `Get-AuthenticodeSignature` (run by user on Windows or by a follow-up CI verify job) confirms signature chains to the self-signed root after `.cer` install.

### Step 13 — Sandbox testing + canonical query suite [Task 1.10]
**Files:**
- `tests/fixtures/canonical-queries.json` — 5 queries per source plan: composition count by template; latest BP per EHR; lab results by date range; demographics summary; stored query execution
- `tests/integration/run-canonical.sh` — runs each against `$CDR_URL`, validates non-empty + correct types
- CI matrix: local EHRbase (always), public sandbox (`https://sandkiste.ehrbase.org` — only on push to `main`, since it's a shared resource and we shouldn't hammer per-PR)

**Verify:** all 5 pass against local EHRbase; all 5 pass or have documented deviations against sandbox; deviations captured in `docs/cookbook/cdr-vendor-notes/ehrbase.md`.

### Step 14 — Docs content [Task 1.13]
Replace placeholders from Step 4 with real content:
- `docs/index.md` — what + why + 60s install
- `docs/getting-started/install-end-user.md` — Windows analyst path with self-signed cert install (PowerShell snippet for `Import-Certificate -FilePath dev-cert.cer -CertStoreLocation Cert:\LocalMachine\Root` + `Cert:\LocalMachine\TrustedPublisher`, requires admin)
- `docs/getting-started/install-gateway-admin.md` — IT path, on-prem gateway requirement (note: VNet gateway not supported)
- `docs/getting-started/install-uncertified.md` — "Allow any extension" path (security warning)
- `docs/getting-started/install-self-signed.md` — **new vs source plan** — replaces `install-signed-cert.md` for now; explains the self-signed trust install flow; `install-signed-cert.md` becomes a "future when we ship a real cert" stub
- `docs/auth/basic.md` — username/password setup
- `docs/cookbook/blood-pressure-trend.md` — full E2E recipe
- `docs/cookbook/cdr-vendor-notes/ehrbase.md` — Step 13 findings
- `docs/reference/functions.md` — `OpenEHR.Aql`, `OpenEHR.StoredQuery` API ref
- `docs/reference/options.md` — every option (`PageSize`, `ExpandRmObjects`, `Timeout`)
- `docs/reference/error-codes.md` — every `OpenEHR.*Error` category
- `docs/troubleshooting.md` — top 10 issues + how to read `mashup-trace.json`

### Step 15 — Sample dashboards [Task 1.14] — DEFERRED
**Cannot complete on macOS.** `.pbix` files require Power BI Desktop. Action: create `dev/sample-pbix/README.md` listing the three intended reports with their exact AQL queries; user (or future Windows-using contributor) builds and commits the `.pbix` files in a follow-up PR. Mark as "Phase 1 incomplete — pending Windows access" in `CHANGELOG.md` for v0.1.0.

### Step 16 — v0.1.0 release [Task 1.15]
- Verify all CI-verifiable acceptance criteria green
- Update `CHANGELOG.md` v0.1.0 entry with explicit "Known limitations: untested on Power BI Desktop locally; sample `.pbix` files pending; release signed with self-signed cert (see install docs)"
- Tag `v0.1.0`, push, verify release pipeline produces signed artifact
- Demo video recording deferred until user has Windows access (note in announcement)
- Skip public launch posts (Discourse, Reddit, LinkedIn) until at least one user has confirmed end-to-end install on Windows; until then, pre-announce as "early adopter preview, Windows testers wanted" on openEHR Discourse only

---

## Critical files to be created (high-signal subset)

| Path | Purpose | Step |
|---|---|---|
| [src/OpenEHR.pq](src/OpenEHR.pq) | Main connector section | 6, 7, 10 |
| [src/Aql.pqm](src/Aql.pqm) | HTTP + AQL execution | 8 |
| [src/Schema.pqm](src/Schema.pqm) | Result-set → table + RM expansion | 9 |
| [src/Paging.pqm](src/Paging.pqm) | `GetAllPages` | 9 |
| [src/Navigation.pqm](src/Navigation.pqm) | Nav-table helper + builders | 10 |
| [src/.pqignore](src/.pqignore) | MakePQX packaging exclusions | 6 |
| [src/resources.resx](src/resources.resx) | Localized strings | 6 |
| [dev/docker-compose.yml](dev/docker-compose.yml) | Local EHRbase + Postgres + Keycloak | 3 |
| [dev/scripts/load-seed.sh](dev/scripts/load-seed.sh) | Seed loader (bash) | 3 |
| [dev/scripts/load-seed.ps1](dev/scripts/load-seed.ps1) | Seed loader (pwsh, for CI) | 3 |
| [.github/workflows/ci.yml](.github/workflows/ci.yml) | Build + integration tests on Windows runner | 11 |
| [.github/workflows/release.yml](.github/workflows/release.yml) | Tag → signed `.pqx` GitHub Release | 12 |
| [.github/workflows/docs.yml](.github/workflows/docs.yml) | MkDocs deploy to gh-pages | 4 |
| [mkdocs.yml](mkdocs.yml) | Docs site config | 4 |
| [CLAUDE.md](CLAUDE.md) | Claude Code project context | 5 |
| [.claude/commands/](.claude/commands/) | Project slash commands | 5 |

---

## Patterns to reuse (no reinvention)

- **Navigation table helper**: copy `Table.ToNavigationTable` verbatim from [Microsoft Power Query nav-tables docs](https://learn.microsoft.com/en-us/power-query/handling-navigation-tables) — do not rewrite.
- **Lag-one paging**: copy the `List.Generate` "fetch ahead, check previous" pattern from [TripPin Part 5](https://learn.microsoft.com/en-us/power-query/samples/trippin/5-paging/readme) — the obvious pattern is off-by-one.
- **OAuth PKCE** (later, Phase 2): copy from [microsoft/DataConnectors OAuthPKCE sample](https://github.com/microsoft/DataConnectors/tree/master/samples/OAuthPKCE) — do not hand-roll PKCE.
- **EHRbase docker-compose + Postgres init**: copy from [upstream EHRbase repo](https://github.com/ehrbase/ehrbase/blob/develop/docker-compose.yml) — Postgres extension setup is fiddly.
- **Self-signed cert flow**: standard PowerShell `New-SelfSignedCertificate` (snippet in Step 12).

---

## Verification — end-to-end

| Layer | How |
|---|---|
| Repo structure | `git ls-files` matches Step-1/2 file list; license auto-detected on GitHub |
| EHRbase local | `cd dev && docker compose up -d && bash scripts/check-health.sh` returns all green; canonical query returns rows |
| Docs site | `mkdocs serve` on macOS port 8000; gh-pages workflow green; URL renders |
| Connector build | CI `windows-latest` job uploads `OpenEHR.mez` artifact |
| Connector unit tests | `MakePQX run` against M test harness in CI; assertions on `ResultSetToTable`, RM expansion, `GetAllPages` |
| Connector integration tests | CI spins EHRbase service container, loads seed, runs canonical queries via the built connector |
| Signed release | Tag `v0.0.1-alpha` → `release.yml` produces signed `.pqx` + `.cer` on GitHub Release; `Get-AuthenticodeSignature` (verify-job in CI) shows valid signature chain after trusting the test cert |
| Power BI Desktop | **Deferred** to user when Windows available — install signed `.pqx` per `docs/getting-started/install-self-signed.md`; run all 5 canonical queries; verify nav table; publish a sample `.pbix` and trigger Service refresh through on-prem gateway |
| Public sandbox | CI scheduled run against `sandkiste.ehrbase.org` weekly (cron in `ci.yml` or separate workflow) |

---

## What this plan explicitly defers

| Item | Why | When to revisit |
|---|---|---|
| Sample `.pbix` files (Task 1.14) | Requires Power BI Desktop (Windows) | When user has Windows access |
| Power BI Desktop interactive validation | Same | Same |
| On-prem gateway test (Task 1.9 deferred verify) | Same | Same |
| Public launch posts (Discourse, Reddit, etc.) | Avoid promoting untested-by-anyone build | After ≥1 Windows user confirms install works |
| Demo video | Same | Same |
| Real Authenticode cert (~$300-600/yr) | User wants to validate before spending | When repo gets ≥10 stars OR before Phase 3 cert submission, whichever first |
| Phase 2 (OAuth PKCE/Client Creds, PHI-safe mode, multi-vendor matrix) | Out of scope for this plan | After v0.1.0 ships |
| Keycloak realm config (Task 0.4 has Keycloak in compose only as a port placeholder) | Phase 2 OAuth work | Phase 2 Task 2.1 |

---

## Open assumptions (flag if wrong)

1. User will run `docker compose up -d` locally on macOS for dev work (Docker Desktop installed).
2. User has push access to `https://github.com/rubentalstra/powerbi-openehr-aql` and admin rights to configure secrets, GitHub Pages source, branch protection.
3. `SECURITY.md` contact email + `FUNDING.yml` handles to be filled in by the user before publishing publicly (placeholders in Step 1 / Step 2).
4. Branch protection on `main` will be enabled by user manually (cannot be set via committed file alone — repo Settings → Branches).
5. The user is okay with v0.1.0 being honestly labeled "early preview, untested on PBI Desktop by maintainer" — alternative is to delay v0.1.0 until Windows access is acquired.
