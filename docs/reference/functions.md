# Function reference

## `OpenEHR.Contents(cdrBaseUrl)`

Navigation entry point. Returns a navigation table with the following children:

- **Ad-hoc AQL** — `OpenEHR.Aql` function leaf.
- **Stored Queries** — folder listing named queries from the CDR's query registry.
- **Templates** — folder listing installed OPTs.
- **EHRs** — table of all EHR IDs.

## `OpenEHR.Aql(cdrBaseUrl, aql, optional options)`

Executes an ad-hoc AQL query against the CDR and returns a Power BI table.

Detailed parameter reference coming soon.

## `OpenEHR.StoredQuery(cdrBaseUrl, qualifiedName, optional version, optional options)`

Executes a stored (named) query from the CDR's registry.

Detailed parameter reference coming soon.

[← Back to Home](../index.md)
