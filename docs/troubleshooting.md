# Troubleshooting

Top issues and how to read the Power BI mashup trace.

Coming soon.

## Quick tips

- **"Dynamic data source" error** — the base URL passed to `Web.Contents` must be static. See `src/lib/Aql.pqm`.
- **Gateway refresh silently fails** — check that `TestConnection` is implemented and the gateway admin has mapped the data source.
- **Columns named `#0`/`#1`** — add `AS <alias>` to every projection in your AQL.
- **Token rotations poison the cache** — the connector sets `ExcludedFromCacheKey = {"Authorization"}`. If you see stale auth errors, verify your build preserves this.

## Reading `mashup-trace.json`

`%USERPROFILE%\AppData\Local\Microsoft\Power BI Desktop\Traces\` — filter by `Source = OpenEHR`. Full walkthrough coming soon.

[← Back to Home](index.md)
