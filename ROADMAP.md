# Roadmap

This roadmap is a public summary of [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md). Dates are intent, not commitments.

## Phase 0 — Foundation (in progress)

Repo scaffolding, GitHub automation, local EHRbase via Docker Compose, MkDocs Material site, Claude Code project context.

## Phase 1 — MVP Connector → v0.1.0

Signed `.pqx` (initially self-signed) that lets anyone with an openEHR CDR run AQL queries from Power BI Desktop and refresh through the on-premises gateway.

- Hello-world connector skeleton
- Basic Auth
- AQL execution via `POST /query/aql`
- Result-set → table conversion
- RM-object flattening (`DV_QUANTITY`, `DV_CODED_TEXT`, …)
- Pagination
- Public function API (`OpenEHR.Aql`, `OpenEHR.StoredQuery`)
- Navigation table
- `TestConnection` for gateway refresh
- CI pipeline (Windows runner builds + integration tests against ephemeral EHRbase)
- Release pipeline (tag → signed `.pqx` on GitHub Release)
- Documentation pages

## Phase 2 — Production-Ready → v1.0.0

OAuth2 (PKCE + Client Credentials), stored query browser, incremental refresh recipes, PHI-safe mode, multi-vendor compatibility tested.

## Phase 3 — Scale & Ecosystem

Entra ID (`Aad`) authentication, template-aware flattening, Fabric / OneLake landing pipeline, optional self-hosted proxy container, Microsoft connector certification submission.

## Phase 4 — Commercial Tier (optional)

Open-source core stays free. Commercial overlay for vendor-certified compatibility, support SLAs, and dashboard packs. Planning deferred until Phase 3 ships and adoption demand is evident.
