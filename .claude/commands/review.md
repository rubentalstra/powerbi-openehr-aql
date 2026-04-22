---
description: Review src/ for bugs, logic errors, and deviations from the gotcha list in CLAUDE.md.
---

## Instructions

Delegate to the `feature-dev:code-reviewer` agent.

Scope: everything under `src/`. Focus on:

1. Any `Web.Contents` call whose first arg is not a literal string constant — this is the dynamic-data-source bug.
2. Any `Web.Contents` call missing `ExcludedFromCacheKey = {"Authorization"}`.
3. Any function that accepts credentials or tokens as parameters (should always use `Extension.CurrentCredential()`).
4. Missing `TestConnection` in the `DataSource.Kind` record.
5. AQL bodies that use `query-parameters` (hyphen) instead of `query_parameters` (underscore).
6. Any `Diagnostics.Trace` that logs AQL bodies or response rows.
7. Public API functions whose types aren't documented (no `Value.ReplaceType` wrapper).
8. Paging implementations that don't `Binary.Buffer` the response.
9. `DataSource.Kind` value — must be exactly `"OpenEHR"` and never change.

Report high-confidence issues with file path, line number, and the fix.
