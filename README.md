# powerbi-openehr-aql

A native Power BI custom data connector for openEHR Archetype Query Language (AQL).

Run AQL against any openEHR Clinical Data Repository (EHRbase, Better Platform, Code24, DIPS) directly from Power BI Desktop. Pagination, RM-object flattening, and Power BI Service refresh through the on-premises gateway are handled for you.

> Status: pre-release. v0.1.0 is in active development against EHRbase. Phase 1 MVP scope is tracked in [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md). Public release notes will appear in [CHANGELOG.md](CHANGELOG.md).

## Quick install (when v0.1.0 ships)

1. Download the signed `OpenEHR.pqx` from the latest [GitHub Release](https://github.com/rubentalstra/powerbi-openehr-aql/releases).
2. Copy it to `%USERPROFILE%\Documents\Power BI Desktop\Custom Connectors\` (create the folder if missing).
3. In Power BI Desktop: **File → Options → Security → Data Extensions** → choose either:
   - "Allow any extension to load without validation or warning" (evaluation), or
   - The trusted-publisher path documented in [docs/getting-started/install-self-signed.md](https://rubentalstra.github.io/powerbi-openehr-aql/getting-started/install-self-signed/) (recommended).
4. Restart Power BI Desktop. **Get Data → Other → openEHR (Beta)**.

## Documentation

Full docs (deployment, auth, AQL recipes, reference, troubleshooting) live at <https://rubentalstra.github.io/powerbi-openehr-aql>.

## Project resources

| | |
|---|---|
| Source plan | [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) |
| Roadmap | [ROADMAP.md](ROADMAP.md) |
| Contributing | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Security policy | [SECURITY.md](SECURITY.md) |
| Support | [SUPPORT.md](SUPPORT.md) |
| Changelog | [CHANGELOG.md](CHANGELOG.md) |
| Code of Conduct | [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) |
| License | [Apache-2.0](LICENSE) |

## Compatibility

| CDR | Status |
|---|---|
| EHRbase 2.x | Targeted for v0.1.0 (in development) |
| Better Platform | Planned for v1.0.0 |
| Code24 | Planned for v1.0.0 |
| DIPS | Planned for v1.0.0 |

File a [CDR compatibility report](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=cdr_compatibility.yml) if you test against another CDR.

## Acknowledgements

Built on the [openEHR](https://www.openehr.org/) specifications and the Microsoft [Power Query M](https://learn.microsoft.com/en-us/powerquery-m/) extensibility platform. Local development uses [EHRbase](https://github.com/ehrbase/ehrbase).
