# Dev environment

Quick-start for contributors. Full contribution policy lives in [CONTRIBUTING.md](https://github.com/rubentalstra/openehr-aql/blob/main/CONTRIBUTING.md).

## Platform layout

```mermaid
flowchart LR
    subgraph Dev host — macOS or Linux
      ED[Editor:<br/>VS Code / JetBrains] --> PQ["src/*.pq / *.pqm"]
      DC[Docker compose] --> PG[(Postgres 16)]
      DC --> EHR[EHRbase 2.x]
      MK[mkdocs serve] --> DOCS[docs/ preview]
    end
    subgraph CI — windows-latest
      DOT[Power Query SDK Tools] --> MPQX[src/ → MakePQX compile + sign]
      MPQX --> ART[OpenEHR.pqx]
    end
    ED -.push.-> CI[GitHub Actions]
    CI --> DOT
```

The Power Query SDK build only runs on **Windows**, so CI is the source of truth for `.pqx` builds. Locally, you edit + test logic via `mkdocs serve` and `docker compose`, then let CI produce a signed artifact.

## One-time setup (macOS / Linux)

```bash
# 1. Clone
git clone https://github.com/rubentalstra/powerbi-openehr-aql.git
cd powerbi-openehr-aql

# 2. Start the local CDR
(cd dev && cp -n .env.example .env && docker compose up -d)
bash dev/scripts/check-health.sh
bash dev/scripts/load-seed.sh

# 3. Docs preview
python -m venv .venv && source .venv/bin/activate
pip install -r docs/requirements.txt
mkdocs serve
```

Services:

| Port | Service                                                    |
| ---- | ---------------------------------------------------------- |
| 5432 | Postgres (EHRbase schema)                                  |
| 8080 | EHRbase REST — `http://localhost:8080/ehrbase/rest/openehr/v1` |
| 8000 | MkDocs preview at <http://localhost:8000>                  |

## Running a CI build remotely from macOS

```bash
# Trigger a build
gh workflow run ci.yml

# Watch it
gh run watch
```

The CI workflow spins up EHRbase for the canonical AQL smoke tests and separately builds an unsigned `src/bin/AnyCPU/Debug/OpenEHR.mez`. The release workflow packs and signs that `.mez` into `OpenEHR.pqx`.

Connector-runtime validation (`MakePQX run OpenEHR.query.pq`) still needs a Windows host with Power Query SDK tooling and credentials configured for the local EHRbase source. Track that manually with the [Windows validation checklist](../getting-started/windows-validation.md).

## Publishing installable release assets

The `release.yml` workflow runs on:

- publishing a GitHub Release,
- pushing a `v*` tag,
- manual `workflow_dispatch` with an existing tag.

It runs `MakePQX compile`, packs and signs the resulting `.mez` into `OpenEHR.pqx`, exports `dev-cert.cer`, writes `SHA256SUMS.txt`, attaches those files to the GitHub Release, and also uploads them as a workflow artifact.

Required repository secrets:

| Secret | Purpose |
| ------ | ------- |
| `CODE_SIGN_CERT_PFX_BASE64` | Base64 encoded self-signed code-signing PFX. |
| `CODE_SIGN_CERT_PASSWORD` | Password for that PFX. |

## Windows-only: signing locally

Only needed if you want a personal build to load in Power BI Desktop before CI catches up.

```powershell
# Tooling
.\dev\scripts\install-powerquery-sdktools.ps1

# Build
Set-Location src
MakePQX compile . -t OpenEHR

# Pack and sign with the dev self-signed PFX
MakePQX pack `
  --mez bin\AnyCPU\Debug\OpenEHR.mez `
  --certificate ..\dev-cert.pfx `
  --password $env:CODE_SIGN_CERT_PASSWORD `
  --target bin\AnyCPU\Debug\OpenEHR.pqx
```

## Repo map

```
src/             Power Query connector workspace
tests/           Canonical AQL fixtures + integration runner
dev/             docker-compose, scripts, seed data
docs/            MkDocs Material content
.github/         Workflows, issue templates, CODEOWNERS
```

## Style conventions

- Public functions: `OpenEHR.<Verb>` (`OpenEHR.Aql`, `OpenEHR.StoredQuery`).
- Locals: `camelCase` or `_camelCase` inside `let`.
- Error categories: `OpenEHR.AqlError`, `AuthError`, `TimeoutError`, `ConflictError`, `NotFoundError`, `HttpError`.
- Never accept credentials as function arguments.
- `Web.Contents` base URL is static; variability lives in `RelativePath` / `Query` / `Headers`.
- `ExcludedFromCacheKey = {"Authorization"}` on every `Web.Contents` call.

## Common pitfalls

| Pitfall                                         | Symptom                                    | Fix                                                           |
| ----------------------------------------------- | ------------------------------------------ | ------------------------------------------------------------- |
| Forgot `TestConnection`                         | Silent gateway refresh failure             | Ensure `OpenEHR = [TestConnection = ..., ...]` is exported.   |
| Dynamic base URL to `Web.Contents`              | Dynamic-source error                       | Move variability to `RelativePath` / `Query`.                 |
| Unaliased AQL projection                        | Columns named `#0`, `#1`                   | `SELECT … AS Name`.                                           |
| Missing `_type` on polymorphic RM JSON          | EHRbase 400 with Jackson stack trace       | Add `PARTY_SELF` / `PARTY_REF` / `GENERIC_ID` tags.           |

## Asking for help

- Bug → [bug report](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=bug_report.yml).
- Design question → [GitHub Discussions](https://github.com/rubentalstra/powerbi-openehr-aql/discussions).
- CDR compatibility report → [cdr_compatibility.yml](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=cdr_compatibility.yml).

[← Back to Home](../index.md)
