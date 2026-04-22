# Contributing

Thanks for considering a contribution. This project is in early development; the surface area is small and conventions are still being settled.

## Code of Conduct

Participation is governed by the [Contributor Covenant 2.1](CODE_OF_CONDUCT.md). Report violations per [SECURITY.md](SECURITY.md) (use the security channel for sensitive reports).

## Development environment

Primary development happens on macOS or Linux. Building and signing the `.pqx` artifact happens on a Windows runner in CI; interactive Power BI Desktop testing happens on Windows.

### Tooling

| Tool | macOS install | Why |
|---|---|---|
| Git | bundled / `brew install git` | Source control |
| Docker Desktop | <https://www.docker.com/products/docker-desktop/> | Local EHRbase + Postgres |
| VS Code | <https://code.visualstudio.com/> | M editor |
| [Power Query SDK extension](https://marketplace.visualstudio.com/items?itemName=PowerQuery.vscode-powerquery-sdk) | install in VS Code | Syntax + lint (full build features are Windows-only) |
| .NET 10 SDK | `brew install --cask dotnet-sdk` | Required by `MakePQX` |
| Node.js 24 LTS | `brew install node@24` | Claude Code CLI |
| PowerShell 7.6 | `brew install --cask powershell` | Cross-platform scripts |
| `yamllint` | `brew install yamllint` | Lint issue/discussion templates |
| `jq` | `brew install jq` | Pretty-print AQL responses |

For Windows host setup, see `IMPLEMENTATION_PLAN.md` Task 0.3.

### Local CDR

```bash
cd dev
cp .env.example .env  # edit credentials if needed
docker compose up -d
bash scripts/check-health.sh
bash scripts/load-seed.sh
```

## Branch naming

- `feat/<short-description>` — new feature
- `fix/<short-description>` — bug fix
- `docs/<short-description>` — docs-only change
- `chore/<short-description>` — repo housekeeping, CI, deps
- `refactor/<short-description>` — internal refactor with no behavior change

## Commit messages

We use [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/). Common prefixes: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`. Breaking changes use `feat!:` or include `BREAKING CHANGE:` in the footer.

Example:

```
feat(aql): add ExpandRmObjects option

Allows callers to disable RM-object flattening when the raw shape is needed.
```

## Pull requests

1. Fork or create a branch (per the naming above).
2. Open a PR. The template will prompt for Summary / Type / Testing / Breaking change / Linked issue.
3. Expect CI to run on Windows. All checks must be green.
4. Reviews come from CODEOWNERS.

## After the first release

The repo's GitHub Pages site (configured under repo Settings → Pages → Source = `gh-pages` branch root) is published by the `docs.yml` workflow on every push to `main`. If the site is missing or stale after merging, check the workflow run history.

## Reporting bugs and CDR compatibility

- Bug → [Bug report](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=bug_report.yml). Redact PHI before submitting.
- CDR worked / did not work → [CDR compatibility report](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=cdr_compatibility.yml). Becomes our living matrix.
- Question / show-and-tell → [GitHub Discussions](https://github.com/rubentalstra/powerbi-openehr-aql/discussions).
- AQL syntax help → [openEHR Discourse](https://discourse.openehr.org/).
