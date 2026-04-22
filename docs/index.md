# powerbi-openehr-aql

A native Power BI custom data connector for openEHR Archetype Query Language (AQL).

Run AQL against any openEHR Clinical Data Repository (EHRbase, Better Platform, Code24, DIPS) directly from Power BI Desktop. Pagination, RM-object flattening, and Power BI Service refresh through the on-premises gateway are handled for you.

!!! warning "Pre-release"
    v0.1.0 is in active development. The [source plan](https://github.com/rubentalstra/powerbi-openehr-aql/blob/main/IMPLEMENTATION_PLAN.md) tracks the full roadmap. Expect breaking changes until v1.0.0.

## 60-second install

1. Grab the signed `OpenEHR.pqx` from the latest [GitHub Release](https://github.com/rubentalstra/powerbi-openehr-aql/releases).
2. Drop it into `%USERPROFILE%\Documents\Power BI Desktop\Custom Connectors\`.
3. Follow either [Self-signed cert install](getting-started/install-self-signed.md) (recommended) or [Unsigned / evaluation](getting-started/install-uncertified.md).
4. Restart Power BI Desktop. **Get Data → Other → openEHR (Beta)**.

## Where to go next

- Analyst getting started: [End-user install](getting-started/install-end-user.md)
- Operator / gateway admin: [Gateway admin install](getting-started/install-gateway-admin.md)
- API reference: [Functions](reference/functions.md), [Options](reference/options.md), [Error codes](reference/error-codes.md)
- Recipes: [Cookbook](cookbook/blood-pressure-trend.md)
- Something broken: [Troubleshooting](troubleshooting.md)
