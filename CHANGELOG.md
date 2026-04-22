# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **OAuth 2.0 + PKCE authentication** (`Auth.pqm`): authorization-code flow with S256 code challenge, `StartLogin` / `FinishLogin` / `Refresh` / `Logout` handlers. Configurable `OAuthConfig` record at the top of `OpenEHR.pq` defaults to Entra ID v2 (`login.microsoftonline.com/common`), easily retargeted at Keycloak / Okta / Auth0 / any OIDC IDP.
- `OpenEHR.pq` exposes three `Authentication` kinds: **OAuth**, **UsernamePassword** (HTTP Basic), **Anonymous**.
- Initial `src/` connector source: `OpenEHR.pq` (section document with `OpenEHR.Contents`, `OpenEHR.Aql`, `OpenEHR.StoredQuery`, `TestConnection`).
- Library modules: `Aql.pqm` (HTTP transport + stored-query fetch + OAuth bearer header), `Auth.pqm` (OAuth2 PKCE factory), `Paging.pqm` (lag-one pagination, factory taking `Aql`), `Schema.pqm` (result-set → table + RM-object flattening, per-column type sampling), `Navigation.pqm` (nav-table helper + builders, factory taking `Aql` / `Paging` / `Schema`, lazy per-row `Data` materialisation for stored queries).
- MSBuild project `src/OpenEHR.proj` and localized strings `src/resources.resx` (adds `OAuthLabel`, `OpenEHR.ConflictError`).
- Connector icons at 16/20/24/32/40/48 px generated from `openehr_logo.png`.
- Dev environment: `dev/docker-compose.yml` (Postgres 16 + EHRbase 2.15 + Keycloak 26 placeholder), seed-data scaffolding with `_type` discriminators for polymorphic RM JSON (`PARTY_SELF`, `PARTY_REF`, `GENERIC_ID`), `check-health.{sh,ps1}`, `load-seed.{sh,ps1}`, `new-self-signed-cert.ps1`.
- MkDocs Material documentation site with Mermaid.js diagram support (`pymdownx.superfences` custom fence). Real content for: home, getting-started (end-user, gateway admin, self-signed, unsigned, future signed-cert), auth (basic, OAuth PKCE, client credentials, Entra ID), cookbook (blood-pressure trend, incremental refresh, EHRbase notes), reference (functions, options, error-codes), compliance (PHI-safe mode), contributing (dev environment), troubleshooting.
- GitHub automation: CODEOWNERS, FUNDING, Dependabot, PR template, bug / feature / CDR-compat issue templates, discussion templates.
- CI workflows pinned to current latest action majors: `ci.yml` (checkout@v6, setup-dotnet@v5, setup-python@v6, upload-artifact@v7 — builds on `windows-latest` + integration tests against an EHRbase service container with Spring Boot 3.x env vars), `release.yml` (action-gh-release@v3 for tag-driven signed `.pqx` + `.cer`), `docs.yml` (GitHub Pages artifact deploy flow: `actions/configure-pages@v6` + `upload-pages-artifact@v5` + `deploy-pages@v5`), `codeql.yml` (codeql-action@v4), `spec-link-check.yml` (lychee-action@v2, create-issue-from-file@v6).
- Canonical AQL test suite: `tests/fixtures/canonical-queries.json` + `tests/integration/run-canonical.sh`.
- Claude Code project context: `CLAUDE.md` + `.claude/settings.json` + 5 slash commands (`/build`, `/test-aql`, `/release`, `/spec`, `/review`).

### Changed
- **Scope narrowed to EHRbase-only for `v0.1.0`.** Better Platform, Code24, and DIPS are deferred to `v1.0.0`. The connector protocol is still vendor-agnostic (standard openEHR REST), so third-party CDRs may work unchanged — file a [CDR compatibility report](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=cdr_compatibility.yml) if you test one.
- **Docs deploy** switched from `gh-deploy` / `gh-pages` branch to the GitHub Pages Actions artifact flow (verified commits only — no deploy-bot commits to `gh-pages`).
- **Repo layout** flattened: `src/*.pqm` instead of `src/lib/*.pqm`. Cross-module `.pqm` loading uses a factory-function pattern so dependencies flow in explicitly rather than via a non-existent shared helper.
- Schema flattening now samples types **per column** (not per row), so sparsely populated RM columns are no longer dropped.
- Stored-query execution uses a single code path: `Aql[ExecuteStored](cdrBaseUrl, qualifiedName, version?)` is called from both `OpenEHR.StoredQuery` and the navigation-table builder.
- EHR_STATUS subject / external_ref seed payloads include the `_type` discriminators EHRbase 2.x's Jackson deserialiser requires.

### Fixed
- MkDocs `--strict` build warning about `docs/getting-started/install-self-signed.md` linking to `../../ROADMAP.md` outside `docs_dir`; the link now points at the absolute GitHub URL.
- EHRbase service container in CI was passing legacy `DB_URL` / `DB_USER` / `DB_PASS` env vars that EHRbase 2.x (Spring Boot 3.x) ignores; now uses `SPRING_DATASOURCE_*` + `SPRING_FLYWAY_*` matching `docker-compose.yml`.

### Known limitations
- Not yet exercised on Power BI Desktop end-to-end — awaiting maintainer Windows access. CI builds, signs, and HTTP-integration-tests the connector, but interactive `.pqx` load + published-report refresh through the on-premises gateway are deferred.
- Native `client_credentials` grant is not supported — `.pqx` cannot hold a client secret safely. Three workaround patterns are documented in [docs/auth/client-credentials.md](docs/auth/client-credentials.md).
- Sample `.pbix` files are pending (see `dev/sample-pbix/README.md`).
- Releases are signed with a **self-signed** certificate; end users must import `dev-cert.cer` into Windows trust stores. See [install-self-signed.md](docs/getting-started/install-self-signed.md). Migration to a commercial OV / EV code-signing cert is tracked in [ROADMAP.md](ROADMAP.md).

[Unreleased]: https://github.com/rubentalstra/powerbi-openehr-aql/compare/HEAD...HEAD
