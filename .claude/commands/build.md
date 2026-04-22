---
description: Build the connector. On macOS, triggers the Windows CI workflow; on Windows, runs MakePQX locally.
---

## Context

Power BI connector builds require Windows (`MakePQX` from `Microsoft.PowerQuery.SdkTools`, .NET 10). This project's maintainer develops on macOS, so the canonical build path is CI.

## Instructions

Detect the OS.

### macOS / Linux
Run:

```bash
gh workflow run ci.yml --ref main
gh run watch $(gh run list --workflow=ci.yml --limit=1 --json databaseId --jq '.[0].databaseId')
```

Report the final status and the URL of the `OpenEHR.mez` / `OpenEHR.pqx` artifact.

### Windows
Run:

```powershell
dotnet tool update -g Microsoft.PowerQuery.SdkTools
MakePQX pack src
Write-Host "Built: $(Resolve-Path src\bin\AnyCPU\Debug\OpenEHR.mez)"
```
