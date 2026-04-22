# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial `src/` connector source: `OpenEHR.pq` (section document with `OpenEHR.Contents`, `OpenEHR.Aql`, `OpenEHR.StoredQuery`, `TestConnection`, Basic auth + Anonymous).
- Library modules: `lib/Aql.pqm` (HTTP transport), `lib/Paging.pqm` (lag-one pagination), `lib/Schema.pqm` (result-set → table + RM-object flattening), `lib/Navigation.pqm` (nav-table helper + builders).
- MSBuild project `src/OpenEHR.proj` and localized strings `src/resources.resx`.
- Connector icons at 16/20/24/32/40/48 px generated from `openehr_logo.png`.
- Dev environment: `dev/docker-compose.yml` (Postgres 16 + EHRbase 2.15 + Keycloak 26 placeholder), seed-data scaffolding, `check-health.{sh,ps1}`, `load-seed.{sh,ps1}`, `new-self-signed-cert.ps1`.
- Documentation site skeleton (MkDocs Material) with full nav and placeholder pages.
- GitHub automation: CODEOWNERS, FUNDING, Dependabot, PR template, bug / feature / CDR-compat issue templates, discussion templates.
- CI workflows: `ci.yml` (build on `windows-latest` + integration tests with EHRbase service container), `release.yml` (tag-driven signed `.pqx` + `.cer` on GitHub Release), `docs.yml` (gh-pages), `codeql.yml`, `spec-link-check.yml`.
- Canonical AQL test suite: `tests/fixtures/canonical-queries.json` + `tests/integration/run-canonical.sh`.
- Claude Code project context: `CLAUDE.md` + `.claude/settings.json` + 5 slash commands (`/build`, `/test-aql`, `/release`, `/spec`, `/review`).

### Known limitations
- Not yet exercised on Power BI Desktop end-to-end — awaiting maintainer Windows access. CI builds, signs, and HTTP-integration-tests the connector, but interactive `.pqx` load + published-report refresh through the on-premises gateway are deferred.
- Sample `.pbix` files are pending (see `dev/sample-pbix/README.md`).
- Releases are signed with a **self-signed** certificate; end users must import `dev-cert.cer` into Windows trust stores. See [install-self-signed.md](docs/getting-started/install-self-signed.md).

[Unreleased]: https://github.com/rubentalstra/powerbi-openehr-aql/compare/HEAD...HEAD
