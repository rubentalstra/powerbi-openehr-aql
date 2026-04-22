# Options reference

`OpenEHR.Aql` and `OpenEHR.StoredQuery` accept an optional `options` record.

| Option | Type | Default | Meaning |
|---|---|---|---|
| `PageSize` | number | 1000 | Rows per server round-trip when paging. |
| `ExpandRmObjects` | logical | `true` | When true, flatten `DV_QUANTITY`, `DV_CODED_TEXT`, ... into scalar columns. |
| `Timeout` | duration | `#duration(0,0,2,0)` | Per-request timeout. |
| `QueryParameters` | record | `null` | Substituted into `:name` placeholders in the AQL. |

Full behavioral notes coming soon.

[← Back to Home](../index.md)
