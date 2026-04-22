---
description: Fetch an openEHR or Power Query spec page into context for discussion.
argument-hint: "<topic: aql | rest-ehr | rest-definition | m-reference | data-connectors | trippin-paging>"
---

## Instructions

Resolve `$ARGUMENTS` to one of these canonical URLs, then `WebFetch` it:

| Topic | URL |
|---|---|
| `aql` | https://specifications.openehr.org/releases/QUERY/latest/AQL.html |
| `rest-ehr` | https://specifications.openehr.org/releases/ITS-REST/latest/ehr.html |
| `rest-definition` | https://specifications.openehr.org/releases/ITS-REST/latest/definition.html |
| `m-reference` | https://learn.microsoft.com/en-us/powerquery-m/power-query-m-function-reference |
| `data-connectors` | https://learn.microsoft.com/en-us/power-query/power-query-what-is-power-query |
| `trippin-paging` | https://learn.microsoft.com/en-us/power-query/samples/trippin/5-paging/readme |

If `$ARGUMENTS` doesn't match, ask the user which topic they meant. After fetching, summarize the headings so future responses can cite specific sections.
