# Troubleshooting

## Top issues

### "The data source cannot be used" / dynamic-source error

The `Web.Contents` base URL is being built dynamically. Re-check any custom query that wraps `OpenEHR.Aql` / `OpenEHR.StoredQuery` — pass the CDR base URL as a parameter, don't concatenate strings that include a protocol.

### Gateway refresh silently fails

Most common cause: `TestConnection` is missing or malformed. The connector ships with it correctly implemented; if you've forked, verify the `OpenEHR = [ TestConnection = ..., ...]` record.

### Column names like `#0`, `#1`

AQL projections without `AS` get positional names. Always alias:

```sql
SELECT c/uid/value AS Uid, c/archetype_details/template_id/value AS Template
FROM EHR e CONTAINS COMPOSITION c
```

### Stale credentials after token rotation

The connector sets `ExcludedFromCacheKey = {"Authorization"}` on every `Web.Contents` call. If you still see cached-auth behavior, confirm you're running the build from the official release.

### "Feature is disabled" when loading `.pqx`

Either:

1. The self-signed cert was not installed (see [install-self-signed.md](getting-started/install-self-signed.md)), OR
2. The "Data Extensions" setting is restrictive. File → Options → Security → Data Extensions.

### Connector does not appear in Get Data

Check these first:

```powershell
$dest = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Microsoft Power BI Desktop\Custom Connectors'
Get-ChildItem $dest
Get-ItemProperty 'HKLM:\Software\Policies\Microsoft\Power BI Desktop' -Name TrustedCertificateThumbprints
```

The folder must be `Microsoft Power BI Desktop\Custom Connectors`. The older-looking `Power BI Desktop\Custom Connectors` path is wrong and the connector will not show up there.

If the file is present but still hidden:

- Right-click `OpenEHR.pqx` → **Properties** → **Unblock** if that checkbox appears.
- Fully close Power BI Desktop from Task Manager, then start it again.
- Temporarily switch **File → Options → Security → Data Extensions** to the not-recommended "allow any extension" option. If it appears in that mode, the connector package is loadable and the problem is trust/thumbprint setup.
- Enable tracing and inspect `%LOCALAPPDATA%\Microsoft\Power BI Desktop\Traces`.

## Reading `mashup-trace.json`

Power BI Desktop writes traces to:

```
%USERPROFILE%\AppData\Local\Microsoft\Power BI Desktop\Traces\
```

Filter by `Source = OpenEHR`. Look for:

- `Web.Request` entries — should show the canonical `/query/aql` endpoint with your base URL's host.
- `OpenEHR.*Error` entries — the `Details` field carries the HTTP status and (truncated) response body.

## Getting help

- Bug or regression → [Bug report](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=bug_report.yml).
- CDR compatibility report → [CDR compatibility](https://github.com/rubentalstra/powerbi-openehr-aql/issues/new?template=cdr_compatibility.yml).
- Question → [GitHub Discussions](https://github.com/rubentalstra/powerbi-openehr-aql/discussions).
- AQL syntax help → [openEHR Discourse](https://discourse.openehr.org/).

[← Back to Home](index.md)
