<div align="center">

<img src="openehr_logo.png" alt="openEHR" width="160" />

# powerbi-openehr-aql

**A native Power BI custom data connector for openEHR [Archetype Query Language](https://specifications.openehr.org/releases/QUERY/latest/AQL.html).**

Run AQL against your openEHR Clinical Data Repository directly from Power BI Desktop. Pagination, RM-object flattening, and Power BI Service gateway refresh are handled for you. `v0.1.0` targets **EHRbase 2.x**; additional CDRs land in `v1.0.0`.

[![CI](https://github.com/rubentalstra/powerbi-openehr-aql/actions/workflows/ci.yml/badge.svg)](https://github.com/rubentalstra/powerbi-openehr-aql/actions/workflows/ci.yml)
[![Docs](https://github.com/rubentalstra/powerbi-openehr-aql/actions/workflows/docs.yml/badge.svg)](https://github.com/rubentalstra/powerbi-openehr-aql/actions/workflows/docs.yml)
[![CodeQL](https://github.com/rubentalstra/powerbi-openehr-aql/actions/workflows/codeql.yml/badge.svg)](https://github.com/rubentalstra/powerbi-openehr-aql/actions/workflows/codeql.yml)
[![Latest release](https://img.shields.io/github/v/release/rubentalstra/powerbi-openehr-aql?include_prereleases&sort=semver&label=release)](https://github.com/rubentalstra/powerbi-openehr-aql/releases)
[![License: Apache-2.0](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

[![Docs site](https://img.shields.io/badge/docs-rubentalstra.github.io-0969da?logo=materialformkdocs&logoColor=white)](https://rubentalstra.github.io/powerbi-openehr-aql)
[![openEHR AQL](https://img.shields.io/badge/openEHR-AQL%20latest-7B3FE4)](https://specifications.openehr.org/releases/QUERY/latest/AQL.html)
[![Power BI](https://img.shields.io/badge/Power%20BI-custom%20connector-F2C811?logo=powerbi&logoColor=black)](https://learn.microsoft.com/en-us/power-query/install-sdk)
[![Power Query M](https://img.shields.io/badge/built%20with-Power%20Query%20M-773A93)](https://learn.microsoft.com/en-us/powerquery-m/)
[![Keep a Changelog](https://img.shields.io/badge/changelog-Keep%20a%20Changelog%201.1.0-E05735)](CHANGELOG.md)

</div>

---

> **Status — pre-release.** `v0.1.0` is in active development against EHRbase 2.x. The full Phase 1 MVP scope is tracked in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md); shipped behaviour is documented in [CHANGELOG.md](CHANGELOG.md).

## Why this connector

- **Native AQL, not a SQL bridge.** Queries are sent to the CDR's canonical `/query/aql` endpoint — archetype-bound, RM-aware, vendor-portable.
- **Result shapes that feel like Power BI.** `DV_QUANTITY`, `DV_CODED_TEXT`, `DV_DATE_TIME`, `DV_IDENTIFIER` and friends flatten into scalar columns automatically. Unknown record-shaped cells fall back to JSON text so nothing is silently dropped.
- **Lag-one pagination out of the box.** Large result sets stream through the TripPin-style paging pattern; no row-limit surprises.
- **Service-safe.** `TestConnection` is implemented, `Web.Contents` base URLs are static (no dynamic-source error), and `ExcludedFromCacheKey = {"Authorization"}` keeps rotating tokens from poisoning the cache.
- **Zero PHI in logs.** No row-level `Diagnostics.Trace`, no query bodies at `Information` level.

## Quick install (when v0.1.0 ships)

1. Download the signed `OpenEHR.pqx` (and `dev-cert.cer`) from the latest [GitHub Release](https://github.com/rubentalstra/powerbi-openehr-aql/releases).
2. Import `dev-cert.cer` into Windows trust stores once — see [docs/getting-started/install-self-signed.md](https://rubentalstra.github.io/powerbi-openehr-aql/getting-started/install-self-signed/).
3. Copy `OpenEHR.pqx` to `%USERPROFILE%\Documents\Power BI Desktop\Custom Connectors\` (create the folder if missing).
4. Restart Power BI Desktop → **Get Data → Other → openEHR (Beta)**.

## Usage sketch

```m
// Navigation entry point — shows Ad-hoc AQL, Stored Queries, Templates, EHRs.
Source = OpenEHR.Contents("http://localhost:8080/ehrbase/rest/openehr/v1")

// Ad-hoc AQL
Source = OpenEHR.Aql(
    "http://localhost:8080/ehrbase/rest/openehr/v1",
    "SELECT
        e/ehr_id/value   AS EhrId,
        o/data[at0001]/events[at0006]/data[at0003]/items[at0004]/value AS Systolic
     FROM EHR e CONTAINS COMPOSITION c CONTAINS OBSERVATION o
         [openEHR-EHR-OBSERVATION.blood_pressure.v2]",
    [ PageSize = 500, ExpandRmObjects = true ]
)

// Stored query
Source = OpenEHR.StoredQuery(
    "http://localhost:8080/ehrbase/rest/openehr/v1",
    "org.openehr::compositions",
    "1.0.0"
)
```

Full reference: [Functions](https://rubentalstra.github.io/powerbi-openehr-aql/reference/functions/) · [Options](https://rubentalstra.github.io/powerbi-openehr-aql/reference/options/) · [Error codes](https://rubentalstra.github.io/powerbi-openehr-aql/reference/error-codes/).

## Architecture

```mermaid
flowchart LR
    PBI["Power BI Desktop<br/>+ Service"] -->|Get Data<br/>openEHR (Beta)| SEC["src/OpenEHR.pq<br/>(section document)"]
    SEC --> F1["OpenEHR.Contents<br/>nav entry"]
    SEC --> F2["OpenEHR.Aql<br/>ad-hoc"]
    SEC --> F3["OpenEHR.StoredQuery<br/>named"]
    F1 --> LIB
    F2 --> LIB
    F3 --> LIB
    subgraph LIB[library modules]
      AQ[Aql.pqm<br/>HTTP + auth + errors]
      PG[Paging.pqm<br/>lag-one pagination]
      SC[Schema.pqm<br/>RS → table + RM expand]
      NV[Navigation.pqm<br/>nav-table builders]
      AU[Auth.pqm<br/>OAuth2 PKCE]
    end
    LIB -->|POST /query/aql| CDR[("openEHR CDR<br/>EHRbase 2.x")]
```

## Compatibility

| CDR              | Status                                     |
| ---------------- | ------------------------------------------ |
| **EHRbase 2.x**  | **Targeted for v0.1.0 — in active development** |
| Other CDRs       | Post-v0.1.0. File a [CDR compatibility report](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=cdr_compatibility.yml) to vote one up. |

## Project resources

| | |
| --- | --- |
| Documentation site | <https://rubentalstra.github.io/powerbi-openehr-aql> |
| Source plan        | [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) |
| Roadmap            | [ROADMAP.md](ROADMAP.md) |
| Changelog          | [CHANGELOG.md](CHANGELOG.md) |
| Contributing       | [CONTRIBUTING.md](CONTRIBUTING.md) |
| License            | [Apache-2.0](LICENSE) |
| Discussions        | [GitHub Discussions](https://github.com/rubentalstra/powerbi-openehr-aql/discussions) |
| Issues             | [bug](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=bug_report.yml) · [feature](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=feature_request.yml) · [CDR compat](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=cdr_compatibility.yml) |

## Acknowledgements

Built on the [openEHR](https://www.openehr.org/) specifications and Microsoft's [Power Query M](https://learn.microsoft.com/en-us/powerquery-m/) extensibility platform. Local development uses [EHRbase](https://github.com/ehrbase/ehrbase). Paging and navigation patterns are adapted from the canonical [TripPin](https://learn.microsoft.com/en-us/power-query/samples/trippin/readme) samples.
