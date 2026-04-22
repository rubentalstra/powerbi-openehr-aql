# powerbi-openehr-aql — Implementation Plan

A task-by-task execution plan for building a native Power BI custom data connector for openEHR Archetype Query Language (AQL). This document is written to be handed to an AI agent (Claude Code, Cursor, etc.) for direct execution.

---

## How to use this plan

- **Phases** group related work; complete a phase before starting the next.
- **Tasks** are atomic units of work, each implementable in one focused session.
- Each task has the same structure: **Goal**, **Prerequisites**, **Files**, **Steps**, **Code (when relevant)**, **Acceptance criteria**, **References**, **Pitfalls**.
- **Acceptance criteria** are verifiable; if any item fails, the task is not done — do not move on.
- **Status markers:** prepend each task heading with `[Not Started]`, `[In Progress]`, `[Blocked: reason]`, or `[Done]` as you progress.
- File paths are relative to the repo root unless noted.
- All sources are linked inline at the point of use **and** consolidated in [Section A — Sources](#appendix-a--sources) at the end.

---

## Project at a glance

| Item | Value |
|------|-------|
| Repository | [`rubentalstra/powerbi-openehr-aql`](https://github.com/rubentalstra/powerbi-openehr-aql) |
| Owner | `rubentalstra` (personal account; can be transferred to an org later if the project grows into a multi-BI suite) |
| License | Apache-2.0 |
| Primary language | Power Query M |
| Build target | Signed `.pqx` |
| Distribution | GitHub Releases (primary), Microsoft AppSource (Phase 3+, when certification reopens) |
| Test CDR | EHRbase (local Docker + public sandbox) |
| Docs site | MkDocs Material on GitHub Pages |
| CI/CD | GitHub Actions |

---

## Phase 0 — Foundation Setup

**Phase goal:** Repository scaffolded, local development environment working, EHRbase CDR running locally with seed data, Power Query SDK able to build an empty connector, Claude Code configured.

**Phase exit criterion:** You can edit M code in VS Code, run `MakePQX compile`, copy the resulting `.pqx` to Power BI Desktop, see the connector load — even if it does nothing yet.

---

### Task 0.1: Repository scaffolding and root files

**Goal:** Create the GitHub repository with all root-level project files populated.

**Prerequisites:** GitHub account, Git installed locally.

**Files to create at repo root:**
- `README.md` — project overview, install instructions, link to docs
- `LICENSE` — Apache-2.0 full text from https://www.apache.org/licenses/LICENSE-2.0.txt
- `CLAUDE.md` — Claude Code project instructions (see Task 0.6)
- `CHANGELOG.md` — empty Keep-a-Changelog v1.1.0 template from https://keepachangelog.com/en/1.1.0/
- `ROADMAP.md` — public-facing roadmap derived from this plan
- `CONTRIBUTING.md` — dev setup, branch naming (`feat/`, `fix/`, `docs/`), Conventional Commits, PR process
- `CODE_OF_CONDUCT.md` — Contributor Covenant 2.1 from https://www.contributor-covenant.org/version/2/1/code_of_conduct/
- `SECURITY.md` — vulnerability disclosure policy with security contact email and PGP key, response SLA (48h ack, 14-day fix target)
- `SUPPORT.md` — routes: bugs → Issues, questions → Discussions, AQL syntax → openEHR Discourse
- `.gitignore` — exclude `*.pqx`, `*.mez`, `*.pfx`, `.env`, `bin/`, `obj/`, `.vs/`, `.idea/`, `node_modules/`, `site/` (MkDocs output)
- `.gitattributes` — `*.pq text eol=lf`, `*.pqm text eol=lf`, mark `.pq`/`.pqm` as `linguist-language=PowerQuery`
- `.editorconfig` — 4-space indent for M, 2-space for YAML/JSON, LF endings, UTF-8

**Steps:**
1. Repo already exists at https://github.com/rubentalstra/powerbi-openehr-aql. Confirm it is public and Apache-2.0 licensed in repo Settings → General. If not, fix both.
2. Locally: `git clone https://github.com/rubentalstra/powerbi-openehr-aql.git`, then create all files above.
3. First commit: `chore: initial repository scaffolding`.
4. Push to `main`. Set `main` as protected: Settings → Branches → Add branch protection rule → require PR reviews, require status checks, no force-push.

**Acceptance criteria:**
- [ ] All 12 root files exist on `main`
- [ ] Repo is public, license shows as Apache-2.0 in GitHub UI
- [ ] `main` is protected
- [ ] `README.md` renders cleanly on the GitHub repo page

**References:**
- Keep a Changelog: https://keepachangelog.com/en/1.1.0/
- Contributor Covenant 2.1: https://www.contributor-covenant.org/version/2/1/code_of_conduct/
- Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/
- GitHub branch protection: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches

**Pitfalls:**
- Do not commit a `.pfx` code-signing cert. Ever. Add it to `.gitignore` before creating the file.
- `SECURITY.md` must include a real reachable email — security researchers use it.

---

### Task 0.2: GitHub repository automation files

**Goal:** Set up `.github/` with templates, workflows, and ownership rules.

**Prerequisites:** Task 0.1 done.

**Files to create under `.github/`:**
- `CODEOWNERS` — assign yourself as owner of all paths initially: `* @rubentalstra`
- `FUNDING.yml` — GitHub Sponsors / Open Collective handles (leave empty initially with placeholder comments)
- `dependabot.yml` — weekly checks for `github-actions` and (later) `npm` ecosystems
- `PULL_REQUEST_TEMPLATE.md` — sections: Summary, Type (feat/fix/docs/refactor/test/chore), Testing, Breaking change Y/N, Linked issue
- `ISSUE_TEMPLATE/bug_report.yml` — required fields: connector version, Power BI Desktop version, OS, CDR vendor + version, AQL query (redacted of PHI), full error record, repro steps
- `ISSUE_TEMPLATE/feature_request.yml` — fields: problem, suggested solution, alternatives, who benefits
- `ISSUE_TEMPLATE/cdr_compatibility.yml` — fields: vendor, vendor version, REST API version, what works, what fails, sample request/response. Becomes your living compatibility matrix.
- `ISSUE_TEMPLATE/config.yml` — `blank_issues_enabled: false`; contact links to GitHub Discussions for questions and to https://discourse.openehr.org/ for AQL syntax help
- `DISCUSSION_TEMPLATE/q-and-a.yml` and `show-and-tell.yml` and `ideas.yml`

**Workflow files under `.github/workflows/` (created in later tasks):**
- `ci.yml` — Task 1.11
- `release.yml` — Task 1.12
- `docs.yml` — Task 0.5
- `codeql.yml` — Task 1.11
- `spec-link-check.yml` — Task 1.13

**Acceptance criteria:**
- [ ] Opening "New issue" on the GitHub repo shows three template choices, blank issues disabled
- [ ] Opening "New PR" auto-populates the PR template
- [ ] Dependabot status appears in repo Insights
- [ ] CODEOWNERS auto-assigns reviewer when a PR is opened (test with a dummy PR)

**References:**
- Issue templates (YAML): https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository
- Dependabot config: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file
- CODEOWNERS syntax: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- Discussion templates: https://docs.github.com/en/discussions/managing-discussions-for-your-community/creating-discussion-category-forms

**Pitfalls:**
- YAML issue forms are picky about indentation; lint with https://github.com/google/yamllint locally before pushing.

---

### Task 0.3: Local development tooling

**Goal:** All tools needed to develop, build, sign, and test the connector are installed and verified.

**Prerequisites:** None.

**Tools to install (Windows host required for full Power BI Desktop testing):**
1. **Git** — https://git-scm.com/downloads
2. **Power BI Desktop** (latest) — Microsoft Store or https://www.microsoft.com/en-us/download/details.aspx?id=58494
3. **VS Code** — https://code.visualstudio.com/
4. **Power Query SDK extension for VS Code** — https://marketplace.visualstudio.com/items?itemName=PowerQuery.vscode-powerquery-sdk (the VS extension is deprecated; do not install it)
5. **.NET 10 SDK (LTS)** — https://dotnet.microsoft.com/en-us/download (released November 2025, supported through November 2028; required by `MakePQX`)
6. **Docker Desktop** — https://www.docker.com/products/docker-desktop/
7. **Node.js 24 LTS** ("Krypton") — https://nodejs.org/ (Active LTS through April 2028; required for Claude Code and tooling). Node.js 22 LTS is also acceptable; do not use Node.js 20 (EOL April 30, 2026).
8. **PowerShell 7.6 LTS** — https://github.com/PowerShell/PowerShell/releases (released March 2026, built on .NET 10, supported ~3 years)
9. **`yamllint`** (optional) — requires Python 3.13+ (3.14 recommended, latest stable). `pip install yamllint`

**Verification commands (run each, document output, confirm minimum versions):**
```bash
git --version          # any recent
dotnet --version       # 10.0.x
docker --version       # any recent
node --version         # v24.x.x (or v22.x.x as fallback)
pwsh --version         # 7.6.x (or 7.4.x as fallback)
code --list-extensions | grep PowerQuery
```

**Acceptance criteria:**
- [ ] All commands above return version numbers without error
- [ ] Power BI Desktop opens
- [ ] VS Code shows the Power Query SDK in the Extensions panel as enabled
- [ ] `docker run hello-world` succeeds

**References:**
- Power Query SDK install guide: https://learn.microsoft.com/en-us/power-query/install-sdk
- VS Code SDK repo: https://github.com/microsoft/vscode-powerquery-sdk

**Pitfalls:**
- Power BI Desktop must be the **Win32 installer** version, not the Microsoft Store version, if you need to load custom connectors via folder drop. Both work for cert-trusted loads.
- The Power Query SDK requires Windows for certain features; macOS/Linux can edit M but cannot run the full SDK or Power BI Desktop.

---

### Task 0.4: EHRbase local CDR

**Goal:** A local openEHR CDR running on Docker, seeded with templates and sample compositions, queryable via curl.

**Prerequisites:** Task 0.3 done.

**Files to create under `dev/`:**
- `dev/docker-compose.yml` — services: `ehrbase-postgres`, `ehrbase`, `keycloak` (for OAuth dev later)
- `dev/seed-data/templates/` — at least 3 operational templates (.opt): `vital_signs.opt`, `laboratory_test.opt`, `demographics.opt`
- `dev/seed-data/compositions/` — at least 50 sample compositions in canonical JSON
- `dev/keycloak-realm.json` — pre-configured realm `openehr`, client `powerbi-connector`, two test users
- `dev/scripts/load-seed.ps1` — uploads templates via `POST /definition/template/adl1.4`, then loops compositions via `POST /ehr/{ehr_id}/composition`
- `dev/scripts/check-health.ps1` — pings `/management/health`, `/definition/template`, `/query/aql`

**Steps:**
1. Use the official EHRbase Docker image: https://hub.docker.com/r/ehrbase/ehrbase. Pin a specific version tag (do not use `latest`).
2. Configure for local dev only: `SECURITY_AUTHTYPE=BASIC`, `SECURITY_AUTHUSER=ehrbase`, `SECURITY_AUTHPASSWORD=<dev-only-strong-password>`.
3. Source seed templates from the openEHR Clinical Knowledge Manager: https://ckm.openehr.org/ckm/ (free, requires registration). For initial dev, the EHRbase test fixtures repo provides ready-to-use OPTs: https://github.com/ehrbase/ehrbase/tree/develop/service/src/test/resources/knowledge/operational_templates
4. Generate sample compositions matching the templates. The Better Sample Generator is convenient: https://better-care.atlassian.net/wiki/spaces/SUPP/pages/1737031777/Synthetic+data
5. Write `load-seed.ps1` to upload templates then compositions.
6. Verify with one AQL query via curl:

```bash
curl -u ehrbase:<password> \
  -H "Content-Type: application/json" \
  -X POST http://localhost:8080/ehrbase/rest/openehr/v1/query/aql \
  -d '{"q": "SELECT c/uid/value FROM EHR e CONTAINS COMPOSITION c LIMIT 5"}'
```

**Acceptance criteria:**
- [ ] `docker compose up -d` brings all services healthy within 60 seconds
- [ ] `check-health.ps1` reports green for all endpoints
- [ ] At least 3 templates uploaded, listable via `GET /definition/template`
- [ ] At least 50 compositions exist, confirmed by `SELECT COUNT(c) FROM EHR e CONTAINS COMPOSITION c`
- [ ] One sample AQL query returns non-empty rows

**References:**
- EHRbase docs: https://docs.ehrbase.org/docs/EHRbase/Introduction
- EHRbase REST overview: https://docs.ehrbase.org/docs/EHRbase/REST/REST_API
- EHRbase Docker image: https://hub.docker.com/r/ehrbase/ehrbase
- openEHR REST Definitions API: https://specifications.openehr.org/releases/ITS-REST/latest/definition.html
- openEHR REST EHR API: https://specifications.openehr.org/releases/ITS-REST/latest/ehr.html
- openEHR CKM (template source): https://ckm.openehr.org/ckm/
- Public EHRbase sandbox (for cross-checking later): https://sandkiste.ehrbase.org

**Pitfalls:**
- EHRbase requires Postgres with specific extensions; the docker-compose must include the init script. The official quickstart compose handles this — copy from https://github.com/ehrbase/ehrbase/blob/develop/docker-compose.yml.
- Templates must be ADL 1.4 OPTs, not ADL2 archetypes, for the standard `/definition/template/adl1.4` endpoint.

---

### Task 0.5: Documentation site (MkDocs Material) and pages workflow

**Goal:** A live documentation site at `https://rubentalstra.github.io/powerbi-openehr-aql` deployed automatically on push to `main`.

**Prerequisites:** Task 0.1 done.

**Files to create:**
- `mkdocs.yml` — site config with Material theme, nav structure, GitHub repo link
- `docs/index.md` — landing page mirroring README hero
- `docs/getting-started/install-end-user.md` — placeholder
- `docs/getting-started/install-gateway-admin.md` — placeholder
- `docs/getting-started/install-uncertified.md` — placeholder
- `docs/getting-started/install-signed-cert.md` — placeholder
- `docs/auth/basic.md`, `oauth-pkce.md`, `client-credentials.md`, `entra-id.md` — placeholders
- `docs/cookbook/blood-pressure-trend.md`, `incremental-refresh.md` — placeholders
- `docs/cookbook/cdr-vendor-notes/ehrbase.md`, `better.md`, `code24.md`, `dips.md` — placeholders
- `docs/reference/functions.md`, `options.md`, `error-codes.md` — placeholders
- `docs/compliance/hipaa.md`, `gdpr.md`, `phi-safe-mode.md` — placeholders
- `docs/troubleshooting.md` — placeholder
- `docs/contributing/dev-environment.md` — placeholder
- `.github/workflows/docs.yml` — builds MkDocs site, deploys to `gh-pages` branch on push to `main`

**Steps:**
1. `pip install mkdocs-material`. Run `mkdocs new .` to scaffold, then customize `mkdocs.yml`.
2. Configure GitHub Pages in repo settings: Source = `gh-pages` branch, root.
3. Workflow: use `actions/checkout@v5` + `actions/setup-python@v5` + `pip install mkdocs-material` + `mkdocs gh-deploy --force` (manual approach, recommended by Material docs over third-party actions). This requires `permissions: contents: write` on the workflow.
4. Add the docs URL to the repo's "About" sidebar and to README.

**Acceptance criteria:**
- [ ] `mkdocs serve` runs locally on port 8000
- [ ] Push to `main` triggers `docs.yml`, which finishes green
- [ ] `https://rubentalstra.github.io/powerbi-openehr-aql` loads with the Material theme
- [ ] Navigation shows all placeholder pages

**References:**
- MkDocs Material: https://squidfunk.github.io/mkdocs-material/
- MkDocs Material on GitHub Pages: https://squidfunk.github.io/mkdocs-material/publishing-your-site/
- GitHub Pages: https://docs.github.com/en/pages/quickstart

**Pitfalls:**
- The `docs.yml` workflow needs `permissions: contents: write` to push to `gh-pages`. Default token permissions in 2024+ are read-only.

---

### Task 0.6: Claude Code configuration (`CLAUDE.md` and `.claude/`)

**Goal:** Claude Code is installed, the repo carries a `CLAUDE.md` with all project context, and team-shared slash commands work.

**Prerequisites:** Tasks 0.1, 0.3 done.

**Files to create:**

**`CLAUDE.md`** at repo root, containing:
- Project mission paragraph
- Tech stack table
- Repo layout (`src/` connector workspace plus `tests/`, `docs/`, `dev/`, `.github/`)
- M coding conventions: `PascalCase` for public functions, `_camelCase` for locals, `Type.Function` namespacing, error records via `Error.Record("OpenEHR.<Category>", message, details)`, no credentials as function parameters (always `Extension.CurrentCredential()`)
- Build commands: `pwsh dev/scripts/install-connector.ps1`, `pwsh tests/run-tests.ps1`
- Test CDR endpoints with **dev-only** credentials clearly marked, plus the public sandbox
- The **gotcha list** (ten items minimum, drawn from the deep research):
  1. `TestConnection` is required or gateway refresh fails silently
  2. `state` parameter must be passed through `StartLogin` for OAuth Service-side refresh
  3. `Web.Contents` requires static base URL; variability goes in `RelativePath`/`Query` to avoid the dynamic-data-source error
  4. Set `ExcludedFromCacheKey = {"Authorization"}` so rotating tokens don't poison the cache
  5. Never accept credentials as M function arguments (they persist into `.pbix`)
  6. Never enable `Diagnostics.Trace` row-level logging by default (PHI leak)
  7. Don't attempt DirectQuery for AQL — Import + Incremental Refresh only
  8. AQL `query_parameters` (underscore) per current spec; older drafts used `query-parameters` (hyphen)
  9. Always alias every column in AQL with `AS` so result columns are named, not `#0`/`#1`
  10. Pad missing columns with typed nulls to keep schema stable across refreshes
- What Claude must never do: commit secrets, log PHI, change the `DataSource.Kind` ID after first release, modify signed build artifacts manually
- Reference links to the AQL spec, REST spec, TripPin samples

**`.claude/settings.json`** (committed): minimal — set the model preference, allowlist common bash commands.

**`.claude/settings.local.json`** in `.gitignore`: per-developer overrides.

**`.claude/commands/*.md`** files (each is a slash command with frontmatter):
- `build.md` — runs `dev/scripts/install-connector.ps1`
- `test-aql.md` — accepts an AQL string, runs it via curl against local EHRbase, pretty-prints the result
- `release.md` — bumps version, updates CHANGELOG, tags, pushes
- `spec.md` — accepts a topic argument; fetches the relevant openEHR or Power Query spec page into context
- `review.md` — runs Claude through the `src/` connector files with a "what would you improve" prompt

**Steps:**
1. Install Claude Code: `npm install -g @anthropic-ai/claude-code`. Sign in: `claude` then follow prompts.
2. From repo root, run `claude` to verify it loads `CLAUDE.md`.
3. Test each slash command at least once.

**Acceptance criteria:**
- [ ] `claude --version` returns a version
- [ ] Starting `claude` in repo root shows it loaded `CLAUDE.md`
- [ ] `/build`, `/test-aql`, `/spec` produce expected output
- [ ] `.claude/settings.local.json` is gitignored (verify with `git status` after creating it)

**References:**
- Claude Code overview: https://docs.claude.com/en/docs/claude-code/overview
- Claude Code memory and `CLAUDE.md`: https://docs.claude.com/en/docs/claude-code/memory
- Claude Code slash commands: https://docs.claude.com/en/docs/claude-code/slash-commands
- Claude Code settings: https://docs.claude.com/en/docs/claude-code/settings

**Pitfalls:**
- Test credentials in `CLAUDE.md` must be for a local-only EHRbase. Never put production credentials in any file Claude reads.

---

## Phase 1 — MVP Connector

**Phase goal:** A signed `.pqx` that lets anyone with an openEHR CDR run an AQL query and see results in Power BI Desktop, with refresh working from the Power BI Service via the on-premises gateway.

**Phase exit criterion:** v0.1.0 tagged on GitHub, signed `.pqx` in the release artifacts, README+gateway-admin guide published, three demo `.pbix` files reproducible end-to-end.

---

### Task 1.1: Hello-world connector skeleton

**Goal:** A connector that builds, loads in Power BI Desktop, and returns a hardcoded 3-row table.

**Prerequisites:** Phase 0 complete.

**Files to create under `src/`:**
- `OpenEHR.pq` — main connector section document
- `OpenEHR.query.pq` — dev test harness
- `.pqignore` — excludes local non-connector files from `MakePQX compile`
- `.vscode/settings.json` — points the Power Query SDK at the connector query + built `.mez`
- `resources.resx` — localizable strings (button label, source name, error messages)
- `OpenEHR16.png`, `OpenEHR20.png`, `OpenEHR24.png`, `OpenEHR32.png`, `OpenEHR40.png`, `OpenEHR48.png` — connector icons (placeholder until designer pass)

**Steps:**
1. In VS Code, open `src/` as the Power Query SDK workspace, or use the repo-level `powerbi-openehr-aql.code-workspace` and target the `src` folder.
2. Keep `.vscode/settings.json` under `src/` pointing at `OpenEHR.query.pq` and `bin\AnyCPU\Debug\OpenEHR.mez`.
3. Replace the body of `OpenEHR.pq` with the skeleton below.
4. Build from `src/`: `MakePQX compile . -t OpenEHR`.
5. Copy `OpenEHR.mez`/`.pqx` to `%USERPROFILE%\Documents\Power BI Desktop\Custom Connectors\`.
6. In Power BI Desktop: File → Options → Security → Data Extensions → "(Not Recommended) Allow any extension to load…". Restart Power BI Desktop.
7. Get Data → Other → "openEHR (Beta)" → Connect. Confirm the 3-row table appears.

**Code (`src/OpenEHR.pq` skeleton):**
```powerquery
section OpenEHR;

[DataSource.Kind="OpenEHR", Publish="OpenEHR.Publish"]
shared OpenEHR.Contents = () as table =>
    let
        rows = {
            {"hello", 1, #date(2026, 1, 1)},
            {"world", 2, #date(2026, 1, 2)},
            {"openEHR", 3, #date(2026, 1, 3)}
        },
        result = #table(
            type table [Name = text, Value = number, Date = date],
            rows
        )
    in
        result;

OpenEHR = [
    TestConnection = (dataSourcePath) => { "OpenEHR.Contents" },
    Authentication = [ Anonymous = [] ],
    Label = Extension.LoadString("DataSourceLabel")
];

OpenEHR.Publish = [
    Beta = true,
    Category = "Online Services",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://github.com/rubentalstra/powerbi-openehr-aql",
    SourceImage = OpenEHR.Icons,
    SourceTypeImage = OpenEHR.Icons
];

OpenEHR.Icons = [
    Icon16 = { Extension.Contents("OpenEHR16.png"), Extension.Contents("OpenEHR20.png"),
               Extension.Contents("OpenEHR24.png"), Extension.Contents("OpenEHR32.png") },
    Icon32 = { Extension.Contents("OpenEHR32.png"), Extension.Contents("OpenEHR40.png"),
               Extension.Contents("OpenEHR48.png") }
];
```

**Acceptance criteria:**
- [ ] Project builds without errors via SDK
- [ ] `.pqx`/`.mez` file appears in `bin/AnyCPU/Debug/`
- [ ] After copying to Power BI Desktop's connector folder and restarting, "openEHR (Beta)" appears in Get Data → Other
- [ ] Connecting returns the 3-row hardcoded table
- [ ] No errors in Power BI Desktop's `mashup-trace.json`

**References:**
- TripPin Part 1 (OData): https://learn.microsoft.com/en-us/power-query/samples/trippin/1-odata/readme
- TripPin Part 2 (REST): https://learn.microsoft.com/en-us/power-query/samples/trippin/2-rest/readme
- Power Query SDK setup: https://learn.microsoft.com/en-us/power-query/install-sdk
- Connector Extensibility overview: https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-connector-extensibility
- Power Query M reference: https://learn.microsoft.com/en-us/powerquery-m/

**Pitfalls:**
- The `DataSource.Kind` value (`"OpenEHR"`) becomes part of the credential storage key. Changing it later orphans every saved credential. Lock it now.
- Icon files must be exact pixel sizes. The SDK validates this.

---

### Task 1.2: Basic Auth implementation

**Goal:** The connector accepts a username/password and includes them in HTTP Basic auth headers.

**Prerequisites:** Task 1.1 done.

**Files to modify:** `OpenEHR.pq`.

**Steps:**
1. Change the `Authentication` record to declare `UsernamePassword`.
2. Refactor `OpenEHR.Contents` to take a `cdrBaseUrl` parameter (typed `Uri.Type`).
3. Use `Extension.CurrentCredential()` inside the function to retrieve credentials — never accept them as parameters.
4. Build the `Authorization: Basic <base64(user:pass)>` header.
5. Test against local EHRbase by calling `GET /definition/template` and returning the template list as a table.

**Code (auth header construction):**
```powerquery
GetAuthHeader = () as record =>
    let
        cred = Extension.CurrentCredential(),
        header =
            if cred[AuthenticationKind] = "UsernamePassword" then
                let
                    token = Binary.ToText(
                        Text.ToBinary(cred[Username] & ":" & cred[Password]),
                        BinaryEncoding.Base64
                    )
                in
                    [ Authorization = "Basic " & token ]
            else
                error Error.Record("OpenEHR.AuthError",
                    "Unsupported authentication kind: " & cred[AuthenticationKind])
    in
        header;
```

**Acceptance criteria:**
- [ ] First connect prompts for Username/Password
- [ ] Credentials persist (second connect uses cached creds without re-prompting)
- [ ] Wrong credentials produce a clear `OpenEHR.AuthError` not a raw 401
- [ ] Successful connect returns the template list from local EHRbase
- [ ] Credentials do **not** appear in the `.pbix` file (confirm by unzipping a saved `.pbix` and grepping for the password)

**References:**
- Power Query authentication overview: https://learn.microsoft.com/en-us/power-query/handling-authentication
- `Extension.CurrentCredential`: https://learn.microsoft.com/en-us/powerquery-m/extension-currentcredential

**Pitfalls:**
- If you accept Username/Password as M function parameters, they persist into the `.pbix` and ship to anyone you share the file with. Guaranteed PHI/security incident. Always use `Extension.CurrentCredential()`.

---

### Task 1.3: AQL execution via `POST /query/aql`

**Goal:** The connector can execute an AQL string against the CDR and return the raw response as a record.

**Prerequisites:** Task 1.2 done.

**Files to modify:** `OpenEHR.pq`. Optionally factor into `Aql.pqm`.

**Steps:**
1. Implement `ExecuteAql(cdrBaseUrl, aql, optional params, optional offset, optional fetch)` that POSTs to `/query/aql`.
2. Use `Web.Contents` with **static base URL** and put `query/aql` in `RelativePath`. This is the only way refresh works in the Power BI Service.
3. Handle status codes: 200 → parse JSON; 400 → wrap in `OpenEHR.AqlError` with the spec's `message` field; 401/403 → `OpenEHR.AuthError`; 408 → `OpenEHR.TimeoutError`; others → `OpenEHR.HttpError`.
4. Test with a simple AQL: `SELECT c/uid/value AS Uid, c/name/value AS Name FROM EHR e CONTAINS COMPOSITION c LIMIT 10`.

**Code:**
```powerquery
ExecuteAql = (cdrBaseUrl as text, aql as text,
              optional params as nullable record,
              optional offset as nullable number,
              optional fetch as nullable number) as record =>
let
    body = Json.FromValue([
        q                = aql,
        offset           = offset ?? 0,
        fetch            = fetch  ?? 1000,
        query_parameters = params ?? []
    ]),
    response = Web.Contents(cdrBaseUrl, [
        RelativePath = "query/aql",
        Headers = [
            #"Content-Type" = "application/json",
            #"Accept"       = "application/json"
        ] & GetAuthHeader(),
        Content = body,
        ManualStatusHandling = { 400, 401, 403, 404, 408, 409, 500 }
    ]),
    status = Value.Metadata(response)[Response.Status],
    parsed =
        if status = 200 then
            Json.Document(response)
        else
            let
                bodyText = try Text.FromBinary(response) otherwise "",
                problem  = try Json.Document(bodyText) otherwise [ message = bodyText ]
            in
                error Error.Record(
                    if status = 400 then "OpenEHR.AqlError"
                    else if status = 401 or status = 403 then "OpenEHR.AuthError"
                    else if status = 408 then "OpenEHR.TimeoutError"
                    else "OpenEHR.HttpError",
                    "HTTP " & Number.ToText(status) & ": " & (problem[message]? ?? ""),
                    problem
                )
in
    parsed;
```

**Acceptance criteria:**
- [ ] Calling `ExecuteAql` with a valid AQL returns a record with `meta`, `q`, `columns`, `rows` fields
- [ ] Calling with an invalid AQL surfaces the CDR's parse error message (not a generic 400)
- [ ] Calling with wrong creds raises `OpenEHR.AuthError`
- [ ] No "dynamic data source" warning appears in Power BI Desktop's diagnostics

**References:**
- openEHR REST Query API spec: https://specifications.openehr.org/releases/ITS-REST/latest/query.html
- `Web.Contents`: https://learn.microsoft.com/en-us/powerquery-m/web-contents
- Static URL pattern for refresh: https://learn.microsoft.com/en-us/power-query/handling-resource-path
- Wait + retry patterns: https://learn.microsoft.com/en-us/power-query/wait-retry

**Pitfalls:**
- Putting the full URL into `Web.Contents(url)` triggers the dynamic-data-source error in the Service. Always: `Web.Contents(staticBase, [RelativePath = …, Query = …])`.
- The current openEHR spec uses `query_parameters` (underscore). Older drafts used `query-parameters` (hyphen). EHRbase accepts both; some vendors only accept one. Default to underscore, document the override.

---

### Task 1.4: Result-set to table conversion

**Goal:** Convert the AQL response (`{columns: [{name, path}], rows: [[...]]}`) into a clean Power BI table.

**Prerequisites:** Task 1.3 done.

**Files to modify:** `OpenEHR.pq` or `Schema.pqm`.

**Steps:**
1. Implement `ResultSetToTable(rs as record) as table` that uses `#table` with the column names from `rs[columns]`.
2. Handle empty `rows` correctly (return empty typed table, not error).
3. Handle missing/null cells consistently.
4. Initially, leave RM-object cells (those with `_type` field like `DV_QUANTITY`) as nested records — Task 1.5 will expand them.

**Code:**
```powerquery
ResultSetToTable = (rs as record) as table =>
let
    cols     = rs[columns],
    rows     = rs[rows] ?? {},
    colNames = List.Transform(cols, each [name]),
    table0   = if List.IsEmpty(rows)
               then #table(colNames, {})
               else #table(colNames, rows)
in
    table0;
```

**Acceptance criteria:**
- [ ] Calling `ResultSetToTable` on a typical AQL response returns a Power BI table with matching column names
- [ ] Empty result set returns an empty table with correct column names, not an error
- [ ] Null cells appear as `null` in Power BI, not as the string `"null"`
- [ ] Numeric cells preserve precision (no float→string→float round-trip)

**References:**
- AQL Result Set spec section: https://specifications.openehr.org/releases/QUERY/latest/AQL.html#_result_set
- AQL spec landing: https://specifications.openehr.org/releases/QUERY/latest/AQL.html
- `#table` function: https://learn.microsoft.com/en-us/powerquery-m/sharpsharptable

**Pitfalls:**
- AQL columns without an `AS` alias return as `#0`, `#1`, etc. The connector should not silently rename them; document this and recommend always aliasing in AQL.
- Result `columns` may have `path` but no `name` for some legacy implementations; fall back to `path` as column name in that case.

---

### Task 1.5: RM-object flattening

**Goal:** When an AQL cell is a Reference Model object (`DV_QUANTITY`, `DV_CODED_TEXT`, `DV_DATE_TIME`, `DV_TEXT`, `DV_BOOLEAN`, etc.), expand its key fields into sibling columns.

**Prerequisites:** Task 1.4 done.

**Files to modify:** `Schema.pqm` (extract from `OpenEHR.pq` if not already).

**Steps:**
1. Detect record-typed cells whose first sample row has a `_type` field.
2. For each known RM type, expand a defined set of fields:
   - `DV_QUANTITY` → `<col>_magnitude`, `<col>_units`, `<col>_precision`
   - `DV_CODED_TEXT` → `<col>_value`, `<col>_code`, `<col>_terminology`
   - `DV_TEXT` → `<col>_value`
   - `DV_DATE_TIME` → `<col>_value` (as datetime)
   - `DV_BOOLEAN` → `<col>_value` (as logical)
   - `DV_COUNT` → `<col>_magnitude`
   - Unknown `_type` → keep nested with a `<col>_json` text column for transparency
3. Sample the **first non-null row** for type detection (not row zero, which may be null).
4. Allow opt-out via connector option `ExpandRmObjects = false` for users who want raw JSON.

**Code (sketch):**
```powerquery
RmExpanders = [
    #"DV_QUANTITY"   = (r) => [ magnitude = r[magnitude]?, units = r[units]?,
                                precision = r[precision]? ],
    #"DV_CODED_TEXT" = (r) => [ value = r[value]?,
                                code = r[defining_code]?[code_string]?,
                                terminology = r[defining_code]?[terminology_id]?[value]? ],
    #"DV_TEXT"       = (r) => [ value = r[value]? ],
    #"DV_DATE_TIME"  = (r) => [ value = r[value]? ],
    #"DV_BOOLEAN"    = (r) => [ value = r[value]? ],
    #"DV_COUNT"      = (r) => [ magnitude = r[magnitude]? ]
];

ExpandRmColumn = (table as table, colName as text) as table =>
let
    sampleRow = List.First(
                  List.Select(Table.Column(table, colName), each _ <> null), null),
    rmType    = if sampleRow is record then sampleRow[_type]? else null,
    expander  = if rmType <> null then Record.FieldOrDefault(RmExpanders, rmType, null)
                                  else null,
    result    = if expander = null then table
                else Table.ExpandRecordColumn(
                       Table.TransformColumns(table, {{colName,
                         each if _ is record then expander(_) else null}}),
                       colName,
                       Record.FieldNames(expander(sampleRow)),
                       List.Transform(Record.FieldNames(expander(sampleRow)),
                                      each colName & "_" & _))
in
    result;
```

**Acceptance criteria:**
- [ ] AQL `SELECT o/data[at0001]/events[at0006]/data[at0003]/items[at0004]/value AS systolic FROM ... CONTAINS OBSERVATION o[openEHR-EHR-OBSERVATION.blood_pressure.v2]` returns a table with `systolic_magnitude` and `systolic_units` columns of types Number and Text
- [ ] Unknown RM types preserve the JSON in a `<col>_json` text column
- [ ] Setting `ExpandRmObjects = false` returns nested records untouched
- [ ] Mixed-type columns (some rows DV_QUANTITY, some null) handle gracefully

**References:**
- openEHR Reference Model — Data Types: https://specifications.openehr.org/releases/RM/latest/data_types.html
- AQL examples (showing object vs primitive selection): https://specifications.openehr.org/releases/QUERY/latest/AQL_examples.html
- `Table.ExpandRecordColumn`: https://learn.microsoft.com/en-us/powerquery-m/table-expandrecordcolumn

**Pitfalls:**
- Sampling row zero for type detection breaks when row zero is null. Always find first non-null.
- Field names like `_type` start with underscore and are valid M record fields, but be defensive: use `record[_type]?` (the `?` returns null instead of erroring on missing field).

---

### Task 1.6: Pagination

**Goal:** When AQL would return more than `pageSize` rows, transparently fetch all pages and return the combined table.

**Prerequisites:** Task 1.4 done.

**Files to modify:** `Paging.pqm`.

**Steps:**
1. Implement `GetAllPages(cdrBaseUrl, aql, params, pageSize)` using the lag-one `List.Generate` pattern.
2. Stop condition: the latest page returned fewer than `pageSize` rows.
3. Use `Binary.Buffer` on each response to prevent re-fetching due to lazy evaluation.
4. Default `pageSize` to 1000; allow override via connector option.

**Code:**
```powerquery
GetAllPages = (cdrBaseUrl as text, aql as text,
               params as nullable record, pageSize as number) as table =>
let
    pages = List.Generate(
        () => [off = 0,
               data = ExecuteAql(cdrBaseUrl, aql, params, 0, pageSize)],
        each List.Count(_[data][rows]) > 0,
        each [off  = _[off] + pageSize,
              data = ExecuteAql(cdrBaseUrl, aql, params,
                                _[off] + pageSize, pageSize)],
        each _[data]),
    tables   = List.Transform(pages, each ResultSetToTable(_)),
    combined = if List.IsEmpty(tables) then #table({}, {}) else Table.Combine(tables)
in
    combined;
```

**Acceptance criteria:**
- [ ] Query that returns 2,500 rows with `pageSize = 1000` makes 3 HTTP calls and returns 2,500 rows
- [ ] Query returning exactly `pageSize` rows correctly fetches a second (empty) page and stops
- [ ] Memory profile: a 50,000-row query peaks under 500 MB during refresh
- [ ] Each page request correctly carries the auth header

**References:**
- Power Query paging patterns: https://learn.microsoft.com/en-us/power-query/handling-pagingnext
- TripPin Part 5 (Paging): https://learn.microsoft.com/en-us/power-query/samples/trippin/5-paging/readme
- `List.Generate`: https://learn.microsoft.com/en-us/powerquery-m/list-generate
- `Binary.Buffer`: https://learn.microsoft.com/en-us/powerquery-m/binary-buffer

**Pitfalls:**
- The classic `List.Generate` off-by-one drops the last page. The fix is the "fetch ahead, check the previous" pattern shown above.
- Without `Binary.Buffer`, lazy evaluation may re-issue HTTP calls when columns are inspected, multiplying load on the CDR.

---

### Task 1.7: Public function API

**Goal:** Expose two well-typed entry points: `OpenEHR.Aql(...)` for ad-hoc queries and `OpenEHR.StoredQuery(...)` for executing server-side stored queries.

**Prerequisites:** Tasks 1.5, 1.6 done.

**Files to modify:** `OpenEHR.pq`.

**Code:**
```powerquery
[DataSource.Kind="OpenEHR"]
shared OpenEHR.Aql = Value.ReplaceType(OpenEHR.AqlImpl, OpenEHR.AqlType);

OpenEHR.AqlType = type function (
    cdrBaseUrl as (Uri.Type meta [
        Documentation.FieldCaption = "CDR base URL",
        Documentation.SampleValues = {"https://ehrbase.example.org/ehrbase/rest/openehr/v1"}
    ]),
    aql as (type text meta [
        Documentation.FieldCaption = "AQL query",
        Documentation.SampleValues = {"SELECT c/uid/value FROM EHR e CONTAINS COMPOSITION c LIMIT 10"},
        Formatting.IsMultiLine = true,
        Formatting.IsCode = true
    ]),
    optional parameters as (type record meta [
        Documentation.FieldCaption = "Query parameters",
        Documentation.LongDescription = "Record mapping AQL $-named parameters to values."
    ]),
    optional options as (type [
        optional PageSize        = number,
        optional ExpandRmObjects = logical,
        optional Timeout         = duration
    ])
) as table;

OpenEHR.AqlImpl = (cdrBaseUrl as text, aql as text,
                   optional parameters as nullable record,
                   optional options as nullable record) as table =>
let
    pageSize = (options ?? [])[PageSize]?  ?? 1000,
    expand   = (options ?? [])[ExpandRmObjects]? ?? true,
    raw      = GetAllPages(cdrBaseUrl, aql, parameters, pageSize),
    typed    = if expand then ExpandAllRmColumns(raw) else raw
in
    typed;

[DataSource.Kind="OpenEHR"]
shared OpenEHR.StoredQuery = (cdrBaseUrl as text, qualifiedName as text,
                              optional version as nullable text,
                              optional parameters as nullable record,
                              optional options as nullable record) as table =>
    // POST /query/{qualified_query_name}[/{version}]
    ...
```

**Acceptance criteria:**
- [ ] `OpenEHR.Aql` shows up in the Power Query function picker with proper field captions
- [ ] AQL field renders as a multi-line code-formatted box
- [ ] `OpenEHR.StoredQuery` correctly POSTs to `/query/{qname}` and `/query/{qname}/{version}`
- [ ] Both functions return tables compatible with downstream Power Query transforms

**References:**
- `Value.ReplaceType` and metadata documentation: https://learn.microsoft.com/en-us/power-query/handling-documentation
- TripPin Part 4 (Paths): https://learn.microsoft.com/en-us/power-query/samples/trippin/4-paths/readme
- openEHR REST stored query execution: https://specifications.openehr.org/releases/ITS-REST/latest/query.html#_execute_stored_query

**Pitfalls:**
- Field metadata (`Documentation.FieldCaption`, `Formatting.IsMultiLine`) only applies if you wrap with `Value.ReplaceType`. Without it, users see raw parameter names.

---

### Task 1.8: Navigation table

**Goal:** When the user picks "openEHR" from Get Data, they see a navigator with **Ad-hoc AQL**, **Stored Queries**, **Templates**, and **EHRs** entries.

**Prerequisites:** Task 1.7 done.

**Files to modify:** `Navigation.pqm`, `OpenEHR.pq`.

**Steps:**
1. Implement the `Table.ToNavigationTable` helper from the Microsoft docs (it's not built in — copy verbatim).
2. Replace the body of `OpenEHR.Contents` to return a navigation table.
3. Top level: `Ad-hoc AQL` (function leaf), `Stored Queries` (folder), `Templates` (folder), `EHRs` (table leaf).
4. `Stored Queries` lazily loads from `GET /definition/query/`.
5. Use `Table.AddColumn` (lazy), not `Table.TransformRows` (eager), or every child fetches on expand.

**Code (Table.ToNavigationTable helper, from Microsoft docs):**
```powerquery
Table.ToNavigationTable = (
    table        as table,
    keyColumns   as list,
    nameColumn   as text,
    dataColumn   as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
let
    tableType    = Value.Type(table),
    newTableType = Type.AddTableKey(tableType, keyColumns, true) meta [
        NavigationTable.NameColumn     = nameColumn,
        NavigationTable.DataColumn     = dataColumn,
        NavigationTable.ItemKindColumn = itemKindColumn,
        Preview.DelayColumn            = itemNameColumn,
        NavigationTable.IsLeafColumn   = isLeafColumn
    ],
    navigationTable = Value.ReplaceType(table, newTableType)
in
    navigationTable;
```

**Acceptance criteria:**
- [ ] Get Data → openEHR (Beta) → Connect → enter base URL → see a navigation tree
- [ ] Top-level shows the four entries with appropriate icons (Function vs Folder vs Table)
- [ ] Expanding "Stored Queries" lists what `GET /definition/query/` returns
- [ ] Selecting "EHRs" returns a paginated EHR-id table
- [ ] No HTTP calls fire on navigation tree expansion that aren't strictly needed (verify in Fiddler)

**References:**
- TripPin Part 3 (Navigation Tables): https://learn.microsoft.com/en-us/power-query/samples/trippin/3-navtables/readme
- Navigation table reference: https://learn.microsoft.com/en-us/power-query/handling-navigation-tables
- openEHR Definition API: https://specifications.openehr.org/releases/ITS-REST/latest/definition.html

**Pitfalls:**
- Using `Table.TransformRows` to build child entries triggers eager evaluation: every node fetches data even if not expanded. Use `Table.AddColumn` so the child column is lazy.

---

### Task 1.9: `TestConnection` for gateway refresh

**Goal:** The Power BI Service can use the on-prem gateway to refresh datasets backed by this connector.

**Prerequisites:** Task 1.8 done.

**Files to modify:** `OpenEHR.pq`.

**Steps:**
1. Implement `TestConnection` returning a list: `{ "OpenEHR.Contents", cdrBaseUrl }`.
2. The first element is the function name; subsequent are the required parameters.
3. Manually test in the on-prem gateway by publishing a sample `.pbix` and triggering a Service refresh.

**Code:**
```powerquery
OpenEHR = [
    TestConnection = (dataSourcePath) =>
        let
            json = Json.Document(dataSourcePath),
            url  = json[cdrBaseUrl]
        in
            { "OpenEHR.Contents", url },
    Authentication = [
        UsernamePassword = [],
        Anonymous = []
    ],
    Label = Extension.LoadString("DataSourceLabel")
];
```

**Acceptance criteria:**
- [ ] Publishing a `.pbix` to the Power BI Service, configuring credentials in the dataset settings, and triggering a refresh succeeds
- [ ] Scheduled refresh (set to every 6 hours) runs at least twice consecutively without intervention
- [ ] Refresh history in the Power BI Service shows green checkmarks

**References:**
- Test Connection docs: https://learn.microsoft.com/en-us/power-query/handling-gateway-support
- Custom connectors with the gateway: https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-custom-connectors

**Pitfalls:**
- This is the single most common cause of "works in Desktop, broken in Service." Test refresh in the Service before tagging any release.
- Custom connectors are not supported on the **VNet** data gateway — only on-prem. Document this clearly.

---

### Task 1.10: Sandbox testing

**Goal:** The connector works against the public EHRbase sandbox without modification.

**Prerequisites:** Task 1.9 done.

**Steps:**
1. Connect Power BI Desktop to the EHRbase sandbox at https://sandkiste.ehrbase.org/ehrbase/rest/openehr/v1 (credentials from EHRbase docs).
2. Run all 5 canonical AQL queries (define them in `tests/fixtures/canonical-queries.json`):
   - Composition count by template
   - Latest blood pressure per EHR
   - Lab results by date range
   - Demographics summary
   - Stored query execution
3. Document any sandbox-specific quirks in `docs/cookbook/cdr-vendor-notes/ehrbase.md`.

**Acceptance criteria:**
- [ ] All 5 queries return non-empty results (or correctly return empty if sandbox lacks the data)
- [ ] No HTTP errors or connector exceptions across all queries
- [ ] Data types in the resulting tables are correct (numbers stay numbers, dates stay dates)

**References:**
- EHRbase sandbox info: https://sandkiste.ehrbase.org
- EHRbase docs — AQL: https://docs.ehrbase.org/docs/EHRbase/Explore/AQL/Introduction

---

### Task 1.11: CI pipeline

**Goal:** Every PR runs lint, build, and integration tests against a Docker-spawned EHRbase.

**Prerequisites:** Tasks 1.1–1.10 done.

**Files to create under `.github/workflows/`:**
- `ci.yml` — runs on PR and push to `main`. Steps: checkout → setup .NET → install MakePQX → spin up EHRbase via docker-compose → load seed data → build connector → run M unit tests → run integration tests against the spun-up EHRbase
- `codeql.yml` — GitHub's free CodeQL scan on PowerShell helper scripts

**Acceptance criteria:**
- [ ] PR triggers `ci.yml`, completes within 10 minutes
- [ ] Failing test fails the workflow (validate by intentionally breaking a test)
- [ ] CI badge appears in README

**References:**
- GitHub Actions for .NET: https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-net
- Docker in GitHub Actions: https://docs.github.com/en/actions/using-containerized-services/about-service-containers
- MakePQX CLI: https://learn.microsoft.com/en-us/power-query/install-sdk#installing-the-power-query-sdk-for-visual-studio-code

**Pitfalls:**
- EHRbase + Postgres in CI takes ~45 seconds to be query-ready. Add a healthcheck loop, not a fixed sleep.

---

### Task 1.12: Code signing and release pipeline

**Goal:** Tagging `vX.Y.Z` produces a signed `.pqx` attached to a GitHub Release.

**Prerequisites:** Code-signing certificate purchased (Sectigo, DigiCert, or SSL.com — budget USD 300–600/yr).

**Files to create:**
- `.github/workflows/release.yml` — runs on tag matching `v*`. Steps: build → import cert from secret → `MakePQX sign` → generate changelog from conventional commits → create Release → attach `.pqx`

**GitHub Secrets required:**
- `CODE_SIGN_CERT_PFX_BASE64` — base64-encoded `.pfx` file
- `CODE_SIGN_CERT_PASSWORD` — `.pfx` password

**Steps:**
1. Buy a code-signing cert (EV recommended for SmartScreen reputation, but standard works for GPO trust).
2. Convert `.pfx` to base64: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("cert.pfx"))`
3. Add as GitHub Secret.
4. Write workflow that decodes, imports, signs, releases.
5. Tag `v0.0.1-alpha` and verify a signed artifact appears.

**Acceptance criteria:**
- [ ] `git tag v0.0.1-alpha && git push --tags` triggers `release.yml`
- [ ] GitHub Release is created with auto-generated notes
- [ ] The attached `.pqx` is signed (verify with `Get-AuthenticodeSignature` in PowerShell)
- [ ] Installing the signed `.pqx` on a clean Windows machine via the GPO trust path works without lowering security settings

**References:**
- MakePQX sign: https://learn.microsoft.com/en-us/power-query/install-sdk#installing-the-power-query-sdk-for-visual-studio-code
- Trusted Third-Party Connectors GPO: https://learn.microsoft.com/en-us/power-bi/admin/desktop-trusted-third-party-connectors
- GitHub Actions secrets: https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions
- Conventional Changelog: https://github.com/conventional-changelog/conventional-changelog

**Pitfalls:**
- A `.pfx` without a private key is unusable. Verify before uploading.
- SmartScreen reputation builds over months; first downloads may show warnings even with a valid signature.

---

### Task 1.13: Documentation pages — actual content

**Goal:** All Phase 1 docs pages are written, not placeholders.

**Prerequisites:** Tasks 1.1–1.12 done.

**Pages to fill (replacing Task 0.5 placeholders):**
- `docs/index.md` — what + why + 60-second install
- `docs/getting-started/install-end-user.md` — for analysts on a corporate Windows machine
- `docs/getting-started/install-gateway-admin.md` — for IT, gateway admin specifically
- `docs/getting-started/install-uncertified.md` — evaluation path
- `docs/getting-started/install-signed-cert.md` — enterprise GPO path with the registry key paths and PowerShell snippets
- `docs/auth/basic.md` — username/password setup
- `docs/cookbook/blood-pressure-trend.md` — full end-to-end recipe with screenshots
- `docs/cookbook/cdr-vendor-notes/ehrbase.md` — every quirk found during Task 1.10
- `docs/reference/functions.md` — `OpenEHR.Aql`, `OpenEHR.StoredQuery` API ref
- `docs/reference/options.md` — every connector option documented
- `docs/reference/error-codes.md` — every error category emitted
- `docs/troubleshooting.md` — top 10 issues anticipated, plus how to read `mashup-trace.json`
- `.github/workflows/spec-link-check.yml` — runs weekly, reports broken external links

**Acceptance criteria:**
- [ ] All listed pages render on the docs site
- [ ] Screenshots embedded and load correctly
- [ ] Internal cross-links work
- [ ] Spec-link-check workflow passes

**References:**
- Microsoft trusted connectors registry: https://learn.microsoft.com/en-us/power-bi/admin/desktop-trusted-third-party-connectors
- Mashup tracing: https://learn.microsoft.com/en-us/power-query/handlingdiagnostics

---

### Task 1.14: Sample dashboards

**Goal:** Three reproducible `.pbix` files demonstrating real value.

**Prerequisites:** Tasks 1.10, 1.13 done.

**Files to create under `dev/sample-pbix/`:**
- `01-blood-pressure-trend.pbix` — line chart of systolic/diastolic over time per patient, with a slicer
- `02-lab-panel.pbix` — matrix of lab values with reference range conditional formatting
- `03-demographics-dashboard.pbix` — KPIs: total EHRs, age distribution, gender split

**Steps:**
1. Build each report against local EHRbase seed data.
2. Verify each refreshes cleanly.
3. Commit `.pbix` files (small enough to commit; document their AQL queries in `dev/sample-pbix/README.md`).
4. Embed screenshots in docs.

**Acceptance criteria:**
- [ ] All three `.pbix` files open in Power BI Desktop
- [ ] All three refresh against local EHRbase without errors
- [ ] Each report's AQL is documented in companion markdown

**References:**
- Power BI Desktop best practices: https://learn.microsoft.com/en-us/power-bi/create-reports/desktop-tips-and-tricks-for-creating-reports
- DAX Guide: https://dax.guide/

---

### Task 1.15: v0.1.0 release and public launch

**Goal:** v0.1.0 is published and announced; first external users discover the connector.

**Prerequisites:** All Phase 1 tasks done.

**Steps:**
1. Verify all acceptance criteria from Tasks 1.1–1.14.
2. Update `CHANGELOG.md` with v0.1.0 entry.
3. `git tag v0.1.0 && git push --tags`. Verify release pipeline produces signed `.pqx`.
4. Record a 5–10 minute demo video (Loom or YouTube).
5. Publish announcement posts:
   - openEHR Discourse: https://discourse.openehr.org/
   - LinkedIn openEHR Clinical Modelling group
   - r/PowerBI and r/healthIT on Reddit
   - Microsoft Fabric Ideas thread (start it now if you didn't earlier)
6. Submit to community lists:
   - https://github.com/NoUnique/awesome-power-bi (or current canonical "awesome" list)
   - Any "awesome openEHR" lists

**Acceptance criteria:**
- [ ] v0.1.0 GitHub Release exists with signed `.pqx`
- [ ] Demo video is public and embedded in README
- [ ] At least one external user has installed it (track via GitHub stars, Discourse replies)
- [ ] Microsoft Fabric Ideas thread has at least one upvote (yours counts)

**References:**
- openEHR Discourse: https://discourse.openehr.org/
- Microsoft Fabric Ideas: https://ideas.fabric.microsoft.com/

---

## Phase 2 — Production-Ready

**Phase goal:** OAuth2 (PKCE + Client Credentials), stored query browser, incremental refresh recipes, PHI-safe mode, multi-vendor compatibility tested. v1.0.0.

---

### Task 2.1: OAuth2 Authorization Code + PKCE

**Goal:** The connector supports OAuth2 for CDRs behind Keycloak, Okta, Auth0, or any OIDC IdP.

**Prerequisites:** Phase 1 complete.

**Files to modify:** `OpenEHR.pq`, `Auth.pqm`.

**Steps:**
1. Add `OAuth = [StartLogin, FinishLogin, Refresh, Logout]` to the `Authentication` record.
2. Implement PKCE (S256 code challenge).
3. Persist `verifier` in the OAuth context record so `FinishLogin` can use it.
4. Always pass `state` through `StartLogin` (Service refresh requires it).
5. Test end-to-end against the local Keycloak realm (loaded by docker-compose in Phase 0).
6. Document setup in `docs/auth/oauth-pkce.md`.

**Code:** See the OAuth2 PKCE section in the original deep research; reference the canonical sample at https://github.com/microsoft/DataConnectors/tree/master/samples/OAuthPKCE

**Acceptance criteria:**
- [ ] First connect launches the IdP login window
- [ ] Successful login returns to Power BI Desktop, queries work
- [ ] Refresh token exchange works (test by waiting for access token expiry, then refreshing)
- [ ] Service-side scheduled refresh works without re-prompting

**References:**
- OAuth2 PKCE sample: https://github.com/microsoft/DataConnectors/tree/master/samples/OAuthPKCE
- Power Query OAuth handling: https://learn.microsoft.com/en-us/power-query/handling-authentication#oauth-and-power-bi
- SMART on openEHR (emerging standard): https://specifications.openehr.org/releases/ITS-REST/development/smart_app_launch.html
- Keycloak admin: https://www.keycloak.org/documentation
- RFC 7636 (PKCE): https://datatracker.ietf.org/doc/html/rfc7636

**Pitfalls:**
- Forgetting to thread `state` through `StartLogin` is the #1 cause of OAuth working in Desktop but failing in the Service. The Microsoft FAQ documents this: https://learn.microsoft.com/en-us/power-query/custom-connector-development-faq
- Never embed a client secret in a connector — Power Query is client-side. Use PKCE.

---

### Task 2.2: OAuth2 Client Credentials

**Goal:** Service-account ETL scenarios can authenticate without an interactive flow.

**Prerequisites:** Task 2.1 done.

**Files to modify:** `Auth.pqm`.

**Steps:**
1. Add a `Key` authentication kind that accepts a bearer token directly (escape hatch).
2. Add a service-credentials option that takes `client_id` + `client_secret` and exchanges them at the token endpoint.
3. Cache the access token until expiry.

**Acceptance criteria:**
- [ ] Headless refresh works without user interaction
- [ ] Token rotation is transparent
- [ ] Documented in `docs/auth/client-credentials.md`

**References:**
- RFC 6749 Client Credentials: https://datatracker.ietf.org/doc/html/rfc6749#section-4.4
- Custom connector FAQ — Auth: https://learn.microsoft.com/en-us/power-query/custom-connector-development-faq

---

### Task 2.3: Stored query browser

**Goal:** The navigation table's "Stored Queries" folder lists all server-side stored queries with their parameters.

**Prerequisites:** Task 1.8 done.

**Files to modify:** `Navigation.pqm`.

**Steps:**
1. Call `GET /definition/query/` to list queries.
2. For each, expose a child node that, when selected, prompts for query parameters and executes via `POST /query/{name}/{version}`.
3. Cache the query list per session.

**Acceptance criteria:**
- [ ] Stored queries appear in navigator
- [ ] Selecting one prompts for any required parameters
- [ ] Execution returns the same shape as `OpenEHR.Aql`

**References:**
- Definition API — list queries: https://specifications.openehr.org/releases/ITS-REST/latest/definition.html#_query_definitions

---

### Task 2.4: Incremental refresh recipes

**Goal:** Document and verify that Power BI's Incremental Refresh feature works with this connector when AQL is parameterized on `c/context/start_time/value`.

**Prerequisites:** Task 1.10 done.

**Files to create:**
- `docs/cookbook/incremental-refresh.md` — full walkthrough
- `dev/sample-pbix/04-incremental-bp.pbix` — sample using IR

**Steps:**
1. In Power Query, define `RangeStart` and `RangeEnd` parameters of type `DateTime`.
2. Translate them to AQL: `WHERE c/context/start_time/value >= $from AND c/context/start_time/value < $to`.
3. Pass via `query_parameters`: `[from = DateTime.ToText(RangeStart, "yyyy-MM-ddTHH:mm:ss"), to = ...]`.
4. In Power BI Desktop, set up Incremental Refresh: keep N years, refresh last M days.
5. Publish, verify the Service partitions correctly.

**Acceptance criteria:**
- [ ] Initial load partitions historical data correctly
- [ ] Subsequent refresh only fetches the recent partition
- [ ] Verify partition counts via SSMS XMLA endpoint

**References:**
- Incremental refresh docs: https://learn.microsoft.com/en-us/power-bi/connect-data/incremental-refresh-overview
- Configuring incremental refresh: https://learn.microsoft.com/en-us/power-bi/connect-data/incremental-refresh-configure
- Query folding for IR: https://learn.microsoft.com/en-us/power-query/power-query-folding

---

### Task 2.5: PHI-safe mode

**Goal:** A single connector option that enforces all PHI-safety guardrails at once.

**Prerequisites:** Phase 1 done.

**Files to modify:** `OpenEHR.pq`.

**Steps:**
1. Add option `PhiSafeMode = true | false`.
2. When true: refuse Basic Auth over non-TLS, force `DiagnosticLevel = 0`, inject `X-Audit-Context: <hash>` on every request, refuse to log row data anywhere.
3. Document in `docs/compliance/phi-safe-mode.md`.

**Acceptance criteria:**
- [ ] Connecting to `http://` (non-TLS) with `PhiSafeMode = true` and Basic auth raises a clear error
- [ ] Diagnostics output contains zero row values when enabled
- [ ] Audit header is present on all requests

**References:**
- HIPAA on Microsoft Cloud: https://learn.microsoft.com/en-us/compliance/regulatory/offering-hipaa-hitech
- GDPR overview for healthcare: https://gdpr.eu/

---

### Task 2.6: Cache key hardening

**Goal:** Prevent rotating bearer tokens from poisoning the `Web.Contents` cache.

**Prerequisites:** Task 2.1 done.

**Files to modify:** `Aql.pqm`.

**Code change:**
```powerquery
response = Web.Contents(cdrBaseUrl, [
    RelativePath = "query/aql",
    Headers = headers,
    Content = body,
    ManualStatusHandling = { ... },
    ExcludedFromCacheKey = { "Authorization", "X-Audit-Context" }
])
```

**Acceptance criteria:**
- [ ] Repeated identical AQL with rotated tokens reuses cache as expected
- [ ] No tokens persist in cache after expiry

**References:**
- `Web.Contents` options: https://learn.microsoft.com/en-us/powerquery-m/web-contents
- Caching considerations: https://learn.microsoft.com/en-us/power-query/web-connection

---

### Task 2.7: Multi-vendor test matrix

**Goal:** Verified compatibility against EHRbase, Better Platform, and at least one of Code24/DIPS.

**Prerequisites:** Phase 1 done.

**Steps:**
1. Obtain sandbox credentials from each vendor (request via vendor sales / community channels).
2. Run the canonical 5-query suite against each.
3. File `cdr_compatibility.yml` issues for each, with results.
4. Update `docs/cookbook/cdr-vendor-notes/<vendor>.md`.

**Acceptance criteria:**
- [ ] EHRbase: full pass
- [ ] Better Platform: full pass or documented exceptions
- [ ] One of Code24/DIPS: tested with documented results
- [ ] Compatibility matrix published in docs

**References:**
- EHRbase: https://github.com/ehrbase/ehrbase
- Better Platform: https://platform.better.care/
- Code24: https://www.code-24.com/
- DIPS: https://www.dips.com/

---

### Task 2.8: v1.0.0 release

**Goal:** v1.0.0 published with full Phase 2 feature set.

**Prerequisites:** Tasks 2.1–2.7 done.

**Steps:** Tag, release, publish 3 blog posts (PBI+EHRbase intro, OAuth setup, IR walkthrough), refresh Discourse announcement, update Fabric Ideas thread.

**Acceptance criteria:**
- [ ] v1.0.0 release on GitHub
- [ ] Three blog posts published
- [ ] Compliance one-pager published

---

## Phase 3 — Scale & Ecosystem

**Phase goal:** Entra ID auth, template-aware flattening, Fabric/OneLake landing pipeline, Microsoft certification submission.

---

### Task 3.1: Entra ID (`Aad`) authentication

**Goal:** CDRs behind Microsoft identity authenticate without per-tenant OAuth setup.

**Prerequisites:** Phase 2 done.

**Steps:** Add `Aad = [AuthorizationUri, Resource, Scope]` to the `Authentication` record. Document tenant configuration. Test against an Azure-hosted CDR.

**References:**
- Entra ID auth in Power Query: https://learn.microsoft.com/en-us/power-query/handling-authentication#azure-active-directory-authentication
- Microsoft identity platform: https://learn.microsoft.com/en-us/entra/identity-platform/

---

### Task 3.2: Template-aware flattening

**Goal:** Reading `/definition/template/{id}` lets the connector auto-generate "tidy" Power BI tables matching the template.

**Prerequisites:** Phase 2 done.

**Steps:** Implement `OpenEHR.TemplateAsTable(cdrBaseUrl, templateId, optional ehrFilter)` that introspects the template and returns one row per composition with named columns matching the template's leaves.

**References:**
- Definition API — templates: https://specifications.openehr.org/releases/ITS-REST/latest/definition.html#_templates
- openEHR Operational Templates: https://specifications.openehr.org/releases/AM/latest/OPT.html

---

### Task 3.3: Fabric / OneLake landing pipeline

**Goal:** Reference architecture: AQL → Parquet → Fabric Lakehouse, mirroring the FHIR analytics pipeline pattern.

**Prerequisites:** Task 3.1 done.

**Files to create:** `dev/fabric-pipeline/` with notebook + pipeline JSON.

**References:**
- Microsoft FHIR Analytics Pipelines (architectural reference): https://github.com/microsoft/FHIR-Analytics-Pipelines
- Microsoft Fabric Lakehouse: https://learn.microsoft.com/en-us/fabric/data-engineering/lakehouse-overview
- Fabric pipelines: https://learn.microsoft.com/en-us/fabric/data-factory/data-factory-overview

---

### Task 3.4: Optional self-hosted proxy container

**Goal:** Enterprises that want federation, caching, or cross-cutting transforms inside their own boundary get a Docker container.

**Prerequisites:** Phase 2 done.

**Files to create:** `proxy/` directory with a small ASP.NET Core or Node.js service that exposes the same endpoints, plus federation/cache logic.

**References:**
- Reverse proxy patterns: https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/yarp/yarp-overview

---

### Task 3.5: Microsoft certification submission

**Goal:** Submit when the program reopens.

**Prerequisites:** All Phase 2 done, accumulated Fabric Ideas votes.

**Steps:** Monitor https://learn.microsoft.com/en-us/power-query/connector-certification for program reopening. When open: complete the submission form, provide demo video, sample data, signed connector, test plan.

**References:**
- Connector certification: https://learn.microsoft.com/en-us/power-query/connector-certification
- Certification submission process: https://learn.microsoft.com/en-us/power-query/certification-submission

---

## Phase 4 — Commercial Tier (Optional)

**Phase goal:** Open-source core stays free; commercial overlay adds vendor-certified compatibility, support SLAs, and pre-built dashboard packs.

Defer planning until Phase 3 ships and there's evidence of adoption demand. Tasks not enumerated here.

---

## Appendix A — Sources

### openEHR specifications
- AQL specification (current): https://specifications.openehr.org/releases/QUERY/latest/AQL.html
- AQL examples: https://specifications.openehr.org/releases/QUERY/latest/AQL_examples.html
- AQL specs repo: https://github.com/openEHR/specifications-QUERY
- REST Query API: https://specifications.openehr.org/releases/ITS-REST/latest/query.html
- REST Definition API: https://specifications.openehr.org/releases/ITS-REST/latest/definition.html
- REST EHR API: https://specifications.openehr.org/releases/ITS-REST/latest/ehr.html
- REST API overview: https://specifications.openehr.org/releases/ITS-REST/latest/overview.html
- SMART on openEHR (draft): https://specifications.openehr.org/releases/ITS-REST/development/smart_app_launch.html
- Reference Model — Data Types: https://specifications.openehr.org/releases/RM/latest/data_types.html
- Operational Templates: https://specifications.openehr.org/releases/AM/latest/OPT.html
- All openEHR specifications: https://specifications.openehr.org/

### openEHR community and tooling
- openEHR Foundation: https://www.openehr.org/
- openEHR Discourse forum: https://discourse.openehr.org/
- openEHR Clinical Knowledge Manager (CKM): https://ckm.openehr.org/ckm/
- Better Academy (free training): https://academy.better.care/
- DIPSAS openehpy (Python): https://github.com/DIPSAS/openehpy

### CDR vendors
- EHRbase repo: https://github.com/ehrbase/ehrbase
- EHRbase docs: https://docs.ehrbase.org/
- EHRbase Docker image: https://hub.docker.com/r/ehrbase/ehrbase
- EHRbase public sandbox: https://sandkiste.ehrbase.org
- Better Platform: https://platform.better.care/
- Better docs: https://docs.better.care/
- Code24: https://www.code-24.com/
- DIPS: https://www.dips.com/
- Cabolabs: https://cabolabs.com/

### Power BI / Power Query — Microsoft official
- Power Query M reference: https://learn.microsoft.com/en-us/powerquery-m/
- Power Query SDK install: https://learn.microsoft.com/en-us/power-query/install-sdk
- VS Code Power Query SDK repo: https://github.com/microsoft/vscode-powerquery-sdk
- Connector Extensibility overview: https://learn.microsoft.com/en-us/power-bi/connect-data/desktop-connector-extensibility
- Custom connector FAQ: https://learn.microsoft.com/en-us/power-query/custom-connector-development-faq
- Authentication handling: https://learn.microsoft.com/en-us/power-query/handling-authentication
- Documentation metadata: https://learn.microsoft.com/en-us/power-query/handling-documentation
- Navigation tables: https://learn.microsoft.com/en-us/power-query/handling-navigation-tables
- Paging patterns: https://learn.microsoft.com/en-us/power-query/handling-pagingnext
- Wait/retry: https://learn.microsoft.com/en-us/power-query/wait-retry
- Resource path: https://learn.microsoft.com/en-us/power-query/handling-resource-path
- Gateway support: https://learn.microsoft.com/en-us/power-query/handling-gateway-support
- Custom connectors with on-prem gateway: https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-custom-connectors
- Trusted Third-Party Connectors GPO: https://learn.microsoft.com/en-us/power-bi/admin/desktop-trusted-third-party-connectors
- Connector certification: https://learn.microsoft.com/en-us/power-query/connector-certification
- Certification submission: https://learn.microsoft.com/en-us/power-query/certification-submission
- Diagnostics tracing: https://learn.microsoft.com/en-us/power-query/handlingdiagnostics
- Power BI Incremental refresh: https://learn.microsoft.com/en-us/power-bi/connect-data/incremental-refresh-overview
- Microsoft Fabric Ideas: https://ideas.fabric.microsoft.com/

### Power Query M sample connectors
- DataConnectors repo (root): https://github.com/microsoft/DataConnectors
- TripPin tutorial (10 parts): https://learn.microsoft.com/en-us/power-query/samples/trippin/readme
- TripPin Part 1 (OData): https://learn.microsoft.com/en-us/power-query/samples/trippin/1-odata/readme
- TripPin Part 2 (REST): https://learn.microsoft.com/en-us/power-query/samples/trippin/2-rest/readme
- TripPin Part 3 (Nav Tables): https://learn.microsoft.com/en-us/power-query/samples/trippin/3-navtables/readme
- TripPin Part 4 (Paths): https://learn.microsoft.com/en-us/power-query/samples/trippin/4-paths/readme
- TripPin Part 5 (Paging): https://learn.microsoft.com/en-us/power-query/samples/trippin/5-paging/readme
- GitHub OAuth sample: https://learn.microsoft.com/en-us/power-query/samples/github/readme
- OAuth2 PKCE sample: https://github.com/microsoft/DataConnectors/tree/master/samples/OAuthPKCE
- FHIR connector (closest healthcare analogue): https://learn.microsoft.com/en-us/power-query/connectors/fhir/fhir
- FHIR Analytics Pipelines (reference architecture): https://github.com/microsoft/FHIR-Analytics-Pipelines

### Power Query M learning
- Ben Gribaudo M Primer (free, comprehensive): https://bengribaudo.com/blog/2017/10/19/4346/power-query-m-primer-part1-introduction-simple-expressions-let
- Chris Webb's BI Blog: https://blog.crossjoin.co.uk/category/power-query/
- Curbal YouTube: https://www.youtube.com/c/CurbalEN
- Reza Rad's RADACAD: https://radacad.com/

### DAX learning
- DAX Guide: https://dax.guide/
- SQLBI YouTube: https://www.youtube.com/c/sqlbi

### Standards and protocols
- OAuth 2.0 (RFC 6749): https://datatracker.ietf.org/doc/html/rfc6749
- PKCE (RFC 7636): https://datatracker.ietf.org/doc/html/rfc7636
- OpenID Connect: https://openid.net/specs/openid-connect-core-1_0.html
- HTTP Problem Details (RFC 7807): https://datatracker.ietf.org/doc/html/rfc7807

### Compliance
- HIPAA on Microsoft Cloud: https://learn.microsoft.com/en-us/compliance/regulatory/offering-hipaa-hitech
- Microsoft Service Trust Portal: https://servicetrust.microsoft.com/
- GDPR for healthcare: https://gdpr.eu/

### GitHub project conventions
- Conventional Commits: https://www.conventionalcommits.org/en/v1.0.0/
- Keep a Changelog: https://keepachangelog.com/en/1.1.0/
- Contributor Covenant: https://www.contributor-covenant.org/version/2/1/code_of_conduct/
- Issue forms: https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/configuring-issue-templates-for-your-repository
- CODEOWNERS: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
- Dependabot: https://docs.github.com/en/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file
- GitHub Pages: https://docs.github.com/en/pages/quickstart
- GitHub Actions for .NET: https://docs.github.com/en/actions/automating-builds-and-tests/building-and-testing-net

### Documentation tooling
- MkDocs Material: https://squidfunk.github.io/mkdocs-material/
- MkDocs gh-pages deployment: https://squidfunk.github.io/mkdocs-material/publishing-your-site/

### Claude
- Claude Code overview: https://docs.claude.com/en/docs/claude-code/overview
- Claude Code memory (CLAUDE.md): https://docs.claude.com/en/docs/claude-code/memory
- Claude Code slash commands: https://docs.claude.com/en/docs/claude-code/slash-commands
- Claude Code settings: https://docs.claude.com/en/docs/claude-code/settings
- Anthropic API docs: https://docs.claude.com/en/api

---

## Appendix B — Status tracker template

Copy this into a GitHub Project board or `STATUS.md` to track execution.

```
Phase 0 — Foundation Setup
  [ ] 0.1  Repository scaffolding and root files
  [ ] 0.2  GitHub repository automation files
  [ ] 0.3  Local development tooling
  [ ] 0.4  EHRbase local CDR
  [ ] 0.5  Documentation site (MkDocs Material)
  [ ] 0.6  Claude Code configuration

Phase 1 — MVP Connector
  [ ] 1.1  Hello-world connector skeleton
  [ ] 1.2  Basic Auth implementation
  [ ] 1.3  AQL execution via POST /query/aql
  [ ] 1.4  Result-set to table conversion
  [ ] 1.5  RM-object flattening
  [ ] 1.6  Pagination
  [ ] 1.7  Public function API
  [ ] 1.8  Navigation table
  [ ] 1.9  TestConnection for gateway refresh
  [ ] 1.10 Sandbox testing
  [ ] 1.11 CI pipeline
  [ ] 1.12 Code signing and release pipeline
  [ ] 1.13 Documentation pages — actual content
  [ ] 1.14 Sample dashboards
  [ ] 1.15 v0.1.0 release and public launch

Phase 2 — Production-Ready
  [ ] 2.1  OAuth2 Authorization Code + PKCE
  [ ] 2.2  OAuth2 Client Credentials
  [ ] 2.3  Stored query browser
  [ ] 2.4  Incremental refresh recipes
  [ ] 2.5  PHI-safe mode
  [ ] 2.6  Cache key hardening
  [ ] 2.7  Multi-vendor test matrix
  [ ] 2.8  v1.0.0 release

Phase 3 — Scale & Ecosystem
  [ ] 3.1  Entra ID (Aad) authentication
  [ ] 3.2  Template-aware flattening
  [ ] 3.3  Fabric / OneLake landing pipeline
  [ ] 3.4  Optional self-hosted proxy container
  [ ] 3.5  Microsoft certification submission

Phase 4 — Commercial Tier
  (To be planned at end of Phase 3)
```

---

## Appendix C — Quick-start prompt for Claude Code

When opening Claude Code in the repo for the first time, paste this:

> "Read `IMPLEMENTATION_PLAN.md` and `CLAUDE.md`. The current task is **Task X.Y** (replace with actual ID). My current state: [describe]. Confirm you understand the task, the prerequisites, and the acceptance criteria. Then propose your first step. Wait for my approval before making any file changes."

This grounds Claude in the plan, prevents drift, and forces explicit acceptance-criteria thinking before code is written.
